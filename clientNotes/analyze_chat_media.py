#!/usr/bin/env python3
"""
IQ Taxi - WhatsApp Chat VIDEO Analyzer
Analyzes videos from WhatsApp chat export using OpenAI GPT-4o Vision
and Whisper for audio transcription to extract client requirements.

Images and chat text are analyzed separately by Copilot.

Usage:
    export OPENAI_API_KEY="sk-..."
    pip install openai opencv-python
    python analyze_chat_media.py

Output: video_analyses.json
"""

import os
import sys
import base64
import glob
import json
import tempfile
import subprocess
from pathlib import Path
from datetime import datetime

try:
    from openai import OpenAI
except ImportError:
    print("❌ openai package not installed. Run: pip install openai")
    sys.exit(1)

# ── Configuration ──────────────────────────────────────────────
CHAT_DIR = Path(__file__).parent / "WhatsApp Chat - New IQ Taxi (1)"
OUTPUT_FILE = Path(__file__).parent / "video_analyses.json"
MODEL = "gpt-4o"
MAX_VIDEO_FRAMES = 15  # more frames = better understanding of video flow

# ── Helpers ────────────────────────────────────────────────────

def encode_image_to_base64(image_path: str) -> str:
    with open(image_path, "rb") as f:
        return base64.b64encode(f.read()).decode("utf-8")


def extract_video_frames(video_path: str, max_frames: int = MAX_VIDEO_FRAMES) -> list[str]:
    """Extract key frames from video using ffmpeg, return list of temp image paths."""
    try:
        # Get video duration using ffprobe
        result = subprocess.run(
            [
                "ffprobe", "-v", "error",
                "-show_entries", "format=duration",
                "-of", "default=noprint_wrappers=1:nokey=1",
                video_path
            ],
            capture_output=True, text=True, timeout=30
        )
        duration = float(result.stdout.strip())
    except (subprocess.TimeoutExpired, ValueError, FileNotFoundError):
        print(f"  ⚠️  Could not get duration for {video_path}, trying opencv...")
        return extract_video_frames_opencv(video_path, max_frames)

    # Calculate intervals
    interval = duration / (max_frames + 1)
    frame_paths = []
    tmp_dir = tempfile.mkdtemp(prefix="iq_taxi_frames_")

    for i in range(max_frames):
        timestamp = interval * (i + 1)
        out_path = os.path.join(tmp_dir, f"frame_{i:03d}.jpg")
        try:
            subprocess.run(
                [
                    "ffmpeg", "-y", "-ss", str(timestamp),
                    "-i", video_path,
                    "-frames:v", "1", "-q:v", "2",
                    out_path
                ],
                capture_output=True, timeout=30
            )
            if os.path.exists(out_path) and os.path.getsize(out_path) > 0:
                frame_paths.append(out_path)
        except (subprocess.TimeoutExpired, FileNotFoundError):
            continue

    if not frame_paths:
        return extract_video_frames_opencv(video_path, max_frames)

    return frame_paths


def extract_video_frames_opencv(video_path: str, max_frames: int) -> list[str]:
    """Fallback: extract frames using OpenCV."""
    try:
        import cv2
    except ImportError:
        print("  ⚠️  opencv-python not installed. Run: pip install opencv-python")
        return []

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"  ⚠️  Could not open video: {video_path}")
        return []

    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    if total_frames <= 0:
        cap.release()
        return []

    interval = total_frames // (max_frames + 1)
    frame_paths = []
    tmp_dir = tempfile.mkdtemp(prefix="iq_taxi_frames_")

    for i in range(max_frames):
        frame_num = interval * (i + 1)
        cap.set(cv2.CAP_PROP_POS_FRAMES, frame_num)
        ret, frame = cap.read()
        if ret:
            out_path = os.path.join(tmp_dir, f"frame_{i:03d}.jpg")
            cv2.imwrite(out_path, frame)
            frame_paths.append(out_path)

    cap.release()
    return frame_paths


def parse_date_from_filename(filename: str) -> str:
    """Extract date from WhatsApp media filename."""
    # Pattern: *-PHOTO-YYYY-MM-DD-HH-MM-SS.jpg or *-VIDEO-...
    parts = filename.split("-")
    for i, part in enumerate(parts):
        if part in ("PHOTO", "VIDEO") and i + 3 < len(parts):
            try:
                year = parts[i + 1]
                month = parts[i + 2]
                day = parts[i + 3]
                return f"{year}-{month}-{day}"
            except (IndexError, ValueError):
                pass
    return "unknown-date"


def transcribe_audio(client: OpenAI, video_path: str) -> str:
    """Extract audio from video and transcribe using Whisper."""
    tmp_dir = tempfile.mkdtemp(prefix="iq_taxi_audio_")
    audio_path = os.path.join(tmp_dir, "audio.mp3")

    try:
        # Extract audio using ffmpeg
        result = subprocess.run(
            [
                "ffmpeg", "-y", "-i", video_path,
                "-vn", "-acodec", "libmp3lame", "-q:a", "4",
                audio_path
            ],
            capture_output=True, timeout=60
        )
        if not os.path.exists(audio_path) or os.path.getsize(audio_path) < 1000:
            return ""

        # Transcribe with Whisper
        with open(audio_path, "rb") as f:
            transcript = client.audio.transcriptions.create(
                model="whisper-1",
                file=f,
                language="ar",
                response_format="text"
            )
        return transcript if isinstance(transcript, str) else transcript.text
    except Exception as e:
        print(f"  ⚠️  Audio transcription failed: {e}")
        return ""
    finally:
        try:
            os.remove(audio_path)
            os.rmdir(tmp_dir)
        except OSError:
            pass


def analyze_video_frames(client: OpenAI, frame_paths: list[str], video_name: str,
                         audio_transcript: str = "") -> dict:
    """
    Two-pass video analysis:
    Pass 1: Describe what's happening in each frame sequentially
    Pass 2: Extract structured requirements from the description
    """

    # ── Pass 1: Detailed frame-by-frame description ──
    content_parts = [
        {
            "type": "text",
            "text": (
                f"هذه {len(frame_paths)} إطار مستخرجة بالترتيب من فيديو '{video_name}' "
                "أرسله العميل في محادثة WhatsApp عن تطبيق IQ Taxi (Flutter).\n\n"
                "المطلوب:\n"
                "1. وصف كل إطار بالتفصيل (ما الشاشة المعروضة، ما العناصر الظاهرة)\n"
                "2. تتبع التسلسل: ما الذي يفعله المستخدم خطوة بخطوة\n"
                "3. تحديد أي أخطاء أو مشاكل UI ظاهرة في أي إطار\n"
                "4. ترجمة أي نص عربي ظاهر\n"
                "5. تحديد هل هذا عرض لباق أم ميزة جديدة أم walkthrough عادي\n\n"
                "أجب بالعربية مع المصطلحات التقنية بالإنجليزية."
            )
        }
    ]

    for idx, fp in enumerate(frame_paths):
        b64 = encode_image_to_base64(fp)
        content_parts.append({
            "type": "text",
            "text": f"--- الإطار {idx + 1}/{len(frame_paths)} ---"
        })
        content_parts.append({
            "type": "image_url",
            "image_url": {
                "url": f"data:image/jpeg;base64,{b64}",
                "detail": "high"
            }
        })

    if audio_transcript:
        content_parts.append({
            "type": "text",
            "text": f"\n--- نص صوتي مستخرج من الفيديو (Whisper) ---\n{audio_transcript}"
        })

    response = client.chat.completions.create(
        model=MODEL,
        messages=[
            {
                "role": "system",
                "content": (
                    "أنت محلل متخصص في تطبيقات الموبايل. تعمل على تحليل فيديوهات "
                    "من محادثة WhatsApp مع عميل لمشروع تطبيق IQ Taxi (Flutter). "
                    "العميل يرسل screen recordings لعرض باقات أو مشاكل أو ميزات مطلوبة. "
                    "حلل كل الإطارات بالتسلسل لفهم ما يحدث في الفيديو. "
                    "أجب بالعربية مع المصطلحات التقنية بالإنجليزية."
                )
            },
            {"role": "user", "content": content_parts}
        ],
        max_tokens=3000
    )
    description = response.choices[0].message.content

    # ── Pass 2: Extract structured requirements ──
    response2 = client.chat.completions.create(
        model=MODEL,
        messages=[
            {
                "role": "system",
                "content": (
                    "أنت مدير مشروع متخصص. بناءً على تحليل فيديو من العميل، "
                    "استخرج قائمة منظمة بالمتطلبات. صنفها إلى:\n"
                    "- bugs: مشاكل وأخطاء يجب إصلاحها\n"
                    "- features: ميزات جديدة مطلوبة\n"
                    "- ui_changes: تعديلات في التصميم وتجربة المستخدم\n"
                    "- technical: مهام تقنية (أداء، توافق، إلخ)\n\n"
                    "أجب بـ JSON فقط بالشكل التالي:\n"
                    '{"bugs": ["..."], "features": ["..."], "ui_changes": ["..."], "technical": ["..."]}\n'
                    "أجب بالعربية مع المصطلحات التقنية بالإنجليزية."
                )
            },
            {
                "role": "user",
                "content": (
                    f"تحليل الفيديو '{video_name}':\n\n{description}\n\n"
                    "استخرج المتطلبات في شكل JSON منظم:"
                )
            }
        ],
        max_tokens=2000
    )

    try:
        raw = response2.choices[0].message.content
        # Strip markdown code fences if present
        raw = raw.strip()
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[1] if "\n" in raw else raw[3:]
        if raw.endswith("```"):
            raw = raw[:-3]
        raw = raw.strip()
        if raw.startswith("json"):
            raw = raw[4:].strip()
        requirements = json.loads(raw)
    except (json.JSONDecodeError, Exception):
        requirements = {"raw": response2.choices[0].message.content}

    return {
        "description": description,
        "audio_transcript": audio_transcript,
        "requirements": requirements
    }


# ── Main ───────────────────────────────────────────────────────

def main():
    api_key = os.environ.get("OPENAI_API_KEY")
    if not api_key:
        print("❌ OPENAI_API_KEY environment variable not set.")
        print("   export OPENAI_API_KEY='sk-...'")
        sys.exit(1)

    client = OpenAI(api_key=api_key)

    if not CHAT_DIR.exists():
        print(f"❌ Chat directory not found: {CHAT_DIR}")
        sys.exit(1)

    # Collect only video files (images analyzed separately by Copilot)
    videos = sorted(glob.glob(str(CHAT_DIR / "*.mp4")))

    print(f"🎥 Found {len(videos)} videos")
    print(f"📋 Starting video analysis...\n")

    all_analyses = []

    # ── Analyze Videos ──
    for i, vid_path in enumerate(videos, 1):
        filename = os.path.basename(vid_path)
        date = parse_date_from_filename(filename)
        print(f"\n[{i}/{len(videos)}] 🎥 Analyzing video: {filename} ({date})...")

        # Step 1: Transcribe audio
        print(f"  🎤 Transcribing audio...")
        transcript = transcribe_audio(client, vid_path)
        if transcript:
            print(f"  ✅ Audio transcribed ({len(transcript)} chars)")
        else:
            print(f"  ⚠️  No audio or transcription failed")

        # Step 2: Extract frames
        print(f"  🖼️  Extracting frames...")
        frames = extract_video_frames(vid_path)

        if not frames:
            print(f"  ⚠️  No frames extracted, skipping")
            all_analyses.append({
                "file": filename,
                "type": "video",
                "date": date,
                "audio_transcript": transcript,
                "description": "[Could not extract video frames for analysis]",
                "requirements": {}
            })
            continue

        print(f"  ✅ Extracted {len(frames)} frames")

        # Step 3: Two-pass analysis (description + structured requirements)
        print(f"  🔎 Running two-pass analysis...")
        try:
            result = analyze_video_frames(client, frames, filename, transcript)
            all_analyses.append({
                "file": filename,
                "type": "video",
                "date": date,
                "audio_transcript": result["audio_transcript"],
                "description": result["description"],
                "requirements": result["requirements"]
            })
            print(f"  ✅ Analysis complete")
        except Exception as e:
            print(f"  ❌ Error: {e}")
            all_analyses.append({
                "file": filename,
                "type": "video",
                "date": date,
                "audio_transcript": transcript,
                "description": f"[Error analyzing video: {e}]",
                "requirements": {}
            })

        # Cleanup temp frames
        for fp in frames:
            try:
                os.remove(fp)
            except OSError:
                pass

    # ── Save Results ──
    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        json.dump(all_analyses, f, ensure_ascii=False, indent=2)

    print(f"\n{'='*60}")
    print(f"✅ Video analyses saved to: {OUTPUT_FILE}")
    print(f"📊 Analyzed {len(all_analyses)} videos")
    print(f"{'='*60}")


if __name__ == "__main__":
    main()

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/iq_image.dart';
import 'bloc/splash_bloc.dart';
import 'bloc/splash_event.dart';
import 'bloc/splash_state.dart';

/// Shared Splash Screen — used by both Passenger & Driver apps.
///
/// **100% StatelessWidget** — the fade-in uses [AnimatedOpacity]
/// (an implicit animation) instead of [AnimationController].
/// Timer logic lives in [SplashBloc].
class SplashPage extends StatelessWidget {
  /// Callback fired after [splashDuration] elapses.
  final void Function(BuildContext context) onSplashComplete;

  /// How long the splash stays visible before [onSplashComplete] fires.
  final Duration splashDuration;

  const SplashPage({
    super.key,
    required this.onSplashComplete,
    this.splashDuration = const Duration(seconds: 3),
  });

  @override
  Widget build(BuildContext context) {
    // Precache the wave pattern
    precacheImage(const AssetImage(AppAssets.splashWavePattern), context);

    return BlocProvider(
      create: (_) => SplashBloc(splashDuration: splashDuration)
        ..add(const SplashStarted()),
      child: _SplashBody(onSplashComplete: onSplashComplete),
    );
  }
}

class _SplashBody extends StatelessWidget {
  final void Function(BuildContext context) onSplashComplete;

  const _SplashBody({required this.onSplashComplete});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listenWhen: (prev, curr) => !prev.completed && curr.completed,
      listener: (context, state) {
        if (state.completed) {
          onSplashComplete(context);
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background: radial gradient (cream)
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.65),
                  radius: 1.8,
                  colors: [
                    AppColors.splashGradientLight,
                    AppColors.splashBackground,
                  ],
                ),
              ),
            ),

            // 2. Wave pattern overlay (22% opacity)
            Positioned.fill(
              child: IqImage(
                AppAssets.splashWavePattern,
                fit: BoxFit.cover,
                color: AppColors.white.withValues(alpha: 0.78),
                colorBlendMode: BlendMode.srcATop,
                filterQuality: FilterQuality.low,
              ),
            ),

            // 3. Centred logo with fade-in
            Center(
              child: BlocBuilder<SplashBloc, SplashState>(
                buildWhen: (prev, curr) =>
                    prev.logoVisible != curr.logoVisible,
                builder: (context, state) {
                  return AnimatedOpacity(
                    opacity: state.logoVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeIn,
                    child: IqImage(
                      AppAssets.iqTaxiLogo,
                      width: 217.w,
                      height: 251.w,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

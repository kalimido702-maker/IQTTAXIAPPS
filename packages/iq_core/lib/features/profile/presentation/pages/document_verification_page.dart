import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/iq_text.dart';
import '../../data/models/needed_document_model.dart';
import '../bloc/driver_documents_bloc.dart';

/// Page that shows the list of driver verification documents
/// with their upload / verification status.
/// Supports dark & light themes and tappable document cards.
class DocumentVerificationPage extends StatelessWidget {
  const DocumentVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.white,
        appBar: AppBar(
          title: IqText(
            AppStrings.documentVerification,
            style: AppTypography.heading3.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: isDark ? AppColors.white : AppColors.textDark,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(
            color: isDark ? AppColors.white : AppColors.textDark,
          ),
        ),
        body: BlocConsumer<DriverDocumentsBloc, DriverDocumentsState>(
          listener: (context, state) {
            if (state.status == DriverDocumentsStatus.uploaded) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(AppStrings.documentUploadedSuccess),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              );
            }
            if (state.status == DriverDocumentsStatus.error &&
                state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.status == DriverDocumentsStatus.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (state.status == DriverDocumentsStatus.error &&
                state.documents.isEmpty) {
              return _buildError(context, state, isDark);
            }
            if (state.documents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      size: 60.sp,
                      color: isDark ? AppColors.darkGray : AppColors.grayLight,
                    ),
                    SizedBox(height: 12.h),
                    IqText(
                      AppStrings.noDataToDisplay,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        color:
                            isDark ? AppColors.darkGray : AppColors.textSubtitle,
                      ),
                    ),
                  ],
                ),
              );
            }

            final isUploading =
                state.status == DriverDocumentsStatus.uploading;

            return Stack(
              children: [
                ListView.separated(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  itemCount: state.documents.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (_, index) {
                    return _DocumentCard(
                      document: state.documents[index],
                      isDark: isDark,
                    );
                  },
                ),
                if (isUploading)
                  Container(
                    color: AppColors.black.withValues(alpha: 0.26),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(24.w),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                            SizedBox(height: 16.h),
                            IqText(
                              AppStrings.documentUploading,
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.white
                                    : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildError(
      BuildContext context, DriverDocumentsState state, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60.sp,
              color: AppColors.error,
            ),
            SizedBox(height: 12.h),
            IqText(
              state.errorMessage ?? AppStrings.serverError,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14.sp,
                color: isDark ? AppColors.darkGray : AppColors.textSubtitle,
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              height: 44.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  context
                      .read<DriverDocumentsBloc>()
                      .add(const DriverDocumentsLoadRequested());
                },
                icon: const Icon(Icons.refresh, color: AppColors.white),
                label: IqText(
                  AppStrings.retry,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DocumentCard — tappable card with proper theme support
// ─────────────────────────────────────────────────────────────────────────────
class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.document, required this.isDark});
  final NeededDocumentModel document;
  final bool isDark;

  /// Determine the visual status of the document.
  _DocStatus get _status {
    if (document.isUploaded) {
      // document_status: 1 = verified/approved, 0 = pending, 2 = declined
      if (document.documentStatus == '1') return _DocStatus.verified;
      if (document.documentStatus == '2') return _DocStatus.declined;
      // Treat '0' or null (just-uploaded) as pending
      return _DocStatus.pending;
    }
    return _DocStatus.needsUpload;
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final statusColor = _colorFor(status);
    final statusBg = statusColor.withAlpha(25);

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.grayLightBg,
      borderRadius: BorderRadius.circular(14.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => _handleTap(context, status),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.grayBorder,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // ── Document icon ──
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _iconFor(status),
                  color: statusColor,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 12.w),
              // ── Name + subtitle ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IqText(
                      document.name,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.white : AppColors.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    IqText(
                      _subtitleFor(status),
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11.sp,
                        color: isDark
                            ? AppColors.darkGray
                            : AppColors.textSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              // ── Status badge ──
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _badgeIconFor(status),
                      color: statusColor,
                      size: 14.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      _labelFor(status),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              // ── Chevron ──
              SizedBox(width: 6.w),
              Icon(
                Icons.chevron_left,
                size: 20.sp,
                color: isDark ? AppColors.darkGray : AppColors.grayLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Status → visual mapping ──

  Color _colorFor(_DocStatus s) {
    switch (s) {
      case _DocStatus.verified:
        return AppColors.success;
      case _DocStatus.pending:
        return AppColors.info;
      case _DocStatus.declined:
        return AppColors.error;
      case _DocStatus.needsUpload:
        return AppColors.warning;
    }
  }

  IconData _iconFor(_DocStatus s) {
    switch (s) {
      case _DocStatus.verified:
        return Icons.verified_user_rounded;
      case _DocStatus.pending:
        return Icons.hourglass_top_rounded;
      case _DocStatus.declined:
        return Icons.cancel_rounded;
      case _DocStatus.needsUpload:
        return Icons.description_outlined;
    }
  }

  IconData _badgeIconFor(_DocStatus s) {
    switch (s) {
      case _DocStatus.verified:
        return Icons.check_circle;
      case _DocStatus.pending:
        return Icons.schedule;
      case _DocStatus.declined:
        return Icons.error_outline;
      case _DocStatus.needsUpload:
        return Icons.cloud_upload_outlined;
    }
  }

  String _labelFor(_DocStatus s) {
    switch (s) {
      case _DocStatus.verified:
        return AppStrings.verified;
      case _DocStatus.pending:
        return AppStrings.pending;
      case _DocStatus.declined:
        return AppStrings.declined;
      case _DocStatus.needsUpload:
        return AppStrings.uploadRequired;
    }
  }

  String _subtitleFor(_DocStatus s) {
    switch (s) {
      case _DocStatus.verified:
        return AppStrings.tapToView;
      case _DocStatus.pending:
        return AppStrings.tapToView;
      case _DocStatus.declined:
        return AppStrings.tapToUpload;
      case _DocStatus.needsUpload:
        return AppStrings.tapToUpload;
    }
  }

  // ── Tap handling ──

  void _handleTap(BuildContext context, _DocStatus status) {
    switch (status) {
      case _DocStatus.verified:
      case _DocStatus.pending:
        // Show uploaded image(s) in a dialog
        _showDocumentPreview(context);
        break;
      case _DocStatus.declined:
      case _DocStatus.needsUpload:
        // Open upload flow
        _showUploadSheet(context);
        break;
    }
  }

  /// Show uploaded document image(s) in a full-screen dialog.
  void _showDocumentPreview(BuildContext context) {
    final images = <String>[];
    if (document.documentImageUrl != null &&
        document.documentImageUrl!.isNotEmpty) {
      images.add(document.documentImageUrl!);
    }
    if (document.backDocumentImageUrl != null &&
        document.backDocumentImageUrl!.isNotEmpty) {
      images.add(document.backDocumentImageUrl!);
    }

    // If no images available → show a "pending review" info dialog
    // instead of opening upload sheet (doc IS uploaded, just no url yet).
    if (images.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r)),
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 48.sp,
                  color: AppColors.info,
                ),
                SizedBox(height: 16.h),
                IqText(
                  document.name,
                  style: AppTypography.heading3.copyWith(
                    color: isDark ? AppColors.white : AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12.h),
                IqText(
                  AppStrings.documentUnderReview,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color:
                        isDark ? AppColors.darkGray : AppColors.textSubtitle,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22.r),
                      ),
                    ),
                    child: IqText(
                      AppStrings.ok,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: isDark ? AppColors.darkCard : AppColors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IqText(
                  document.name,
                  style: AppTypography.heading3.copyWith(
                    color: isDark ? AppColors.white : AppColors.textDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 16.h),
                for (final url in images) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: Image.network(
                      url,
                      height: 200.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkInputBg
                                : AppColors.grayLightBg,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => Container(
                        height: 200.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkInputBg
                              : AppColors.grayLightBg,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.error.withAlpha(80),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.broken_image_rounded,
                                color: AppColors.error, size: 36.sp),
                            SizedBox(height: 8.h),
                            Text(
                              AppStrings.failedToLoadImage,
                              style: TextStyle(
                                color: AppColors.error,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
                // If editable & already uploaded → allow re-upload
                if (document.isEditable) ...[
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    height: 44.h,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showUploadSheet(context);
                      },
                      icon: const Icon(Icons.edit, color: AppColors.white,
                          size: 18),
                      label: IqText(
                        AppStrings.edit,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show the upload bottom sheet — pick camera / gallery, then dispatch.
  void _showUploadSheet(BuildContext context) {
    final isDarkSheet = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkSheet ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetCtx) {
        return _UploadSheetContent(
          document: document,
          parentContext: context,
          isDark: isDarkSheet,
        );
      },
    );
  }
}

enum _DocStatus { verified, pending, declined, needsUpload }

// ─────────────────────────────────────────────────────────────────────────────
// _UploadSheetContent — image picker + optional fields
// ─────────────────────────────────────────────────────────────────────────────
class _UploadSheetContent extends StatefulWidget {
  const _UploadSheetContent({
    required this.document,
    required this.parentContext,
    required this.isDark,
  });

  final NeededDocumentModel document;
  final BuildContext parentContext;
  final bool isDark;

  @override
  State<_UploadSheetContent> createState() => _UploadSheetContentState();
}

class _UploadSheetContentState extends State<_UploadSheetContent> {
  String? _frontPath;
  String? _backPath;
  final _idNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    _expiryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isFront}) async {
    final source = await _chooseSource();
    if (source == null) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    setState(() {
      if (isFront) {
        _frontPath = picked.path;
      } else {
        _backPath = picked.path;
      }
    });
  }

  Future<ImageSource?> _chooseSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: widget.isDark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),
      builder: (_) => Directionality(
        textDirection: TextDirection.rtl,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.camera_alt,
                      color: widget.isDark
                          ? AppColors.white
                          : AppColors.textDark),
                  title: IqText(
                    AppStrings.camera,
                    style: TextStyle(
                      color: widget.isDark
                          ? AppColors.white
                          : AppColors.textDark,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library,
                      color: widget.isDark
                          ? AppColors.white
                          : AppColors.textDark),
                  title: IqText(
                    AppStrings.gallery,
                    style: TextStyle(
                      color: widget.isDark
                          ? AppColors.white
                          : AppColors.textDark,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_frontPath == null) return;

    widget.parentContext.read<DriverDocumentsBloc>().add(
          DriverDocumentUploadRequested(
            documentId: widget.document.id,
            filePath: _frontPath!,
            backFilePath: _backPath,
            identifyNumber: _idNumberCtrl.text.isNotEmpty
                ? _idNumberCtrl.text.trim()
                : null,
            expiryDate:
                _expiryCtrl.text.isNotEmpty ? _expiryCtrl.text.trim() : null,
          ),
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final doc = widget.document;
    final dark = widget.isDark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.grayBorder,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              IqText(
                doc.name,
                style: AppTypography.heading3.copyWith(
                  color: dark ? AppColors.white : AppColors.textDark,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),

              // ── Front image picker ──
              _imagePickerTile(
                label: doc.isFrontAndBack
                    ? AppStrings.frontImage
                    : AppStrings.chooseImage,
                picked: _frontPath != null,
                onTap: () => _pickImage(isFront: true),
                dark: dark,
              ),

              // ── Back image picker (if front-and-back required) ──
              if (doc.isFrontAndBack) ...[
                SizedBox(height: 12.h),
                _imagePickerTile(
                  label: AppStrings.backImage,
                  picked: _backPath != null,
                  onTap: () => _pickImage(isFront: false),
                  dark: dark,
                ),
              ],

              // ── ID number field ──
              if (doc.hasIdNumber) ...[
                SizedBox(height: 14.h),
                _buildInput(
                  label: AppStrings.idNumber,
                  controller: _idNumberCtrl,
                  dark: dark,
                ),
              ],

              // ── Expiry date field ──
              if (doc.hasExpiryDate) ...[
                SizedBox(height: 14.h),
                _buildInput(
                  label: AppStrings.expiryDate,
                  controller: _expiryCtrl,
                  dark: dark,
                  hint: 'YYYY-MM-DD',
                ),
              ],

              SizedBox(height: 24.h),
              SizedBox(
                height: 52.h,
                child: ElevatedButton(
                  onPressed: _frontPath != null ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28.r),
                    ),
                  ),
                  child: IqText(
                    AppStrings.save,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePickerTile({
    required String label,
    required bool picked,
    required VoidCallback onTap,
    required bool dark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkInputBg : AppColors.grayLightBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: picked ? AppColors.success : AppColors.grayBorder,
            width: picked ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              picked
                  ? Icons.check_circle_rounded
                  : Icons.cloud_upload_outlined,
              color: picked ? AppColors.success : AppColors.warning,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: IqText(
                label,
                style: AppTypography.bodyMedium.copyWith(
                  color: dark ? AppColors.white : AppColors.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14.sp,
              color: dark ? AppColors.darkGray : AppColors.grayLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required bool dark,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IqText(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: dark ? AppColors.darkGray : AppColors.textSubtitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 6.h),
        TextField(
          controller: controller,
          style: TextStyle(
            color: dark ? AppColors.white : AppColors.textDark,
            fontSize: 14.sp,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: dark ? AppColors.darkGray : AppColors.grayPlaceholder,
              fontSize: 13.sp,
            ),
            filled: true,
            fillColor: dark ? AppColors.darkInputBg : AppColors.grayLightBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  BorderSide(color: AppColors.grayBorder, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/iq_image.dart';
import '../../../core/widgets/iq_primary_button.dart';
import '../../../core/widgets/iq_text.dart';
import 'bloc/onboarding_bloc.dart';
import 'bloc/onboarding_event.dart';
import 'bloc/onboarding_state.dart';

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String illustrationAsset;

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.illustrationAsset,
  });
}

/// Onboarding page — **100% StatelessWidget**.
///
/// Page index + completion live in [OnboardingBloc].
/// The [PageController] is the only imperative piece; it is
/// kept in a private [_OnboardingBody] that uses a single
/// [StatelessWidget] + manual controller sync via [BlocListener].
class OnboardingPage extends StatelessWidget {
  final void Function(BuildContext context) onComplete;
  final List<OnboardingPageData>? customPages;

  const OnboardingPage({
    super.key,
    required this.onComplete,
    this.customPages,
  });

  static const _defaultPages = [
    OnboardingPageData(
      title: AppStrings.onboardingTitle1,
      subtitle: AppStrings.onboardingSubtitle1,
      illustrationAsset: AppAssets.onboardingEasyPayment,
    ),
    OnboardingPageData(
      title: AppStrings.onboardingTitle2,
      subtitle: AppStrings.onboardingSubtitle2,
      illustrationAsset: AppAssets.onboardingTrackDriver,
    ),
    OnboardingPageData(
      title: AppStrings.onboardingTitle3,
      subtitle: AppStrings.onboardingSubtitle3,
      illustrationAsset: AppAssets.onboardingRideRequest,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = customPages ?? _defaultPages;
    // Precache assets on first build
    _precacheAssets(context, pages);

    return BlocProvider(
      create: (_) => OnboardingBloc(totalPages: pages.length),
      child: _OnboardingBody(pages: pages, onComplete: onComplete),
    );
  }

  void _precacheAssets(BuildContext context, List<OnboardingPageData> pages) {
    const svgAssets = [
      AppAssets.iqTaxiLogo,
      AppAssets.icArrowLeft,
    ];
    const rasterAssets = [
      AppAssets.onboardingRideRequest,
      AppAssets.onboardingEasyPayment,
      AppAssets.onboardingTrackDriver,
    ];

    for (final asset in svgAssets) {
      final loader = SvgAssetLoader(asset);
      svg.cache.putIfAbsent(
        loader.cacheKey(null),
        () => loader.loadBytes(null),
      );
    }
    for (final asset in rasterAssets) {
      precacheImage(AssetImage(asset), context);
    }
    for (final page in pages) {
      precacheImage(AssetImage(page.illustrationAsset), context);
    }
  }
}

/// Inner body that owns the [PageController].
class _OnboardingBody extends StatefulWidget {
  final List<OnboardingPageData> pages;
  final void Function(BuildContext context) onComplete;

  const _OnboardingBody({
    required this.pages,
    required this.onComplete,
  });

  @override
  State<_OnboardingBody> createState() => _OnboardingBodyState();
}

class _OnboardingBodyState extends State<_OnboardingBody> {
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listenWhen: (prev, curr) =>
          prev.currentPage != curr.currentPage || curr.completed,
      listener: (context, state) {
        if (state.completed) {
          widget.onComplete(context);
          return;
        }
        // Animate PageView to match BLoC state
        if (_pageController.hasClients &&
            _pageController.page?.round() != state.currentPage) {
          _pageController.animateToPage(
            state.currentPage,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.6, -0.65),
                radius: 1.8,
                colors: [AppColors.splashGradientLight, AppColors.white],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(context, state),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: widget.pages.length,
                      onPageChanged: (index) => context
                          .read<OnboardingBloc>()
                          .add(OnboardingPageChanged(index)),
                      itemBuilder: (_, index) =>
                          _buildPageContent(widget.pages[index], state),
                    ),
                  ),
                  _buildBottomButton(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, OnboardingState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context
                .read<OnboardingBloc>()
                .add(const OnboardingSkipped()),
            child: IqText(
              AppStrings.skip,
              style: AppTypography.labelLarge.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          IqImage(AppAssets.iqTaxiLogo, width: 74.w, height: 85.w),
          state.currentPage > 0
              ? GestureDetector(
                  onTap: () => context
                      .read<OnboardingBloc>()
                      .add(const OnboardingBackPressed()),
                  child: SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: IqImage(
                      AppAssets.icArrowLeft,
                      width: 24.w,
                      height: 24.w,
                      color: AppColors.black,
                    ),
                  ),
                )
              : SizedBox(width: 24.w),
        ],
      ),
    );
  }

  Widget _buildPageContent(
      OnboardingPageData page, OnboardingState state) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        children: [
          const Spacer(flex: 1),
          SizedBox(
            width: 278.w,
            height: 278.w,
            child: IqImage(page.illustrationAsset,
                width: 278.w, height: 278.w),
          ),
          const Spacer(flex: 1),
          IqText(
            page.title,
            style: AppTypography.heading1,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15.h),
          IqText(
            page.subtitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textHint,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 30.h),
          _buildDotsIndicator(state.currentPage),
          const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildDotsIndicator(int currentPage) {
    final int dotCount = widget.pages.length;
    final int activeDot = currentPage >= dotCount ? 0 : currentPage;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(dotCount, (index) {
        final bool isActive = index == activeDot;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: isActive ? 28.w : 10.w,
          height: 10.w,
          decoration: BoxDecoration(
            color:
                isActive ? AppColors.buttonYellow : AppColors.grayInactive,
            borderRadius: BorderRadius.circular(5.r),
          ),
        );
      }),
    );
  }

  Widget _buildBottomButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(40.w, 0, 40.w, 24.h),
      child: IqPrimaryButton(
        text: AppStrings.getStarted,
        onPressed: () => context
            .read<OnboardingBloc>()
            .add(const OnboardingNextPressed()),
        width: 360.w,
      ),
    );
  }
}

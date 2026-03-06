import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iq_core/iq_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Root widget for the Driver App
class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  /// Global key so [BlocListener] can navigate without a page [BuildContext].
  static final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<AuthBloc>()),
            BlocProvider.value(value: sl<ThemeCubit>()),
            BlocProvider.value(value: sl<LocaleCubit>()),
          ],
          child: BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, themeState) {
              return BlocBuilder<LocaleCubit, LocaleState>(
                builder: (context, localeState) {
                  return MaterialApp(
                    navigatorKey: DriverApp.navigatorKey,
                    title: AppStrings.appNameDriver,
                    debugShowCheckedModeBanner: false,
                    theme: AppTheme.lightTheme,
                    darkTheme: AppTheme.darkTheme,
                    themeMode: themeState.themeMode,
                    locale: localeState.locale,
                    supportedLocales: const [
                      Locale('ar'),
                      Locale('en'),
                    ],
                    localizationsDelegates: const [
                      GlobalMaterialLocalizations.delegate,
                      GlobalWidgetsLocalizations.delegate,
                      GlobalCupertinoLocalizations.delegate,
                    ],
                    builder: (context, child) {
                      return Directionality(
                        textDirection: localeState.isArabic
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: BlocListener<AuthBloc, AuthState>(
                          listenWhen: (prev, curr) =>
                              prev is! AuthUnauthenticated &&
                              curr is AuthUnauthenticated,
                          listener: (context, state) {
                            // 401 received → clear nav stack, restart from splash
                            DriverApp.navigatorKey.currentState
                                ?.pushAndRemoveUntil(
                              MaterialPageRoute<void>(
                                builder: (_) => const _AppHome(),
                              ),
                              (route) => false,
                            );
                          },
                          child: child ?? const SizedBox.shrink(),
                        ),
                      );
                    },
                    home: const _AppHome(),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

/// Manages the Splash -> Onboarding -> Auth transition.
/// **100% StatelessWidget**.
///
/// Routing logic after splash:
/// 1. If auth token exists → Home (login persisted).
/// 2. If onboarding was seen → Login.
/// 3. First launch → Onboarding (marked seen on complete).
class _AppHome extends StatelessWidget {
  const _AppHome();

  /// External link for driver registration / joining.
  static const _driverJoinUrl = 'https://iqtaxi.com/driver/join';

  @override
  Widget build(BuildContext context) {
    return SplashPage(
      onSplashComplete: (splashCtx) {
        final destination = AppStartup.getDestination();

        switch (destination) {
          case AppStartupDestination.home:
            _navigateToHome(splashCtx);
          case AppStartupDestination.login:
            _navigateToLogin(splashCtx);
          case AppStartupDestination.onboarding:
            Navigator.of(splashCtx).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => OnboardingPage(
                  customPages: const [
                    OnboardingPageData(
                      title: AppStrings.driverOnboardingTitle1,
                      subtitle: AppStrings.driverOnboardingSubtitle1,
                      illustrationAsset: AppAssets.onboardingEasyPayment,
                    ),
                    OnboardingPageData(
                      title: AppStrings.driverOnboardingTitle2,
                      subtitle: AppStrings.driverOnboardingSubtitle2,
                      illustrationAsset: AppAssets.onboardingTrackDriver,
                    ),
                    OnboardingPageData(
                      title: AppStrings.driverOnboardingTitle3,
                      subtitle: AppStrings.driverOnboardingSubtitle3,
                      illustrationAsset: AppAssets.onboardingRideRequest,
                    ),
                  ],
                  onComplete: (onboardingCtx) {
                    AppStartup.markOnboardingSeen();
                    _navigateToLogin(onboardingCtx);
                  },
                ),
              ),
            );
        }
      },
    );
  }

  void _navigateToLogin(BuildContext ctx) {
    Navigator.of(ctx).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: LoginPage(
            title: AppStrings.login,
            isDriver: true,
            headerBuilder: (_) => const DriverLoginHeader(),
            footerLinkLabel: AppStrings.joinUs,
            onFooterLinkTap: (_) => _openJoinLink(),
            onOtpSent: (pageCtx, phone) => _navigateToOtp(pageCtx, phone),
            role: 'driver',
          ),
        ),
      ),
    );
  }

  void _navigateToOtp(BuildContext ctx, String phone) {
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: OtpPage(
            phone: phone,
            role: 'driver',
            onVerified: (pageCtx) {
              _navigateToHome(pageCtx);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openJoinLink() async {
    final uri = Uri.parse(_driverJoinUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _navigateToHome(BuildContext ctx) {
    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => DriverHomePage(
          sidebarItems: _buildSidebarItems(),
          onProfileTap: (profileCtx) => Navigator.of(profileCtx).push(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider(
                create: (_) => sl<ProfileBloc>()
                  ..add(const ProfileLoadRequested()),
                child: const ProfilePage(),
              ),
            ),
          ),
        ),
      ),
      (route) => false,
    );
  }

  static List<IqSidebarItem> _buildSidebarItems() {
    return [
      IqSidebarItem(
        icon: Icons.notifications_outlined,
        label: AppStrings.notifications,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => sl<NotificationBloc>()
                ..add(const NotificationLoadRequested()),
              child: const NotificationsPage(),
            ),
          ),
        ),
      ),
      IqSidebarItem(
        icon: Icons.description_outlined,
        label: AppStrings.tripHistory,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => sl<TripHistoryBloc>()
                ..add(const TripHistoryLoadRequested()),
              child: const TripHistoryPage(),
            ),
          ),
        ),
      ),
      IqSidebarItem(
        icon: Icons.monetization_on_outlined,
        label: AppStrings.earnings,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => EarningsBloc(
                repository: sl<EarningsRepository>(),
              )..add(const EarningsLoadRequested()),
              child: const EarningsPage(),
            ),
          ),
        ),
      ),
      IqSidebarItem(
        icon: Icons.emoji_events_outlined,
        label: AppStrings.incentives,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => sl<IncentiveBloc>()
                ..add(const IncentiveLoadRequested(type: 0)),
              child: const IncentivePage(),
            ),
          ),
        ),
      ),
      IqSidebarItem(
        icon: Icons.account_balance_wallet_outlined,
        label: AppStrings.wallet,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => sl<WalletBloc>()
                ..add(const WalletLoadRequested()),
              child: const DriverWalletPage(),
            ),
          ),
        ),
      ),
      IqSidebarItem(
        icon: Icons.card_membership_rounded,
        label: AppStrings.subscription,
        onTap: (ctx) {
          final homeData = ctx.read<DriverHomeBloc>().state.homeData;
          final activeSub = homeData?.subscriptionData != null
              ? ActiveSubscription.fromJson(homeData!.subscriptionData!)
              : null;
          Navigator.of(ctx).push(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider(
                create: (_) => sl<SubscriptionBloc>()
                  ..add(SubscriptionLoadPlans(
                    activeSubscription: activeSub,
                    hasSubscription: homeData?.hasSubscription ?? false,
                    isExpired: homeData?.isSubscriptionExpired ?? false,
                    walletBalance:
                        homeData?.wallet.balance ?? 0,
                    currencySymbol:
                        homeData?.currencySymbol ?? 'IQD',
                  )),
                child: const SubscriptionPage(),
              ),
            ),
          );
        },
      ),
      IqSidebarItem(
        icon: Icons.card_giftcard_rounded,
        label: AppStrings.solveAndWin,
        onTap: (ctx) {
          final code =
              ctx.read<DriverHomeBloc>().state.homeData?.refferalCode ?? '';
          Navigator.of(ctx).push(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider(
                create: (_) => ReferralCubit(referralCode: code),
                child: const ReferralPage(),
              ),
            ),
          );
        },
      ),
      IqSidebarItem(
        icon: Icons.language,
        label: AppStrings.changeLanguage,
        onTap: (ctx) => LanguageBottomSheet.show(ctx),
      ),
      IqSidebarItem(
        icon: Icons.phone_outlined,
        label: AppStrings.technicalSupport,
        onTap: (ctx) {
          final homeData =
              ctx.read<DriverHomeBloc>().state.homeData;
          final cachedConvId =
              sl<SupportChatDataSource>().getSavedConversationId();
          Navigator.of(ctx).push(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider(
                create: (_) => SupportChatBloc(
                  repository: sl<SupportChatRepository>(),
                  currentUserId: homeData?.id ?? '',
                  initialConversationId:
                      homeData?.conversationId ?? cachedConvId,
                )..add(const SupportChatLoadRequested()),
                child: const SupportChatPage(),
              ),
            ),
          );
        },
      ),
      IqSidebarItem(
        icon: Icons.bar_chart_outlined,
        label: AppStrings.reports,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => sl<ReportsBloc>(),
              child: const ReportsPage(),
            ),
          ),
        ),
      ),
      IqSidebarItem(
        icon: Icons.tune,
        label: AppStrings.settings,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: sl<ThemeCubit>(),
              child: SettingsPage(
                onLogout: () {
                  ctx.read<AuthBloc>().add(const AuthLogoutEvent());
                },
              ),
            ),
          ),
        ),
      ),
      IqSidebarItem(
        icon: Icons.logout,
        label: AppStrings.logout,
        onTap: (ctx) {
          ctx.read<AuthBloc>().add(const AuthLogoutEvent());
        },
      ),
    ];
  }
}

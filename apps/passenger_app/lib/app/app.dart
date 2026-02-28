import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iq_core/iq_core.dart';
import 'package:url_launcher/url_launcher.dart';

/// Root widget for the Passenger App
class PassengerApp extends StatelessWidget {
  const PassengerApp({super.key});

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
                    navigatorKey: PassengerApp.navigatorKey,
                    title: AppStrings.appNamePassenger,
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
                            PassengerApp.navigatorKey.currentState
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
/// **100% StatelessWidget** — all navigation is callback-driven.
///
/// Routing logic after splash:
/// 1. If auth token exists → Home (login persisted).
/// 2. If onboarding was seen → Login.
/// 3. First launch → Onboarding (marked seen on complete).
class _AppHome extends StatelessWidget {
  const _AppHome();

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
            isDriver: false,
            headerBuilder: (_) => const LoginHeroIllustration(),
            footerLinkLabel: AppStrings.createAccount,
            onFooterLinkTap: (pageCtx) => _navigateToRegister(pageCtx),
            onOtpSent: (pageCtx, phone) => _navigateToOtp(pageCtx, phone),
            onNeedsRegistration: (pageCtx, phone) =>
                _navigateToRegister(pageCtx, phone: phone),
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
            onVerified: (pageCtx) {
              _navigateToHome(pageCtx);
            },
            onNeedsRegistration: (pageCtx, regPhone) {
              Navigator.of(pageCtx).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (routeCtx) => BlocProvider(
                    create: (_) => sl<AuthBloc>(),
                    child: RegisterPage(
                      phone: regPhone,
                      onRegistered: (regCtx) {
                        _navigateToHome(regCtx);
                      },
                      onLoginTap: (regCtx) => _navigateToLogin(regCtx),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToRegister(BuildContext ctx, {String? phone}) {
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider(
          create: (_) => sl<AuthBloc>(),
          child: RegisterPage(
            phone: phone,
            onRegistered: (regCtx) {
              _navigateToHome(regCtx);
            },
            onLoginTap: (regCtx) => _navigateToLogin(regCtx),
          ),
        ),
      ),
    );
  }

  void _navigateToHome(BuildContext ctx) {
    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => PassengerHomePage(
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
        label: AppStrings.history,
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
        icon: Icons.account_balance_wallet_outlined,
        label: AppStrings.wallet,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => sl<WalletBloc>()
                ..add(const WalletLoadRequested()),
              child: const PassengerWalletPage(),
            ),
          ),
        ),
      ),
      IqSidebarItem(
        icon: Icons.card_giftcard_rounded,
        label: AppStrings.solveAndWin,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider(
              create: (_) => ReferralCubit(referralCode: ''),
              child: const ReferralPage(),
            ),
          ),
        ),
      ),
      IqSidebarItem(
        icon: Icons.language,
        label: AppStrings.changeLanguage,
        onTap: (ctx) => LanguageBottomSheet.show(ctx),
      ),
      IqSidebarItem(
        icon: Icons.star_border_outlined,
        label: AppStrings.favouriteLocation,
        onTap: (ctx) {
          Navigator.of(ctx).push(
            MaterialPageRoute<void>(
              builder: (_) => BlocProvider(
                create: (_) => FavouriteLocationBloc(
                  repository: sl<FavouriteLocationRepository>(),
                )..add(const FavouriteLocationLoadRequested()),
                child: const FavouriteLocationPage(),
              ),
            ),
          );
        },
      ),
      IqSidebarItem(
        icon: Icons.cell_tower,
        label: AppStrings.emergency,
        onTap: (ctx) async {
          final uri = Uri(scheme: 'tel', path: '911');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
      ),
      IqSidebarItem(
        icon: Icons.phone_outlined,
        label: AppStrings.technicalSupport,
        onTap: (ctx) {
          final homeData =
              ctx.read<PassengerHomeBloc>().state.homeData;
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
        icon: Icons.tune,
        label: AppStrings.settings,
        onTap: (ctx) => Navigator.of(ctx).push(
          MaterialPageRoute<void>(
            builder: (_) => BlocProvider.value(
              value: sl<ThemeCubit>(),
              child: const SettingsPage(),
            ),
          ),
        ),
      ),
      IqSidebarItem(
        icon: Icons.logout,
        label: AppStrings.logout,
        onTap: (_) {
          // TODO: handle logout
        },
      ),
    ];
  }
}

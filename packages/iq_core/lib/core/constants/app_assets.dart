/// Asset paths constants
class AppAssets {
  AppAssets._();

  // ─── Base Paths ───
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _lottie = 'assets/lottie';
  static const String _svg = 'assets/svg';

  // ─── Splash ───
  static const String splashWavePattern = '$_images/splash_wave_pattern.webp';
  static const String iqTaxiLogo = '$_svg/iq_taxi_logo.svg';

  // ─── Onboarding Illustrations ───
  /// Pre-rendered PNG — the SVG version has 126+ filter/blur elements
  /// that freeze the UI thread during rendering.
  static const String onboardingRideRequest =
      '$_images/onboarding_ride_request.png';
  static const String onboardingTrackDriver =
      '$_images/onboarding_track_driver.png';
  static const String onboardingEasyPayment =
      '$_images/onboarding_easy_payment.png';

  // ─── Images ───
  static const String loginIllustration = '$_images/login_illustration.png';
  static const String iraqFlag = '$_images/iraq_flag.png';
  static const String profilePlaceholder = '$_images/profile_placeholder.png';
  static const String carYellow = '$_images/car_yellow.png';
  static const String loginHero = '$_images/login_hero.png';
  static const String userHomeBanner = '$_images/user_home_banner.png';

  // ─── SVG Icons ───
  static const String icArrowLeft = '$_svg/arrow_left.svg';
  static const String icArrowBack = '$_svg/ic_arrow_back.svg';
  static const String icLocation = '$_svg/ic_location.svg';
  static const String icSearch = '$_svg/ic_search.svg';
  static const String icMenu = '$_svg/ic_menu.svg';
  static const String icStar = '$_svg/ic_star.svg';
  static const String icClock = '$_svg/ic_clock.svg';
  static const String icRoute = '$_svg/ic_route.svg';
  static const String icCar = '$_svg/ic_car.svg';
  static const String icCash = '$_svg/ic_cash.svg';
  static const String icProfile = '$_svg/ic_profile.svg';
  static const String icTrips = '$_svg/ic_trips.svg';
  static const String icWallet = '$_svg/ic_wallet.svg';
  static const String icSettings = '$_svg/ic_settings.svg';
  static const String icNotification = '$_svg/ic_notification.svg';
  static const String icHome = '$_svg/ic_home.svg';
  static const String icWork = '$_svg/ic_work.svg';
  static const String icFavorite = '$_svg/ic_favorite.svg';
  static const String icPhone = '$_svg/ic_phone.svg';
  static const String icChat = '$_svg/ic_chat.svg';
  static const String icNavigation = '$_svg/ic_navigation.svg';
  static const String icGps = '$_svg/ic_gps.svg';
  static const String icPackage = '$_svg/ic_package.svg';
  static const String icMale = '$_svg/ic_male.svg';
  static const String icFemale = '$_svg/ic_female.svg';
  static const String icCamera = '$_svg/ic_camera.svg';
  static const String icClose = '$_svg/ic_close.svg';
  static const String icCheck = '$_svg/ic_check.svg';
  static const String searchIcon = '$_svg/search.svg';
  static const String gift = '$_images/gift.png';

  // ─── Lottie Animations ───
  static const String lottieLoading = '$_lottie/loading.json';
  static const String lottieSuccess = '$_lottie/success.json';
  static const String lottieError = '$_lottie/error.json';
  static const String lottieSearching = '$_lottie/searching.json';
  static const String lottieEmpty = '$_lottie/empty.json';
}

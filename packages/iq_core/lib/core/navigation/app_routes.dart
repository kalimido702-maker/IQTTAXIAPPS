/// Navigation route names shared between both apps
class AppRoutes {
  AppRoutes._();

  // ─── Common Routes ───
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String register = '/register';

  // ─── Profile ───
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';

  // ─── Trip ───
  static const String tripSummary = '/trip/summary';
  static const String tripDetails = '/trip/details';
  static const String tripHistory = '/trip/history';
  static const String rateTrip = '/trip/rate';

  // ─── Notifications ───
  static const String notifications = '/notifications';

  // ─── Settings ───
  static const String settings = '/settings';
  static const String support = '/support';

  // ─── Chat ───
  static const String chat = '/chat';

  // ─── Passenger Only ───
  static const String passengerHome = '/passenger/home';
  static const String searchDestination = '/passenger/search';
  static const String selectRideType = '/passenger/ride-type';
  static const String confirmRide = '/passenger/confirm';
  static const String trackTrip = '/passenger/track';
  static const String packageDelivery = '/passenger/package';
  static const String packageRecipient = '/passenger/package/recipient';
  static const String interCity = '/passenger/inter-city';

  // ─── Driver Only ───
  static const String driverHome = '/driver/home';
  static const String tripRequest = '/driver/trip-request';
  static const String activeTrip = '/driver/active-trip';
  static const String earnings = '/driver/earnings';
  static const String driverRegister = '/driver/register';
}

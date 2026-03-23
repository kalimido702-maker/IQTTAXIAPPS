/// API endpoint constants
class ApiConstants {
  ApiConstants._();

  // Base URL - replace with your actual API base URL
  static const String baseUrl = 'https://iqttaxi.com/api/v1';

  // ─── Auth ───
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh-token';

  // ─── Profile ───
  static const String profile = '/profile';
  static const String updateProfile = '/profile/update';
  static const String uploadAvatar = '/profile/avatar';

  // ─── Trips ───
  static const String trips = '/trips';
  static const String tripDetails = '/trips/{id}';
  static const String requestTrip = '/trips/request';
  static const String cancelTrip = '/trips/{id}/cancel';
  static const String rateTrip = '/trips/{id}/rate';
  static const String tripHistory = '/trips/history';

  // ─── Location ───
  static const String updateLocation = '/location/update';
  static const String nearbyDrivers = '/location/nearby-drivers';

  // ─── Notifications ───
  static const String notifications = '/notifications';
  static const String markNotificationRead = '/notifications/{id}/read';

  // ─── Wallet ───
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';

  // ─── Support ───
  static const String support = '/support';
  static const String supportTickets = '/support/tickets';

  // ─── Settings ───
  static const String settings = '/settings';

  // ─── Chat ───
  static const String chatMessages = '/chat/{tripId}/messages';
  static const String sendMessage = '/chat/{tripId}/send';

  // ─── Driver Specific ───
  static const String driverStatus = '/driver/status';
  static const String driverEarnings = '/driver/earnings';
  static const String acceptTrip = '/driver/trips/{id}/accept';
  static const String startTrip = '/driver/trips/{id}/start';
  static const String completeTrip = '/driver/trips/{id}/complete';

  // ─── Package Delivery ───
  static const String packageRequest = '/packages/request';
  static const String packageDetails = '/packages/{id}';
}

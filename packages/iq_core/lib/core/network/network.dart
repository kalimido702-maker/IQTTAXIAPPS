// Note: ApiClient is hidden to avoid ambiguous export with core/api/api_client.dart
// Import directly from 'core/network/api_client.dart' when needed (e.g. DI).
export 'api_client.dart' hide ApiClient;
// Note: AuthInterceptor & LoggingInterceptor hidden to avoid conflict with core/api/interceptors/
export 'api_interceptors.dart' hide AuthInterceptor, LoggingInterceptor;
export 'network_info.dart';

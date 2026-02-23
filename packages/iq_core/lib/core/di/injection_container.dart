import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/api_client.dart';
import '../network/auth_service.dart';
import '../network/network_info.dart';
import '../../features/auth/data/datasources/auth_data_source.dart';
import '../../features/auth/data/datasources/auth_data_source_impl.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/send_otp_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/home/data/datasources/home_data_source.dart';
import '../../features/home/data/datasources/home_data_source_impl.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/notification/data/datasources/notification_data_source.dart';
import '../../features/notification/data/datasources/notification_data_source_impl.dart';
import '../../features/notification/data/repositories/notification_repository_impl.dart';
import '../../features/notification/domain/repositories/notification_repository.dart';
import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/favourite_location/data/datasources/favourite_location_data_source.dart';
import '../../features/favourite_location/data/datasources/favourite_location_data_source_impl.dart';
import '../../features/favourite_location/data/repositories/favourite_location_repository_impl.dart';
import '../../features/favourite_location/domain/repositories/favourite_location_repository.dart';
import '../../features/reports/data/datasources/reports_data_source.dart';
import '../../features/reports/data/datasources/reports_data_source_impl.dart';
import '../../features/reports/data/repositories/reports_repository_impl.dart';
import '../../features/reports/domain/repositories/reports_repository.dart';
import '../../features/reports/presentation/bloc/reports_bloc.dart';
import '../../features/earnings/data/datasources/earnings_data_source.dart';
import '../../features/earnings/data/datasources/earnings_data_source_impl.dart';
import '../../features/earnings/data/repositories/earnings_repository_impl.dart';
import '../../features/earnings/domain/repositories/earnings_repository.dart';
import '../../features/earnings/presentation/bloc/earnings_bloc.dart';
import '../../features/settings/presentation/bloc/theme_cubit.dart';
import '../../features/settings/presentation/bloc/locale_cubit.dart';
import '../../features/trip/data/datasources/trip_data_source.dart';
import '../../features/trip/data/datasources/trip_data_source_impl.dart';
import '../../features/trip/data/repositories/trip_repository_impl.dart';
import '../../features/trip/domain/repositories/trip_repository.dart';
import '../../features/trip/presentation/bloc/trip_history_bloc.dart';
import '../../features/wallet/data/datasources/wallet_data_source.dart';
import '../../features/wallet/data/datasources/wallet_data_source_impl.dart';
import '../../features/wallet/data/repositories/wallet_repository_impl.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/wallet/presentation/bloc/wallet_bloc.dart';
import '../../features/chat/data/datasources/support_chat_data_source.dart';
import '../../features/chat/data/datasources/support_chat_data_source_impl.dart';
import '../../features/chat/data/repositories/support_chat_repository_impl.dart';
import '../../features/chat/domain/repositories/support_chat_repository.dart';
import '../../features/profile/data/datasources/profile_data_source.dart';
import '../../features/profile/data/datasources/profile_data_source_impl.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Initialize core dependencies shared between both apps.
///
/// Must be called in `main()` **before** `runApp`.
Future<void> initCoreDependencies() async {
  // Allow re-registration on hot restart
  sl.allowReassignment = true;

  // ── External ──
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);

  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.instance,
  );

  // ── Core ──
  final apiClient = await ApiClient.create();
  sl.registerLazySingleton<ApiClient>(() => apiClient);

  sl.registerLazySingleton<AuthService>(
    () => AuthService(),
  );

  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl<InternetConnectionChecker>()),
  );

  // ── Auth: Data sources ──
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceImpl(
      dio: sl<ApiClient>().dio,
      prefs: sl<SharedPreferences>(),
    ),
  );

  // ── Auth: Repository ──
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl<AuthDataSource>()),
  );

  // ── Auth: Use cases ──
  sl.registerLazySingleton(() => SendOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(sl<AuthRepository>()));

  // ── Auth: BLoC ──
  // Factory → new instance per screen. This is intentional.
  sl.registerFactory(
    () => AuthBloc(
      sendOtpUseCase: sl<SendOtpUseCase>(),
      verifyOtpUseCase: sl<VerifyOtpUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      repository: sl<AuthRepository>(),
    ),
  );

  // ── Home: Data sources ──
  sl.registerLazySingleton<HomeDataSource>(
    () => HomeDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // ── Home: Repository ──
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(dataSource: sl<HomeDataSource>()),
  );

  // ── Notification: Data sources ──
  sl.registerLazySingleton<NotificationDataSource>(
    () => NotificationDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // ── Notification: Repository ──
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(dataSource: sl<NotificationDataSource>()),
  );

  // ── Notification: BLoC ──
  sl.registerFactory(
    () => NotificationBloc(repository: sl<NotificationRepository>()),
  );

  // ── Favourite Location: Data sources ──
  sl.registerLazySingleton<FavouriteLocationDataSource>(
    () => FavouriteLocationDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // ── Favourite Location: Repository ──
  sl.registerLazySingleton<FavouriteLocationRepository>(
    () => FavouriteLocationRepositoryImpl(
        dataSource: sl<FavouriteLocationDataSource>()),
  );

  // ── Reports: Data sources ──
  sl.registerLazySingleton<ReportsDataSource>(
    () => ReportsDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // ── Reports: Repository ──
  sl.registerLazySingleton<ReportsRepository>(
    () => ReportsRepositoryImpl(dataSource: sl<ReportsDataSource>()),
  );

  // ── Reports: BLoC ──
  sl.registerFactory(
    () => ReportsBloc(repository: sl<ReportsRepository>()),
  );

  // ── Earnings: Data sources ──
  sl.registerLazySingleton<EarningsDataSource>(
    () => EarningsDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // ── Earnings: Repository ──
  sl.registerLazySingleton<EarningsRepository>(
    () => EarningsRepositoryImpl(dataSource: sl<EarningsDataSource>()),
  );

  // ── Earnings: BLoC ──
  sl.registerFactory(
    () => EarningsBloc(repository: sl<EarningsRepository>()),
  );

  // ── Theme: Cubit ──
  sl.registerLazySingleton(
    () => ThemeCubit(prefs: sl<SharedPreferences>()),
  );

  // ── Locale: Cubit ──
  sl.registerLazySingleton(
    () => LocaleCubit(prefs: sl<SharedPreferences>()),
  );

  // ── Trip History: Data sources ──
  sl.registerLazySingleton<TripDataSource>(
    () => TripDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // ── Trip History: Repository ──
  sl.registerLazySingleton<TripRepository>(
    () => TripRepositoryImpl(dataSource: sl<TripDataSource>()),
  );

  // ── Trip History: BLoC ──
  sl.registerFactory(
    () => TripHistoryBloc(repository: sl<TripRepository>()),
  );

  // ── Wallet: Data sources ──
  sl.registerLazySingleton<WalletDataSource>(
    () => WalletDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // ── Wallet: Repository ──
  sl.registerLazySingleton<WalletRepository>(
    () => WalletRepositoryImpl(dataSource: sl<WalletDataSource>()),
  );

  // ── Wallet: BLoC ──
  sl.registerFactory(
    () => WalletBloc(repository: sl<WalletRepository>()),
  );

  // ── Support Chat: Data sources ──
  sl.registerLazySingleton<SupportChatDataSource>(
    () => SupportChatDataSourceImpl(
      dio: sl<ApiClient>().dio,
      prefs: sl<SharedPreferences>(),
    ),
  );

  // ── Support Chat: Repository ──
  sl.registerLazySingleton<SupportChatRepository>(
    () => SupportChatRepositoryImpl(dataSource: sl<SupportChatDataSource>()),
  );

  // ── Profile: Data source ──
  sl.registerLazySingleton<ProfileDataSource>(
    () => ProfileDataSourceImpl(dio: sl<ApiClient>().dio),
  );

  // ── Profile: BLoC ──
  sl.registerFactory(
    () => ProfileBloc(dataSource: sl<ProfileDataSource>()),
  );
}

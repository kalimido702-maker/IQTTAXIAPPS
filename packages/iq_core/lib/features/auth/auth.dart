// ─── Domain ───
export 'domain/entities/user_entity.dart';
export 'domain/repositories/auth_repository.dart';
export 'domain/usecases/send_otp_usecase.dart';
export 'domain/usecases/verify_otp_usecase.dart';
export 'domain/usecases/register_usecase.dart';
export 'domain/usecases/logout_usecase.dart';

// ─── Data ───
export 'data/models/user_model.dart';
export 'data/datasources/auth_data_source.dart';
export 'data/datasources/auth_data_source_impl.dart';
export 'data/repositories/auth_repository_impl.dart';

// ─── Presentation: BLoC ───
export 'presentation/bloc/auth_bloc.dart';
export 'presentation/bloc/auth_event.dart';
export 'presentation/bloc/auth_state.dart';
export 'presentation/bloc/login_form_bloc.dart';
export 'presentation/bloc/login_form_event.dart';
export 'presentation/bloc/login_form_state.dart';
export 'presentation/bloc/otp_form_bloc.dart';
export 'presentation/bloc/otp_form_event.dart';
export 'presentation/bloc/otp_form_state.dart';
export 'presentation/bloc/register_form_bloc.dart';
export 'presentation/bloc/register_form_event.dart';
export 'presentation/bloc/register_form_state.dart';

// ─── Presentation: Pages ───
export 'presentation/pages/login_page.dart';
export 'presentation/pages/otp_page.dart';
export 'presentation/pages/register_page.dart';

// ─── Presentation: Widgets ───
export 'presentation/widgets/login_hero_illustration.dart';
export 'presentation/widgets/driver_login_header.dart';

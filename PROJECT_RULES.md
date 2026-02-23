# IQ Taxi – Project Rules

> **Every contributor (human or AI) MUST read this file before writing a single line of code.**

---

## 1. Architecture

| Layer | Lives In | Examples |
|---|---|---|
| **Data – Models** | `data/models/` | `notification_model.dart`, `reports_model.dart` |
| **Data – Data Sources** | `data/datasources/` | Abstract interface + `_impl.dart` with Dio |
| **Domain – Repositories** | `domain/repositories/` (abstract), `data/repositories/` (impl) | `notification_repository.dart` |
| **Presentation – BLoC / Cubit** | `presentation/bloc/` | Events, States, BLoC files |
| **Presentation – Widgets** | `presentation/widgets/` | Small, reusable, single-responsibility widgets |
| **Presentation – Pages** | `presentation/pages/` | One page per file, composes widgets |

Every feature lives under `packages/iq_core/lib/features/<feature_name>/` and follows this exact folder structure.

---

## 2. Absolute Prohibitions (ZERO tolerance)

### 2.1 No Hardcoded Colors
```dart
// ❌ FORBIDDEN
Color(0xFF030303)
Colors.grey

// ✅ REQUIRED
AppColors.textNearBlack
AppColors.gray
```
Every color MUST be a named constant in `AppColors` (`packages/iq_core/lib/core/theme/app_colors.dart`).

### 2.2 No Hardcoded Strings
```dart
// ❌ FORBIDDEN
Text('الاشعارات')
'تسجيل خروج'

// ✅ REQUIRED
IqText(AppStrings.notifications)
AppStrings.logout
```
Every user-visible string MUST be a constant in `AppStrings` (`packages/iq_core/lib/core/constants/app_strings.dart`).

### 2.3 No StatefulWidget – EVER
```dart
// ❌ FORBIDDEN
class MyPage extends StatefulWidget { ... }

// ✅ REQUIRED
class MyPage extends StatelessWidget { ... }
// + BLoC/Cubit for ALL state
```
100% of pages and widgets MUST be `StatelessWidget`. All state goes through `flutter_bloc`.

### 2.4 No Private Widgets Inside Page Files
```dart
// ❌ FORBIDDEN — widget class defined in the same file as the page
class _MyTile extends StatelessWidget { ... } // inside my_page.dart

// ✅ REQUIRED
// my_tile.dart in presentation/widgets/
class MyTile extends StatelessWidget { ... }
```
Every reusable UI piece MUST be extracted to its own file in `presentation/widgets/`.

### 2.5 No Magic Numbers / Inline Dimensions
```dart
// ❌ FORBIDDEN
SizedBox(height: 16)

// ✅ REQUIRED
SizedBox(height: 16.h)  // flutter_screenutil
```
All dimensions must use ScreenUtil extensions (`.w`, `.h`, `.r`, `.sp`).

---

## 3. State Management Rules

| Rule | Detail |
|---|---|
| Package | `flutter_bloc ^9.1.0` only |
| Pattern | BLoC for complex flows (events → states), Cubit for simple toggles |
| Provision | Wrap with `BlocProvider` at the navigation call site |
| Access | `context.read<T>()` for dispatching, `BlocBuilder` / `BlocConsumer` for UI |
| Equatable | All states and events extend `Equatable` |
| Immutability | States MUST be immutable; use `copyWith` for updates |

---

## 4. Dependency Injection

- Library: `get_it ^8.0.3`
- Access pattern: `sl<T>()` (service locator)
- Registration file: `packages/iq_core/lib/core/di/injection_container.dart`
- Order of registration: DataSource → Repository → BLoC/Cubit
- BLoCs: register as **Factory** (new instance per screen)
- Singletons: DataSources, Repositories, Cubits that persist (e.g., `ThemeCubit`)

---

## 5. Networking

| Item | Value |
|---|---|
| Library | `dio ^5.8.0` |
| Base URL | `https://iqttaxi.com/` |
| Client | `ApiClient` (singleton in DI) |
| Auth | `AuthInterceptor` adds `Bearer` token from `SharedPreferences` |
| Error handling | Wrap Dio calls in try/catch, return `dartz Either<Failure, T>` |
| Failure types | `ServerFailure`, `NetworkFailure`, `CacheFailure`, `UnauthorizedFailure` |

---

## 6. Data Source Contract

```dart
// Abstract (contract)
abstract class XxxDataSource {
  Future<Model> getSomething();
}

// Implementation
class XxxDataSourceImpl implements XxxDataSource {
  final Dio _dio;
  XxxDataSourceImpl(this._dio);

  @override
  Future<Model> getSomething() async {
    final response = await _dio.get('api/v1/...');
    return Model.fromJson(response.data['data']);
  }
}
```

---

## 7. File & Naming Conventions

| Type | Convention | Example |
|---|---|---|
| Files | `snake_case.dart` | `notification_bloc.dart` |
| Classes | `PascalCase` | `NotificationBloc` |
| BLoC Events | `PascalCase` ending in verb | `NotificationLoadRequested` |
| BLoC States | `PascalCase` ending in adjective/noun | `NotificationLoaded` |
| Constants | `camelCase` | `AppStrings.notifications` |
| Barrel files | Feature name `.dart` at feature root | `notification/notification.dart` |

---

## 8. Barrel Export Rules

Every feature MUST have a barrel file that exports ALL public files:

```dart
// notification/notification.dart
export 'data/datasources/notification_data_source.dart';
export 'data/datasources/notification_data_source_impl.dart';
export 'data/models/notification_model.dart';
export 'data/repositories/notification_repository_impl.dart';
export 'domain/repositories/notification_repository.dart';
export 'presentation/bloc/notification_bloc.dart';
export 'presentation/bloc/notification_event.dart';
export 'presentation/bloc/notification_state.dart';
export 'presentation/pages/notifications_page.dart';
export 'presentation/widgets/notification_tile.dart';
```

New feature barrels MUST be added to `features/features.dart` which is re-exported by `iq_core.dart`.

---

## 9. Design System

| Item | Value |
|---|---|
| Design size | 440 × 956 (ScreenUtil) |
| Fonts | Almarai (Arabic), Outfit (English/numbers) |
| Direction | RTL (`TextDirection.rtl`) |
| Language | Arabic (primary) |
| Colors file | `app_colors.dart` |
| Typography file | `app_typography.dart` |
| Shared widgets | `IqText`, `IqPrimaryButton`, `IqOutlinedButton`, `IqAppBar`, `IqTextField` |

---

## 10. Monorepo Structure

```
NEWIQTaxiProject/
├── packages/
│   └── iq_core/          ← ALL shared code (features, core, widgets)
├── apps/
│   ├── passenger_app/    ← Passenger-specific UI shell
│   └── driver_app/       ← Driver-specific UI shell
├── melos.yaml
└── PROJECT_RULES.md      ← THIS FILE
```

- `iq_core` contains 100% of business logic, data layers, and reusable UI.
- Apps only contain `main.dart`, `app.dart` (app shell), and app-specific pages (e.g., `PassengerHomePage`, `DriverHomePage`).
- Both apps import `package:iq_core/iq_core.dart` for everything.

---

## 11. Navigation

- Pages are navigated to with `Navigator.of(ctx).push(MaterialPageRoute(...))`.
- BLoC/Cubit providers are created **at the navigation call site**, NOT inside the page.
- Pages must NEVER create their own BLoC — they receive it from the widget tree.

```dart
// ✅ CORRECT — BlocProvider at navigation site
Navigator.of(ctx).push(
  MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) => sl<NotificationBloc>()..add(const NotificationLoadRequested()),
      child: const NotificationsPage(),
    ),
  ),
);
```

---

## 12. Tooling

| Tool | Version / Notes |
|---|---|
| Flutter | ≥ 3.32.0, managed via FVM |
| Dart | ≥ 3.8.0 |
| Melos | Monorepo management |
| Analysis | `fvm dart analyze lib/` — **must produce 0 errors** |
| Format | `fvm dart format .` — must pass |

---

## 13. Checklist Before Any PR / Commit

- [ ] `fvm dart analyze lib/` — 0 errors on all 3 packages
- [ ] No hardcoded colors (grep for `Color(0x` and `Colors.`)
- [ ] No hardcoded Arabic strings (grep for Arabic characters outside `AppStrings`)
- [ ] No `StatefulWidget` anywhere
- [ ] No private widget classes inside page files
- [ ] All new types registered in `injection_container.dart`
- [ ] Barrel files updated with all new exports
- [ ] `features.dart` updated if new feature added
- [ ] All dimensions use ScreenUtil (`.w`, `.h`, `.r`, `.sp`)

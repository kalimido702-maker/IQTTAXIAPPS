# 401 Unauthorized Handling Implementation

## Overview
Implemented a comprehensive 401 response handling system that:
1. **Triggers automatic logout** when a 401 (Unauthorized) response is received
2. **Queues pending requests** to prevent double-sends during logout
3. **Broadcasts 401 events** through a service layer for centralized handling
4. **Blocks new requests** while logout is in progress

---

## Architecture

### 1. **AuthService** (Core Service Layer)
**Location:** `packages/iq_core/lib/core/network/auth_service.dart`

**Purpose:** Singleton service that manages:
- 401 event broadcasting via StreamController
- Request queue during logout
- Refresh status flag

**Key Methods:**
```dart
// Emit 401 event to BLoC
void emitUnauthorized();

// Queue a request while logout is in progress
void queueRequest(RequestOptions options);

// Get all queued requests
List<RequestOptions> getQueuedRequests();

// Clear queue after logout
void clearQueue();

// Set refresh status
void setRefreshing(bool value);

// Get refresh status
bool get isRefreshing;

// Get broadcast stream
Stream<UnauthorizedEvent> get unauthorizedStream;
```

**Key Classes:**
- `UnauthorizedEvent`: Simple event class emitted on 401

---

### 2. **AuthInterceptor** (Updated)
**Location:** `packages/iq_core/lib/core/network/api_interceptors.dart`

**Changes:**
- Now receives `AuthService` instance in constructor
- On 401 response:
  1. Clears stored token from SharedPreferences
  2. Sets `isRefreshing` flag to true (blocks new requests)
  3. Calls `authService.emitUnauthorized()` to trigger BLoC logout
  4. Queues pending requests via `queueRequest()`
- On request: Checks `isRefreshing` flag and queues if logout is in progress

**Flow:**
```
401 Response Received
    ↓
Clear Token
    ↓
Set isRefreshing = true
    ↓
Queue pending requests
    ↓
Emit UnauthorizedEvent
    ↓
AuthBloc receives event
    ↓
BLoC triggers logout
    ↓
Navigate to login screen
```

---

### 3. **AuthBloc** (Updated)
**Location:** `packages/iq_core/lib/features/auth/presentation/bloc/auth_bloc.dart`

**New Event Handler:**
```dart
on<AuthUnauthorizedEvent>(_onUnauthorized);
```

**Handler Implementation:**
```dart
Future<void> _onUnauthorized(
  AuthUnauthorizedEvent event,
  Emitter<AuthState> emit,
) async {
  // Immediately logout without loading state
  final result = await logoutUseCase(const NoParams());
  result.fold(
    (failure) => emit(AuthError(message: 'Session expired. Please login again.')),
    (_) => emit(const AuthUnauthenticated()),
  );
}
```

---

### 4. **AuthEvent** (New Event)
**Location:** `packages/iq_core/lib/features/auth/presentation/bloc/auth_event.dart`

**New Event:**
```dart
class AuthUnauthorizedEvent extends AuthEvent {
  const AuthUnauthorizedEvent();
}
```

---

### 5. **DI Container** (Updated)
**Location:** `packages/iq_core/lib/core/di/injection_container.dart`

**Registration:**
```dart
sl.registerLazySingleton<AuthService>(
  () => AuthService(),
);
```

---

### 6. **ApiClient** (Updated)
**Location:** `packages/iq_core/lib/core/network/api_client.dart`

**Changes:**
- Creates `AuthService` instance in `create()` factory
- Passes `authService` to `AuthInterceptor` constructor

---

## Flow Diagram

```
API Request
    ↓
AuthInterceptor.onRequest()
    ↓
    ├─ Is isRefreshing = true?
    │  └─ YES: Queue request, return early
    │  └─ NO: Attach token, continue
    ↓
API Response
    ↓
AuthInterceptor.onError()
    ↓
    ├─ Status Code = 401?
    │  └─ YES:
    │     1. Clear token from SharedPreferences
    │     2. Set isRefreshing = true
    │     3. Queue any pending requests
    │     4. Emit UnauthorizedEvent
    │  └─ NO: Continue normal error handling
    ↓
AuthBloc receives UnauthorizedEvent
    ↓
_onUnauthorized() handler:
    1. Calls LogoutUseCase
    2. Emits AuthUnauthenticated state
    3. Material app navigates to login
```

---

## Request Queueing Mechanism

### Problem Solved
- **Before:** Multiple requests could be in-flight when 401 occurs
- **After:** New requests are queued while logout completes

### Implementation
1. When 401 received: `isRefreshing = true`
2. Subsequent requests check `isRefreshing` in `onRequest()`
3. If true: Request is queued via `queueRequest(options)`
4. If false: Request proceeds normally with token attachment
5. After logout completes: Queue can be retried or cleared

---

## State Transitions

### Happy Path (401 Received)
```
AuthAuthenticated
    ↓ (401 received in API call)
AuthUnauthenticated (after logout)
    ↓
App navigation to login screen
```

### Error Path (Logout Fails)
```
AuthAuthenticated
    ↓ (401 received + logout fails)
AuthError("Session expired. Please login again.")
    ↓
Error displayed to user
```

---

## Usage Example

### In a Screen
```dart
BlocBuilder<AuthBloc, AuthState>(
  builder: (context, state) {
    if (state is AuthUnauthenticated) {
      // Navigate to login
      Navigator.of(context).pushReplacementNamed('/login');
    }
    return SizedBox.expand(child: _buildContent());
  },
);
```

### Automatic on 401
```
No manual handling needed!
Interceptor → AuthService → BLoC → State Change → Navigation
```

---

## Testing Scenarios

### Scenario 1: Single 401 Response
1. Make API call while authenticated
2. Server returns 401
3. ✅ Token cleared
4. ✅ Logout triggered
5. ✅ Navigation to login
6. ✅ BLoC state → AuthUnauthenticated

### Scenario 2: Multiple Requests During 401
1. Make 3 API calls while authenticated
2. 1st call returns 401
3. ✅ Flag set to `isRefreshing = true`
4. ✅ Calls 2 & 3 queued
5. ✅ Logout happens
6. ✅ Queue cleared
7. ✅ All state cleaned up

### Scenario 3: Logout Fails on 401
1. API returns 401
2. LogoutUseCase fails (e.g., network error)
3. ✅ AuthError state emitted
4. ✅ Error message shown to user
5. ✅ Manual retry available

---

## Key Improvements

| Before | After |
|--------|-------|
| 401 only cleared token silently | 401 triggers full logout flow |
| No request queuing | Pending requests queued during logout |
| No broadcast mechanism | AuthService broadcasts events |
| BLoC unaware of 401 | BLoC explicitly handles unauthorized event |
| Potential double-sends | Refresh flag prevents overlapping requests |

---

## File Changes Summary

| File | Changes |
|------|---------|
| `auth_service.dart` | **NEW** - Singleton service with broadcast stream + queue |
| `auth_interceptors.dart` | Updated onError() to use AuthService, added onRequest() queuing logic |
| `auth_event.dart` | Added AuthUnauthorizedEvent class |
| `auth_bloc.dart` | Added on<AuthUnauthorizedEvent>() handler |
| `injection_container.dart` | Registered AuthService as lazySingleton |
| `api_client.dart` | Pass AuthService to AuthInterceptor |

---

## No Breaking Changes
- All existing functionality preserved
- Backward compatible with current auth flow
- Automatic behavior, no manual intervention needed
- Ready for production use

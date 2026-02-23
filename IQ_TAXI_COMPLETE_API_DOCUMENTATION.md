# 📚 IQ Taxi - Complete API & System Documentation

> **Base URL:** `https://iqttaxi.com/`
> **Authentication:** Bearer Token via `Authorization` header
> **Response Format:** JSON with `{ success, message, data }` structure
> **Architecture:** Clean Architecture + BLoC Pattern (Flutter)
> **Languages:** Arabic (RTL) + English (LTR)
> **Map Providers:** Google Maps

---

# 📋 Table of Contents

1. [Application Architecture](#1-application-architecture)
2. [Authentication & Registration APIs](#2-authentication--registration-apis)
3. [Home & Map APIs](#3-home--map-apis)
4. [Booking & Trip Lifecycle APIs](#4-booking--trip-lifecycle-apis)
5. [Chat System](#5-chat-system)
6. [Bidding System](#6-bidding-system)
7. [Payment System](#7-payment-system)
8. [Firebase Realtime Database](#8-firebase-realtime-database)
9. [Push Notifications](#9-push-notifications)
10. [Account & Profile APIs](#10-account--profile-apis)
11. [Wallet APIs](#11-wallet-apis)
12. [Driver-Specific APIs](#12-driver-specific-apis)
13. [Owner/Fleet APIs](#13-ownerfleet-apis)
14. [Support & Complaints APIs](#14-support--complaints-apis)
15. [Data Models Reference](#15-data-models-reference)
16. [App Navigation Flow](#16-app-navigation-flow)
17. [Shared Preferences Keys](#17-shared-preferences-keys)
18. [Constants & Configuration](#18-constants--configuration)

---

# 1. Application Architecture

## 1.1 Overall Old Structure

```
lib/
├── main.dart                 # Entry point
├── app/
│   ├── app.dart              # MaterialApp + MultiBlocProvider
│   └── localization.dart     # LocalizationBloc (locale + dark mode)
├── common/                   # Shared utilities, themes, routes, constants
├── core/
│   ├── network/              # Dio HTTP client, endpoints, error handling
│   ├── services/             # Navigation, BLoC observer, duration calculator
│   └── pushnotification/     # FCM handling
├── db/                       # Drift (SQLite) local database
├── di/
│   └── locator.dart          # GetIt dependency injection
├── features/
│   ├── auth/                 # Login, Register, OTP, Referral
│   ├── home/                 # Home page, Map, Destination selection
│   ├── bookingpage/          # (User) Booking, Trip, Invoice, Review
│   ├── account/              # Profile, Wallet, History, Settings, etc.
│   ├── landing/              # Onboarding screens
│   ├── loading/              # Splash & permission check
│   └── language/             # Language selection
├── generated/                # Auto-generated code
└── l10n/                     # Localization strings
```

## 1.2 Feature Architecture (Clean Architecture per feature)

```
feature/
├── domain/
│   ├── models/               # Data models (fromJson)
│   └── repositories/         # Abstract repository interfaces
├── data/
│   ├── repository/           # Raw API calls (Dio)
│   └── repo_implementation/  # Repository implementations (error handling)
├── application/
│   ├── feature_bloc.dart     # BLoC (events + states + handlers)
│   ├── feature_event.dart    # Event classes
│   ├── feature_state.dart    # State classes
│   └── usecases/             # Use case wrappers
└── presentation/
    ├── pages/                # Full-screen pages
    └── widgets/              # Reusable UI components
```

## 1.3 HTTP Client Configuration

```
Base URL: https://iqttaxi.com/
Connect Timeout: 30 seconds
Receive Timeout: 30 seconds
Rate Limit: 429 responses auto-retried (exponential backoff: 500ms → 10s max, 10 retries)
Request Deduplication: Duplicate requests to same endpoint wait for first to complete
Logging: PrettyDioLogger enabled in debug mode
```

## 1.4 Error Handling Pattern

Every repository method returns `Either<Failure, T>` from dartz package:

- `Left(GetDataFailure(message))` — Server/data errors
- `Left(InPutDataFailure(message))` — Input validation errors
- `Right(data)` — Success

Status code handling:

- `400` → Bad request error message
- `401` → Force logout
- `429` → Rate limited (auto-retried)
- `500` → Server error

---

# 2. Authentication & Registration APIs

## 2.1 Common Module Check

```
GET api/v1/common/modules
Auth: Not required
```

**Response:**

```json
{
  "success": true,
  "message": "...",
  "enable_owner_login": "0" | "1",        // Driver app only
  "enable_email_otp": true | false,
  "firebase_otp_enabled": true | false,
  "enable_refferal": true | false,         // User app: "enable_refferal"
  "enable_driver_referral_earnings": true   // Driver app
}
```

## 2.2 Country List

```
GET api/v1/countries
Auth: Not required
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "dial_code": "+964",
      "name": "Iraq",
      "code": "IQ",
      "flag": "https://...",
      "dial_min_length": 10,
      "dial_max_length": 10,
      "active": 1,
      "default": 1
    }
  ]
}
```

## 2.3 User Registration (User App)

```
POST api/v1/user/register
Auth: Not required
Content-Type: multipart/form-data
```

**Body:**


| Field          | Type   | Description                         |
| -------------- | ------ | ----------------------------------- |
| `mobile`       | string | Phone number (without country code) |
| `device_token` | string | FCM token                           |
| `country`      | string | Country code (e.g., "+964")         |
| `login_by`     | string | "android" or "ios"                  |
| `lang`         | string | Language code (e.g., "ar")          |

**Response:**

```json
{
  "success": true,
  "message": "...",
  "access_token": "Bearer xxx..."
}
```

## 2.4 Driver Registration (Driver App)

```
POST api/v1/driver/register
Auth: Not required
Content-Type: multipart/form-data
```

**Body:** Same as user registration

**Response:**

```json
{
  "message": "...",
  "mode": "register",
  "active": 0 | 1,
  "uuid": "unique-id",
  "whatsapp_deeplink": "https://wa.me/..."   // Optional WhatsApp verification link
}
```

## 2.5 Verify User (Check if user exists)

```
User:   POST api/v1/user/validate-mobile-for-login
Driver: POST api/v1/driver/validate-mobile-for-login
Auth: Not required
```

**Response:**

```json
{
  "success": true,
  "message": "...",
  "status_code": 200
}
```

## 2.6 Send Mobile OTP

```
POST api/v1/mobile-otp
Auth: Not required
```

**Body:**


| Field          | Type   |
| -------------- | ------ |
| `mobile`       | string |
| `country_code` | string |

**Response:**

```json
{
  "success": true,
  "message": "OTP sent successfully"
}
```

## 2.7 Verify Mobile OTP

```
User:   POST api/v1/user/validate-mobile
Driver: POST api/v1/driver/validate-mobile
Auth: Not required
```

**Body:**


| Field | Type              |
| ----- | ----------------- |
| `otp` | string (6 digits) |

**Response (Login):**

```json
{
  "success": true,
  "token_type": "Bearer",
  "expires_in": 31536000,
  "access_token": "xxx..."
}
```

## 2.8 User Login

```
User:   POST api/v1/user/login
Driver: POST api/v1/driver/login
Auth: Not required
Content-Type: multipart/form-data
```

**Body:**


| Field          | Type   | Description        |
| -------------- | ------ | ------------------ |
| `mobile`       | string | Phone number       |
| `device_token` | string | FCM token          |
| `login_by`     | string | "android" or "ios" |

**Response:**

```json
{
  "success": true,
  "token_type": "Bearer",
  "expires_in": 31536000,
  "access_token": "xxx..."
}
```

## 2.9 Verify Email OTP

```
POST api/v1/validate-email-otp
Auth: Not required
```

**Response:**

```json
{
  "success": true
}
```

## 2.10 Update Password

```
User:   POST api/v1/user/update-password
Driver: POST api/v1/driver/update-password
Auth: Not required
```

**Body:**


| Field              | Type   | Description             |
| ------------------ | ------ | ----------------------- |
| `email` / `mobile` | string | User identifier         |
| `password`         | string | Min 8 characters        |
| `role`             | string | Optional (driver/owner) |

## 2.11 Submit Referral Code

```
User:   POST api/v1/update/user/referral
Driver: POST api/v1/update/driver/referral
Auth: Bearer Token
```

**Body:**


| Field           | Type                       |
| --------------- | -------------------------- |
| `refferal_code` | string (or "Skip" to skip) |

## 2.12 Onboarding Screens

```
User:   GET api/v1/on-boarding
Driver: GET api/v1/on-boarding-driver
Owner:  GET api/v1/on-boarding-owner
Auth: Not required
```

**Response:**

```json
{
  "success": true,
  "data": {
    "onboarding": {
      "data": [
        {
          "order": 1,
          "id": 1,
          "screen": "screen_1",
          "title": "مرحباً بك",
          "onboarding_image": "https://...",
          "description": "وصف...",
          "active": 1
        }
      ]
    }
  }
}
```

---

# 3. Home & Map APIs

## 3.1 Get User Details

```
GET api/v1/user
Auth: Bearer Token
```

**Response — User App:**

```json
{
  "success": true,
  "data": {
    "id": 1,
    "name": "User Name",
    "last_name": "",
    "username": "",
    "email": "user@email.com",
    "mobile": "9641234567890",
    "country_code": "+964",
    "profile_picture": "https://...",
    "gender": "male",
    "active": 1,
    "approve": 1,
    "refferal_code": "ABC123",
    "currency_code": "IQD",
    "currency_symbol": "د.ع",
    "show_rental_ride": true,
    "enable_modules_for_applications": "taxi",  // "taxi", "delivery", "both"
    "enableBiddingRideType": true,
    "show_outstation_ride_feature": "1",
    "mapType": "google_map",                     // "google_map" or "open_street_map"
    "ChatId": "chat-id-123",
    "notify_count": 5,
    "conversation_id": "conv-123",
    "enable_country_restrict_on_map": true,
    "enableWazeMap": true,
    "enable_pet_preference": true,
    "enable_luggage_preference": true,
    "enableSubVehicleTypeModule": true,
    "country_code_for_restriction": "IQ",
  
    "onTripRequest": { /* Active trip data - see Section 15 */ },
    "metaRequest": { /* Pending request data */ },
  
    "wallet": {
      "amount_balance": 50000.0,
      "currency_code": "IQD",
      "currency_symbol": "د.ع"
    },
  
    "favouriteLocations": {
      "home": [{ "id": 1, "address": "...", "pick_lat": 33.31, "pick_lng": 44.36 }],
      "work": [{ "id": 2, "address": "...", "pick_lat": 33.32, "pick_lng": 44.37 }],
      "others": [{ "id": 3, "address": "...", "pick_lat": 33.33, "pick_lng": 44.38 }]
    },
  
    "sos": {
      "data": [
        { "id": 1, "name": "Emergency", "number": "911", "user_type": "admin" },
        { "id": 2, "name": "Contact", "number": "+964...", "user_type": "user" }
      ]
    },
  
    "bannerImage": [
      { "id": 1, "image": "https://...", "redirect_link": "https://..." }
    ]
  }
}
```

**Response — Driver App (additional fields):**

```json
{
  "data": {
    "role": "driver",
    "available": "1",
    "approve": 1,
    "uploaded_document": true,
    "declined_reason": null,
    "owner_id": null,
    "driver_mode": "driver",           // "driver" | "owner" | "both"
    "enable_bidding": true,
    "enable_bid_on_fare": true,
    "accept_duration": 30,              // Seconds to accept/reject ride
    "service_location_id": "loc-1",
    "transport_type": "taxi",
    "vehicle_type_id": 1,
    "vehicle_type_name": "Sedan",
    "vehicle_type_icon": "car",
    "car_make": "Toyota",
    "car_model": "Camry",
    "car_color": "White",
    "car_number": "ABC 123",
  
    "subscription": {
      "data": [{ /* subscription plan data */ }]
    },
    "has_subscription": true,
    "loyalty_points": {
      "data": [{ /* loyalty data */ }]
    },
  
    "total_earnings": "1500000",
    "total_kms": "5000",
    "total_minutes_online": "12000",
    "total_rides_taken": "450",
  
    "enable_peak_zone_feature": true,
    "enable_second_ride_for_driver": true,
    "has_waiting_ride": null,
    "enable_my_route_feature": true,
    "my_route_address": { /* address data */ },
  
    "sub_vehicle_type": [
      { "id": 1, "name": "Economy", "is_selected": 1 }
    ]
  }
}
```

## 3.2 Update User Location

```
POST api/v1/user/update-location
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field         | Type   |
| ------------- | ------ |
| `current_lat` | string |
| `current_lng` | string |

## 3.3 Get Ride Modules

```
GET api/v1/common/ride_modules
Auth: Bearer Token
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Taxi",
      "icon": "https://...",
      "enabled": true
    },
    {
      "id": 2,
      "name": "Delivery",
      "icon": "https://...",
      "enabled": true
    }
  ]
}
```

## 3.4 Recent Routes / Searches

```
GET api/v1/request/list-recent-searches
Auth: Bearer Token
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "pick_address": "...",
      "pick_lat": 33.31,
      "pick_lng": 44.36,
      "drop_address": "...",
      "drop_lat": 33.32,
      "drop_lng": 44.37,
      "polyline": "encoded_polyline",
      "stops": [
        { "address": "...", "lat": 33.315, "lng": 44.365 }
      ],
      "poc_name": "...",
      "poc_mobile": "...",
      "poc_instruction": "..."
    }
  ]
}
```

## 3.5 Service Location Verify

```
POST api/v1/request/serviceVerify
Auth: Bearer Token
```

**Body:**


| Field      | Type   |
| ---------- | ------ |
| `pick_lat` | double |
| `pick_lng` | double |

## 3.6 Address Autocomplete (Google Places)

```
GET https://maps.googleapis.com/maps/api/place/autocomplete/json
```

**Query Params:**


| Field        | Value                                         |
| ------------ | --------------------------------------------- |
| `input`      | search text                                   |
| `key`        | Google Maps API key                           |
| `components` | `country:IQ` (if country restriction enabled) |

## 3.7 Address Autocomplete (OpenStreetMap)

```
GET https://nominatim.openstreetmap.org/search?q={query}&format=json&addressdetails=1
```

## 3.8 Geocoding (Lat/Lng → Address)

### Google:

```
GET https://maps.googleapis.com/maps/api/geocode/json?latlng={lat},{lng}&key={mapKey}
```

### OpenStreetMap:

```
GET https://nominatim.openstreetmap.org/reverse?lat={lat}&lon={lng}&format=json
```

## 3.9 Get Polyline (Route Directions)

### Google Routes API:

```
POST https://routes.googleapis.com/directions/v2:computeRoutes
```

**Headers:**


| Header                    | Value                                                                   |
| ------------------------- | ----------------------------------------------------------------------- |
| `Content-Type`            | `application/json`                                                      |
| `X-Goog-Api-Key`          | Google API Key                                                          |
| `X-Goog-FieldMask`        | `routes.duration,routes.distanceMeters,routes.polyline.encodedPolyline` |
| `X-Android-Package`       | Package name (Android)                                                  |
| `X-Android-Cert`          | SHA cert (Android)                                                      |
| `X-Ios-Bundle-Identifier` | Bundle ID (iOS)                                                         |

**Body:**

```json
{
  "origin": {
    "location": {
      "latLng": { "latitude": 33.31, "longitude": 44.36 }
    }
  },
  "destination": {
    "location": {
      "latLng": { "latitude": 33.32, "longitude": 44.37 }
    }
  },
  "intermediates": [
    {
      "location": {
        "latLng": { "latitude": 33.315, "longitude": 44.365 }
      }
    }
  ],
  "travelMode": "DRIVE",
  "routingPreference": "TRAFFIC_AWARE"
}
```

**Response:**

```json
{
  "routes": [
    {
      "polyline": { "encodedPolyline": "abc123..." },
      "distanceMeters": 5000,
      "duration": "900s"
    }
  ]
}
```

### OpenStreetMap OSRM:

```
GET https://routing.openstreetmap.de/routed-car/route/v1/driving/{pickLng},{pickLat};{dropLng},{dropLat}?overview=false&geometries=polyline&steps=true
```

## 3.10 Service Location

```
GET api/v1/servicelocation
Auth: Bearer Token
```

**Response:**

```json
{
  "success": true,
  "data": [
    { "id": "1", "name": "Baghdad" }
  ]
}
```

---

# 4. Booking & Trip Lifecycle APIs

## 4.1 Complete Trip Flow Diagram

```
[User App]                                              [Driver App]
    │                                                        │
    ├── 1. ETA Request ──────────────────────────────────────┤
    │   (Get vehicle types + pricing)                        │
    │                                                        │
    ├── 2. Create Request ───────────────────────────────────┤
    │   (Book a ride)                                        │
    │                                                        │
    ├── 3. Stream Firebase ──────── request-meta ────────────┤ ← 3. Stream Firebase
    │   (Wait for driver)             │                      │   (Receive ride request)
    │                                 │                      │
    │                                 │              4. Accept/Reject ──┤
    │                                 │                      │
    ├── 5. Driver Found ─────── requests/{id} ───────────────┤ ← 5. Ride Assigned
    │   (Stream trip updates)         │                      │
    │                                 │              6. Navigate to Pickup ──┤
    │                                 │                      │
    │                                 │              7. Arrived ──────────┤
    ├── 8. Driver Arrived ───────────┤                       │
    │                                 │                      │
    │                                 │              9. Start Ride ──────┤
    ├── 10. Trip Started ────────────┤                       │
    │   (Chat, SOS, Location Edit)    │                      │
    │                                 │              11. End Ride ───────┤
    ├── 12. Trip Completed ──────────┤                       │
    │                                 │                      │
    ├── 13. Invoice Page ────────────┤              13. Invoice Page ───┤
    │   (View fare, add tip)          │                      │
    │                                 │              14. Payment Received ──┤
    ├── 15. Review Driver ───────────┤              15. Review User ────┤
    │                                                        │
    └── Done ────────────────────────────────────── Done ─────┘
```

## 4.2 ETA Request (Get Vehicle Types & Pricing)

```
POST api/v1/request/eta
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field                    | Type       | Description                      |
| ------------------------ | ---------- | -------------------------------- |
| `pick_lat`               | double     | Pickup latitude                  |
| `pick_lng`               | double     | Pickup longitude                 |
| `drop_lat`               | double     | Drop-off latitude                |
| `drop_lng`               | double     | Drop-off longitude               |
| `ride_type`              | int        | 1 = normal                       |
| `transport_type`         | string     | "taxi", "delivery"               |
| `promo_code`             | string     | Optional coupon code             |
| `stops`                  | JSON array | `[{"lat": 33.31, "lng": 44.36}]` |
| `pickup_poc_name`        | string     | Delivery: sender name            |
| `pickup_poc_mobile`      | string     | Delivery: sender phone           |
| `pickup_poc_instruction` | string     | Delivery: sender instructions    |
| `drop_poc_name`          | string     | Delivery: receiver name          |
| `drop_poc_mobile`        | string     | Delivery: receiver phone         |
| `drop_poc_instruction`   | string     | Delivery: receiver instructions  |
| `is_outstation`          | int        | 0 or 1                           |
| `selected_preferences`   | JSON       | `[{"id": 1}]`                    |

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "zone_type_id": 1,
      "name": "Sedan",
      "icon": "https://...",
      "short_description": "Comfortable ride",
      "capacity": 4,
      "is_default": 1,
      "payment_type": {
        "cash": true,
        "wallet": true,
        "card": true,
        "online_payment": true
      },
    
      "base_price": 2500,
      "base_distance": 2,
      "price_per_distance": 500,
      "price_per_time": 100,
      "distance": 5.2,
      "time": 15,
      "total": 5000,
      "approximate_fare": 5000,
      "min_fare": 2500,
      "max_fare": 7500,
      "currency": "IQD",
      "currency_symbol": "د.ع",
    
      "dispatch_type": "normal",       // "normal" | "bidding" | "both"
      "bidding_low_percentage": 10,
      "bidding_high_percentage": 30,
    
      "promo_discount": 500,
      "has_discount": true,
      "promo_id": "promo-1",
    
      "waiting_charge": 200,
      "waiting_charge_per_min": 50,
      "free_waiting_time_in_mins_before_trip_start": 5,
      "free_waiting_time_in_mins_after_trip_start": 3,
    
      "airport_surge_fee": 0,
      "cancellation_fee": 1000,
    
      "category": [
        {
          "id": 1,
          "name": "Category 1",
          "data": [
            { "id": 1, "zone_type_id": 1, "name": "Option A", "price": 500 }
          ]
        }
      ],
    
      "preferences": [
        { "id": 1, "name": "Pet Friendly", "price": 500 }
      ]
    }
  ]
}
```

## 4.3 Rental ETA Request (Rental Packages)

```
POST api/v1/request/list-packages
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field            | Type   |
| ---------------- | ------ |
| `pick_lat`       | double |
| `pick_lng`       | double |
| `transport_type` | string |

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "4 Hours / 40 KM",
      "short_description": "City tour",
      "min_price": 25000,
      "max_price": 50000,
      "types": [
        {
          "zone_type_id": 1,
          "name": "Sedan",
          "icon": "https://...",
          "total": 30000,
          "base_price": 20000,
          "price_per_distance": 300,
          "price_per_time": 50,
          "preferences": [
            { "id": 1, "name": "Pet Friendly", "price": 500 }
          ]
        }
      ]
    }
  ]
}
```

## 4.4 Create Ride Request (User App)

```
POST api/v1/request/create
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field                  | Type       | Description                                |
| ---------------------- | ---------- | ------------------------------------------ |
| `pick_lat`             | double     | Pickup latitude                            |
| `pick_lng`             | double     | Pickup longitude                           |
| `drop_lat`             | double     | Drop-off latitude                          |
| `drop_lng`             | double     | Drop-off longitude                         |
| `pick_address`         | string     | Pickup address text                        |
| `drop_address`         | string     | Drop-off address text                      |
| `vehicle_type`         | int        | Selected vehicle type ID                   |
| `ride_type`            | int        | 1 = normal, 2 = ride later                 |
| `payment_opt`          | int        | 1 = cash, 2 = wallet, 0 = card, 3 = online |
| `transport_type`       | string     | "taxi" / "delivery"                        |
| `offer_amount`         | double     | Bidding: custom fare amount                |
| `is_bid_ride`          | int        | 0 or 1                                     |
| `promo_code`           | string     | Optional coupon code                       |
| `stops`                | JSON array | Multi-stop addresses                       |
| `polyline`             | string     | Encoded polyline                           |
| `is_later`             | int        | 0 or 1                                     |
| `trip_start_time`      | string     | Scheduled ride datetime                    |
| `instructions`         | string     | Driver instructions                        |
| `request_eta_amount`   | double     | Estimated fare amount                      |
| `is_outstation`        | int        | 0 or 1                                     |
| `is_round_trip`        | int        | 0 or 1                                     |
| `return_date`          | string     | Outstation return date                     |
| `package_id`           | int        | Rental package ID                          |
| `selected_preferences` | JSON       | `[{"id": 1}]`                              |

## 4.5 Create Delivery Request (User App)

```
POST api/v1/request/delivery/create
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Additional Body Fields:**


| Field                    | Type   | Description           |
| ------------------------ | ------ | --------------------- |
| `pickup_poc_name`        | string | Sender name           |
| `pickup_poc_mobile`      | string | Sender phone          |
| `pickup_poc_instruction` | string | Sender instructions   |
| `drop_poc_name`          | string | Receiver name         |
| `drop_poc_mobile`        | string | Receiver phone        |
| `drop_poc_instruction`   | string | Receiver instructions |
| `goods_type_id`          | int    | Type of goods         |
| `goods_type_quantity`    | string | Quantity description  |

## 4.6 Cancel Request (User App)

```
POST api/v1/request/cancel
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field             | Type   |
| ----------------- | ------ |
| `request_id`      | string |
| `reason`          | string |
| `custom_reason`   | string |
| `is_cancel_timer` | int    |

## 4.7 Cancel Reasons

```
GET api/v1/common/cancallation/reasons
Auth: Bearer Token
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "user_type": "user",
      "arrival_status": "before",    // "before" | "after" driver arrival
      "reason": "Changed my mind"
    }
  ]
}
```

## 4.8 Change Drop Location (User App)

```
POST api/v1/request/change-drop-location
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field          | Type       | Description             |
| -------------- | ---------- | ----------------------- |
| `request_id`   | string     | Active trip ID          |
| `drop_lat`     | double     | New drop-off latitude   |
| `drop_lng`     | double     | New drop-off longitude  |
| `drop_address` | string     | New drop-off address    |
| `polyline`     | string     | New encoded polyline    |
| `stops`        | JSON array | Updated multi-stop list |

## 4.9 Submit User Rating/Review

```
POST api/v1/request/rating
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type      |
| ------------ | --------- |
| `request_id` | string    |
| `rating`     | int (1-5) |
| `comment`    | string    |

## 4.10 Add Driver Tips (User App)

```
POST api/v1/request/user/driver-tip
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   |
| ------------ | ------ |
| `request_id` | string |
| `tips`       | double |

**Response includes updated fare breakdown.**

## 4.11 Change Payment Method (User App, during ride)

```
POST api/v1/request/user/payment-method
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field         | Type   | Description                        |
| ------------- | ------ | ---------------------------------- |
| `request_id`  | string | Active trip ID                     |
| `payment_opt` | int    | 1=cash, 2=wallet, 0=card, 3=online |

---

## 4.12 Driver-Side Trip APIs

### Respond to Request (Accept/Reject)

```
POST api/v1/request/respond
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   | Description            |
| ------------ | ------ | ---------------------- |
| `request_id` | string | Trip request ID        |
| `is_accept`  | int    | 1 = accept, 0 = reject |

### Ride Arrived

```
POST api/v1/request/arrived
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   |
| ------------ | ------ |
| `request_id` | string |

### Ride Started

```
POST api/v1/request/started
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   | Description           |
| ------------ | ------ | --------------------- |
| `request_id` | string | Trip ID               |
| `pick_lat`   | double | Current latitude      |
| `pick_lng`   | double | Current longitude     |
| `otp`        | string | OTP code (if enabled) |

### Ride End

```
POST api/v1/request/end
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field                            | Type   | Description                      |
| -------------------------------- | ------ | -------------------------------- |
| `request_id`                     | string | Trip ID                          |
| `drop_lat`                       | double | Current latitude                 |
| `drop_lng`                       | double | Current longitude                |
| `distance`                       | double | Trip distance in km              |
| `before_trip_start_waiting_time` | int    | Wait time before start (seconds) |
| `after_trip_start_waiting_time`  | int    | Wait time after start (seconds)  |

### Payment Received (Cash rides)

```
POST api/v1/request/payment-confirm
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   |
| ------------ | ------ |
| `request_id` | string |

### Cancel by Driver

```
POST api/v1/request/cancel/by-driver
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field           | Type   |
| --------------- | ------ |
| `request_id`    | string |
| `reason`        | string |
| `custom_reason` | string |

### Upload Proof (Delivery)

```
POST api/v1/request/upload-proof
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field          | Type         |
| -------------- | ------------ |
| `request_id`   | string       |
| `before_image` | File (image) |
| `after_image`  | File (image) |

### Stop Complete (Multi-stop)

```
POST api/v1/request/stop-complete
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   |
| ------------ | ------ |
| `request_id` | string |
| `stop_id`    | string |

### Stop OTP Verify

```
POST api/v1/request/stop-otp-verify
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   |
| ------------ | ------ |
| `request_id` | string |
| `stop_id`    | string |
| `otp`        | string |

### Additional Charge

```
POST api/v1/request/additional-charge
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   |
| ------------ | ------ |
| `request_id` | string |
| `amount`     | double |
| `remarks`    | string |

### Bidding Accept (User App)

```
POST api/v1/request/respond-for-bid
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field                | Type   |
| -------------------- | ------ |
| `request_id`         | string |
| `accepted_ride_fare` | double |
| `driver_id`          | string |
| `offer_amount`       | double |

---

# 5. Chat System

## 5.1 In-Ride Chat (User ↔ Driver)

### Get Chat History

```
POST api/v1/request/chat-history
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   |
| ------------ | ------ |
| `request_id` | string |

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "request_id": "req-123",
      "from_type": 1,           // 1 = user sent, 2 = driver sent
      "message": "مرحبا",
      "delivered": 1,
      "seen": 0,
      "created_at": "2026-02-11T10:00:00Z",
      "updated_at": "2026-02-11T10:00:00Z"
    }
  ]
}
```

### Send Chat Message

```
POST api/v1/request/send
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   | Description     |
| ------------ | ------ | --------------- |
| `request_id` | string | Active trip ID  |
| `message`    | string | Message content |

### Mark Messages as Seen

```
POST api/v1/request/seen
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   |
| ------------ | ------ |
| `request_id` | string |

### Real-time Chat Sync (Firebase)

Chat notifications are synced via Firebase Realtime Database at `requests/{requestId}`:

**User sends message:** Updates `message_by_user: chatHistoryList.length`
**Driver sends message:** Updates `message_by_driver: chats.length + 1`

Both apps listen to the corresponding field changes to trigger chat history refresh.

## 5.2 Admin Chat (User/Driver ↔ Admin)

### Send Message to Admin

```
User:   POST api/v1/request/user-send-message
Driver: POST api/v1/request/user-send-message
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field     | Type                                               |
| --------- | -------------------------------------------------- |
| `chat_id` | string (from`userData.chatId` / `conversation_id`) |
| `message` | string                                             |

### Get Admin Chat History

```
User:   GET api/v1/request/user-chat-history
Driver: GET api/v1/request/user-chat-history
Auth: Bearer Token
```

**Query Params:**


| Field     | Type   |
| --------- | ------ |
| `chat_id` | string |

**Response:**

```json
{
  "success": true,
  "data": {
    "chat_data": {
      "id": "chat-123",
      "conversations": [
        {
          "id": 1,
          "message": "مرحبا",
          "sender_id": "user-1",
          "created_at": "2026-02-11T10:00:00Z"
        }
      ]
    }
  }
}
```

### Mark Admin Messages Seen

```
GET api/v1/request/update-notification-count
Auth: Bearer Token
```

### Real-time Admin Chat (Firebase)

Admin chat streams via Firebase at path `conversation/{chatId}` using `.onValue`.
The `chatId` is obtained from `userData.conversationId` or `userData.chatId`.

---

# 6. Bidding System

## 6.1 How Bidding Works

1. **User** creates a ride request with `is_bid_ride: 1` and `offer_amount`
2. **System** creates a node at `bid-meta/{requestId}` in Firebase with request details + geohash
3. **Driver App** streams `bid-meta` using geohash-based geo-query to find nearby bid requests
4. **Driver** views the bid and responds with their price (within `biddingLowPercentage` to `biddingHighPercentage` of original)
5. **Driver's bid** is written to `bid-meta/{requestId}/drivers/driver_{driverId}`
6. **User App** streams `bid-meta/{requestId}` to see all incoming driver bids
7. **User** can accept or decline individual driver bids
8. On accept, normal ride flow begins

## 6.2 Firebase Bid Data Structure

```
bid-meta/{requestId}/
├── request_id: "abc123"
├── g: "sv8gh1"                          # Geohash for geo-query
├── pick_lat: 33.312
├── pick_lng: 44.366
├── vehicle_type: "type_id"
├── currency: "IQD"
├── price: "5000"                         # User's offer price
├── updated_at: ServerValue.timestamp
└── drivers/
    └── driver_{driverId}/
        ├── driver_id: 123
        ├── driver_name: "Ali"
        ├── driver_img: "https://..."
        ├── price: "5500"                 # Driver's counter-offer
        ├── bid_time: ServerValue.timestamp
        ├── is_rejected: "none"           # "none" | "by_driver" | "by_user"
        ├── vehicle_make: "Toyota"
        ├── vehicle_model: "Camry"
        ├── vehicle_number: "ABC123"
        ├── lat: 33.312
        ├── lng: 44.366
        ├── rating: "4.5"
        └── mobile: "+964..."
```

## 6.3 Bid Price Controls

```
Min Price = ETA Total × (1 - biddingLowPercentage / 100)
Max Price = ETA Total × (1 + biddingHighPercentage / 100)
```

## 6.4 User Updates Bid Price

When user changes offer price:

1. Updates `bid-meta/{requestId}/price` and `updated_at`
2. Removes all `bid-meta/{requestId}/drivers` (clears existing bids)
3. Drivers see the updated price and can re-bid

---

# 7. Payment System

## 7.1 Payment Options


| Option Code | Name           | Description                         |
| ----------- | -------------- | ----------------------------------- |
| `1`         | Cash           | Driver collects cash from user      |
| `2`         | Wallet         | Deducted from user's wallet balance |
| `0`         | Card           | Stripe saved card payment           |
| `3`         | Online Payment | External payment gateway (WebView)  |

## 7.2 Supported Payment Gateways


| Gateway      | Key Fields                                                                                                            |
| ------------ | --------------------------------------------------------------------------------------------------------------------- |
| Stripe       | `stripe_publishable_key`, `stripe_secret_key`, `stripe_environment`                                                   |
| Razorpay     | `razorpay_environment`, `razorpay_api_key`, `razorpay_secret_key`                                                     |
| Paystack     | `paystack_environment`, `paystack_public_key`, `paystack_secret_key`                                                  |
| Khalti       | `khalti_pay_environment`, `khalti_api_key`, `khalti_secret_key`                                                       |
| CashFree     | `cash_free_environment`, `cash_free_app_id`, `cash_free_secret_key`                                                   |
| FlutterWave  | `flutter_wave_environment`, `flutter_wave_public_key`, `flutter_wave_secret_key`, `flutter_wave_encryption_key`       |
| Paymob       | `paymob_environment`, `paymob_api_key`, `paymob_secret_key`, `paymob_iframe_id`                                       |
| Braintree    | `braintree_tree_environment`, `braintree_tree_merchant_id`, `braintree_tree_public_key`, `braintree_tree_private_key` |
| QI Card (IQ) | `api/v1/payment/qicard/create-payment`                                                                                |

## 7.3 QI Card Payment (IQ-specific gateway)

```
POST api/v1/payment/qicard/create-payment
Auth: Bearer Token
Content-Type: application/json
```

**Body:**


| Field        | Type   | Description                           |
| ------------ | ------ | ------------------------------------- |
| `amount`     | double | Amount to charge                      |
| `user_id`    | string | User ID                               |
| `request_id` | string | Trip/request ID (optional for wallet) |

**Response:**

```json
{
  "success": true,
  "data": {
    "payment_url": "https://...",        // Open in WebView
    "payment_id": "pay-123",
    "response_details": { ... }
  }
}
```

## 7.4 Stripe Setup Intent

```
POST api/v1/payment/stripe/create-setup-intent
Auth: Bearer Token
```

**Response:**

```json
{
  "success": true,
  "data": {
    "setup_intent": "seti_xxx",
    "ephemeral_key": "ek_xxx",
    "customer": "cus_xxx",
    "publishable_key": "pk_xxx"
  }
}
```

## 7.5 Save Stripe Card

```
POST api/v1/payment/stripe/save-card
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field               | Type   |
| ------------------- | ------ |
| `setup_intent`      | string |
| `payment_method_id` | string |

## 7.6 Saved Cards List

```
GET api/v1/payment/cards/list
Auth: Bearer Token
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "card_id": "pm_xxx",
      "last_number": "4242",
      "card_type": "visa",
      "valid_through": "12/28",
      "is_default": 1
    }
  ]
}
```

## 7.7 Delete Saved Card

```
POST api/v1/payment/cards/delete/{cardId}
Auth: Bearer Token
```

## 7.8 Trip Payment Flow (Firebase + API)

### Cash Payment Flow:

1. Trip ends → Invoice shown to both
2. Driver confirms cash received → `POST api/v1/request/payment-confirm`
3. Firebase update: `is_payment_received: true`
4. User sees payment confirmed → Review screen

### Online/Card Payment Flow:

1. Trip ends → Invoice shown
2. User initiates payment via WebView or Stripe
3. Firebase update: `is_paid: 1`, `is_user_paid: true`
4. Driver sees payment confirmed → Review screen

### Wallet Payment Flow:

1. Trip ends → Auto-deducted from wallet
2. Both proceed to review screen

---

# 8. Firebase Realtime Database

## 8.1 Complete Path Map


| Path                                 | Purpose                    | Written By    | Read By                       |
| ------------------------------------ | -------------------------- | ------------- | ----------------------------- |
| `/call_FB_OTP`                       | Firebase OTP flag          | Server        | Both apps                     |
| `/drivers/driver_{id}`               | Driver location & status   | Driver        | User (geo-query), Driver      |
| `/owners/owner_{id}`                 | Fleet owner approval       | Driver/Server | Driver                        |
| `/request-meta`                      | Ride dispatch metadata     | Server        | Driver (query by`driver_id`)  |
| `/request-meta/{id}`                 | Single request dispatch    | Server        | User (child removed listener) |
| `/bid-meta/{id}`                     | Bidding ride data          | Both apps     | Both apps                     |
| `/bid-meta/{id}/drivers/driver_{id}` | Individual driver bid      | Driver        | User                          |
| `/requests/{id}`                     | Active ride real-time data | Both apps     | Both apps                     |
| `/SOS/{requestId}`                   | Emergency alert            | Both apps     | Server/Admin                  |
| `/conversation/{chatId}`             | Admin chat messages        | Server        | Both apps                     |
| `/peak-zones`                        | Peak demand zones          | Server        | Driver                        |

## 8.2 Driver Location Node Structure

```json
// Path: /drivers/driver_{id}
{
  "bearing": 0,
  "date": "2026-02-11 10:00:00",
  "id": "driver_123",
  "g": "sv8gh1",                          // Geohash for geo-query
  "is_active": 1,                          // 0 or 1
  "is_available": true,                    // true/false
  "profile_picture": "https://...",
  "rating": "4.5",
  "l": { "0": 33.312, "1": 44.366 },     // Latitude/Longitude
  "mobile": "+964...",
  "name": "Driver Name",
  "vehicle_type_icon": "car",             // car/bike/auto/truck/etc.
  "vehicle_type_name": "Sedan",
  "vehicle_number": "ABC 123",
  "vehicle_types": ["type_id_1"],
  "updated_at": 1707600000000,            // ServerValue.timestamp
  "ownerid": "owner_id",
  "service_location_id": "loc_id",
  "transport_type": "taxi",               // taxi/delivery/both
  "preferences": [...],
  "approve": 1,                            // 0 or 1
  "total_rides_taken": "450",
  "total_kms": "5000",
  "total_active_hrs": "200"
}
```

## 8.3 Active Ride Node Structure

```json
// Path: /requests/{requestId}
{
  "trip_arrived": "1",
  "trip_start": "1",
  "cancelled_by_user": false,
  "cancelled_by_driver": false,
  "is_cancelled": false,
  "modified_by_driver": 1707600000000,    // ServerValue.timestamp
  "modified_by_user": 1707600000000,
  "is_accept": true,
  "message_by_driver": 5,                 // Chat message count
  "message_by_user": 3,
  "trip_distance": 12.5,
  "driver_id": 123,
  "lat": 33.312,                          // Driver current lat
  "lng": 44.366,                          // Driver current lng
  "name": "Driver Name",
  "profile_picture": "https://...",
  "rating": "4.5",
  "lat_lng_array": [                      // Trip path recording
    {"lat": 33.31, "lng": 44.36}
  ],
  "request_id": "req-123",
  "vehicle_type_icon": "car",
  "transport_type": "taxi",
  "waiting_time_before_start": 120,       // Seconds
  "waiting_time_after_start": 60,
  "is_paid": 1,
  "is_user_paid": true,
  "is_payment_received": true,
  "payment_method": "1",                  // 1=cash, 2=wallet, 0=card, 3=online
  "driver_tips": "500",
  "polyline": "encoded_polyline_string",
  "distance": 5000.0,                     // Meters
  "duration": 15.0,                       // Minutes
  "pickup_distance": 2000.0,
  "pickup_duration": 8.0,
  "destination_change": 1707600000000,
  "additional_charges_reason": "toll",
  "additional_charges_amount": "1000"
}
```

## 8.4 Geo-Query for Nearby Vehicles

User app finds nearby vehicles using geohash-based range query:

```dart
FirebaseDatabase.instance
  .ref('drivers')
  .orderByChild('g')
  .startAt(lowerGeoHash)
  .endAt(upperGeoHash + '\uf8ff')
  .onValue
```

The geohash is calculated from user's current location with configurable precision.

## 8.5 SOS Alert Structure

```json
// Path: /SOS/{requestId}
{
  "is_driver": "0",     // "0" or "1"
  "is_user": "1",       // "0" or "1"
  "req_id": "req-123",
  "serv_loc_id": "loc-1",
  "updated_at": 1707600000000
}
```

## 8.6 Peak Zone Structure

```json
// Path: /peak-zones/{zoneId}
{
  "name": "Baghdad Central",
  "active": "1",
  "end_time_timestamp": 1707600000000,
  "coordinates": [
    { "latitude": 33.31, "longitude": 44.36 },
    { "latitude": 33.32, "longitude": 44.37 },
    { "latitude": 33.33, "longitude": 44.38 }
  ]
}
```

---

# 9. Push Notifications

## 9.1 Configuration

```
Firebase Project ID: iq-taxi-5cc3f
Messaging Sender ID: 871702027202
Android API Key: AIzaSyCbuNsXQZ7ArEmdrgA3UmK-ur-IxI4bhGM
iOS API Key: AIzaSyA9S2YO8Yth4Nh2R__m9u0BpCPWWgZFbaw
```

## 9.2 Notification Types


| push_type   | Behavior                                                     |
| ----------- | ------------------------------------------------------------ |
| `general`   | Shows local notification with title, message, optional image |
| Other types | Shows ride notification (triggers ride-related UI updates)   |

## 9.3 Notification Data Payload

```json
{
  "push_type": "general",
  "title": "Notification Title",
  "message": "Notification body text",
  "image": "https://..."            // Optional image URL
}
```

## 9.4 Audio Assets


| Audio        | Path                           | Usage                 |
| ------------ | ------------------------------ | --------------------- |
| Notification | `audio/notification_sound.mp3` | General notifications |
| Request      | `audio/request_sound.mp3`      | New ride requests     |
| Beep         | `audio/beep.mp3`               | Alert sounds          |

---

# 10. Account & Profile APIs

## 10.1 Update User Profile

```
User:   POST api/v1/user/profile
Driver: POST api/v1/user/driver-profile
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field             | Type   | Description                  |
| ----------------- | ------ | ---------------------------- |
| `name`            | string | Display name                 |
| `email`           | string | Email address                |
| `gender`          | string | "male" / "female" / "others" |
| `profile_picture` | File   | Profile image (optional)     |

## 10.2 Favorite Locations (User App)

### Add Favorite

```
POST api/v1/user/add-favourite-location
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field          | Type   | Description                   |
| -------------- | ------ | ----------------------------- |
| `pick_lat`     | double | Location latitude             |
| `pick_lng`     | double | Location longitude            |
| `address`      | string | Full address text             |
| `address_name` | string | "Home" / "Work" / custom name |

### Remove Favorite

```
POST api/v1/user/delete-favourite-location
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field | Type |
| ----- | ---- |
| `id`  | int  |

## 10.3 Notifications

### Get Notifications

```
GET api/v1/notifications/get-notification
Auth: Bearer Token
```

**Query Params:**


| Field  | Type |
| ------ | ---- |
| `page` | int  |

**Response:**

```json
{
  "success": true,
  "data": {
    "data": [
      {
        "id": 1,
        "title": "...",
        "body": "...",
        "image": "https://...",
        "created_at": "2026-02-11T10:00:00Z"
      }
    ],
    "meta": {
      "current_page": 1,
      "last_page": 5,
      "total": 50
    }
  }
}
```

### Delete Notification

```
GET api/v1/notifications/delete-notification/{notificationId}
Auth: Bearer Token
```

### Clear All Notifications

```
GET api/v1/notifications/delete-all-notification
Auth: Bearer Token
```

## 10.4 History

```
GET api/v1/request/history
Auth: Bearer Token
```

**Query Params:**


| Field  | Type   | Values                                     |
| ------ | ------ | ------------------------------------------ |
| `page` | int    | Page number                                |
| `type` | string | "is_completed", "is_cancelled", "is_later" |

**Response:** Array of `HistoryData` objects with full trip details, driver info, fare breakdown, stops, polylines.

## 10.5 Download Invoice

```
GET api/v1/request/invoice/{requestId}
Auth: Bearer Token
```

**Response:** PDF file / downloadable invoice

## 10.6 Logout

```
POST api/v1/logout
Auth: Bearer Token
```

## 10.7 Delete Account

```
POST api/v1/user/delete-user-account
Auth: Bearer Token
```

**Note:** Account enters 30-day deletion window. Can be restored within 24 hours by logging back in.

## 10.8 SOS Contacts

### Add SOS Contact

```
POST api/v1/common/sos/store
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field    | Type   |
| -------- | ------ |
| `name`   | string |
| `number` | string |

**Max 4 user SOS contacts.**

### Delete SOS Contact

```
POST api/v1/common/sos/delete/{contactId}
Auth: Bearer Token
```

## 10.9 FAQ

```
GET api/v1/common/faq/list
Auth: Bearer Token
```

**Query Params (Driver only):**


| Field | Type   |
| ----- | ------ |
| `lat` | double |
| `lng` | double |

## 10.10 Terms & Privacy

```
GET api/v1/common/mobile/{type}
Auth: Bearer Token
```

**Types:** `"privacy"`, `"terms"`
**Response:** HTML string content

## 10.11 Update Language

```
POST api/v1/user/update-my-lang
Auth: Bearer Token
Content-Type: application/json
```

**Body:**

```json
{ "lang": "ar" }
```

---

# 11. Wallet APIs

## 11.1 Wallet History

```
GET api/v1/payment/wallet/history
Auth: Bearer Token
```

**Query Params:**


| Field  | Type |
| ------ | ---- |
| `page` | int  |

**Response:**

```json
{
  "success": true,
  "data": {
    "wallet_balance": 50000.0,
    "currency_code": "IQD",
    "currency_symbol": "د.ع",
    "enable_save_card": true,
    "minimum_amount_added_to_wallet": 5000,
  
    "stripe": true,
    "stripe_publishable_key": "pk_xxx",
  
    "payment_gateways": [
      {
        "id": 1,
        "name": "Qi Card",
        "image": "https://...",
        "url": "https://..."
      }
    ],
  
    "wallet_history": {
      "data": [
        {
          "id": 1,
          "type": "credit",           // "credit" | "debit"
          "amount": 10000,
          "remarks": "Wallet top-up",
          "created_at": "2026-02-11T10:00:00Z"
        }
      ],
      "meta": {
        "current_page": 1,
        "last_page": 3
      }
    }
  }
}
```

## 11.2 Add Money to Wallet (Stripe)

```
POST api/v1/payment/stripe/add-money-to-wallet
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field     | Type   |
| --------- | ------ |
| `amount`  | double |
| `card_id` | string |

## 11.3 Transfer Money

```
POST api/v1/payment/wallet/transfer-money-from-wallet
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field          | Type   | Description            |
| -------------- | ------ | ---------------------- |
| `amount`       | double | Transfer amount        |
| `mobile`       | string | Recipient phone number |
| `role`         | string | "user" or "driver"     |
| `country_code` | string | Country dial code      |

---

# 12. Driver-Specific APIs

## 12.1 Online/Offline Toggle

```
POST api/v1/driver/online-offline
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field       | Type   | Description             |
| ----------- | ------ | ----------------------- |
| `is_active` | int    | 1 = online, 0 = offline |
| `lat`       | double | Current latitude        |
| `lng`       | double | Current longitude       |

## 12.2 Create Instant Ride (Driver creates ride for user)

```
POST api/v1/request/create-instant-ride
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field            | Type   |
| ---------------- | ------ |
| `pick_lat`       | double |
| `pick_lng`       | double |
| `drop_lat`       | double |
| `drop_lng`       | double |
| `pick_address`   | string |
| `drop_address`   | string |
| `vehicle_type`   | int    |
| `user_name`      | string |
| `user_mobile`    | string |
| `ride_type`      | int    |
| `transport_type` | string |
| `polyline`       | string |

## 12.3 Create Delivery Instant Ride

```
POST api/v1/request/create-delivery-instant-ride
Auth: Bearer Token
Content-Type: multipart/form-data
```

Additional fields: `goods_type_id`, `goods_type_quantity`

## 12.4 Earnings

### Overall Earnings

```
GET api/v1/driver/new-earnings
Auth: Bearer Token
```

### Daily Earnings

```
POST api/v1/driver/earnings-by-date
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field  | Type                |
| ------ | ------------------- |
| `date` | string (YYYY-MM-DD) |

### Earnings Report

```
GET api/v1/driver/earnings-report/{fromDate}/{toDate}
Auth: Bearer Token
```

## 12.5 Subscription Plans

### List Plans

```
GET api/v1/driver/list_of_plans
Auth: Bearer Token
```

### Subscribe

```
POST api/v1/driver/subscribe
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field         | Type   |
| ------------- | ------ |
| `plan_id`     | int    |
| `payment_opt` | string |

## 12.6 Incentives

### Today's Incentives

```
GET /api/v1/driver/new-incentives
Auth: Bearer Token
```

### Weekly Incentives

```
GET /api/v1/driver/week-incentives
Auth: Bearer Token
```

## 12.7 Rewards & Loyalty

### Driver Level History

```
GET /api/v1/driver/loyalty/history
Auth: Bearer Token
```

### Driver Rewards History

```
GET /api/v1/driver/rewards/history
Auth: Bearer Token
```

### Redeem Points to Wallet

```
POST /api/v1/payment/wallet/convert-point-to-wallet
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field    | Type   |
| -------- | ------ |
| `amount` | double |

## 12.8 Leaderboard

### By Earnings

```
GET api/v1/driver/leader-board/earnings
Auth: Bearer Token
```

### By Trips

```
GET api/v1/driver/leader-board/trips
Auth: Bearer Token
```

## 12.9 Bank Information

### Get Bank Info

```
GET api/v1/driver/list/bankinfo
Auth: Bearer Token
```

### Update Bank Info

```
POST api/v1/driver/update/bankinfo
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field            | Type   |
| ---------------- | ------ |
| `account_name`   | string |
| `account_number` | string |
| `bank_name`      | string |
| `ifsc_code`      | string |
| `upi_id`         | string |

## 12.10 Withdrawal

### Get Withdrawal History

```
GET api/v1/payment/wallet/withdrawal-requests
Auth: Bearer Token
```

### Request Withdrawal

```
POST api/v1/payment/wallet/request-for-withdrawal
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field    | Type   |
| -------- | ------ |
| `amount` | double |

## 12.11 Driver Profile / Vehicle Registration

### Get Vehicle Types

```
GET api/v1/types/service?transport_type={type}
Auth: Bearer Token
```

### Get Vehicle Makes

```
GET api/v1/common/car/makes?transport_type={type}&vehicle_type={iconFor}
Auth: Bearer Token
```

### Get Vehicle Models

```
GET api/v1/common/car/models/{makeId}
Auth: Bearer Token
```

### Update Vehicle Info

```
POST api/v1/user/driver-profile
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field                 | Type   |
| --------------------- | ------ |
| `service_location_id` | string |
| `is_company_driver`   | bool   |
| `vehicle_type`        | int    |
| `custom_make`         | string |
| `custom_model`        | string |
| `car_color`           | string |
| `car_number`          | string |
| `vehicle_year`        | string |
| `transport_type`      | string |

### Get Needed Documents

```
GET api/v1/driver/documents/needed
Auth: Bearer Token
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "Driving License",
      "doc_type": "image",
      "has_id_number": true,
      "has_expiry_date": true,
      "id_key": "license_number",
      "is_uploaded": false,
      "is_editable": true,
      "document_status": 0,
      "is_front_and_back": true,
      "status_string": "Not uploaded",
      "is_required": true,
      "document": null
    }
  ],
  "enable_submit_button": false
}
```

### Upload Document

```
POST api/v1/driver/upload/documents
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field             | Type   | Description                 |
| ----------------- | ------ | --------------------------- |
| `document_id`     | int    | Document type ID            |
| `document`        | File   | Front image                 |
| `back_image`      | File   | Back image (if required)    |
| `identify_number` | string | ID number (if required)     |
| `expiry_date`     | string | Expiry date (if required)   |
| `fleet_id`        | string | Fleet vehicle ID (if fleet) |

## 12.12 Sub-Vehicle Types

```
GET api/v1/types/sub-vehicle
Auth: Bearer Token
```

## 12.13 Update Price Per Distance

```
POST api/v1/driver/update-price
Auth: Bearer Token
```

## 12.14 Diagnostic Notification

```
GET api/v1/driver/diagnostic
Auth: Bearer Token
```

## 12.15 My Route Booking

### Update Route Address

```
POST api/v1/driver/add-my-route-address
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field          | Type   |
| -------------- | ------ |
| `pick_lat`     | double |
| `pick_lng`     | double |
| `drop_lat`     | double |
| `drop_lng`     | double |
| `pick_address` | string |
| `drop_address` | string |

### Enable/Disable Route Booking

```
POST api/v1/driver/enable-my-route-booking
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field    | Type |
| -------- | ---- |
| `enable` | int  |

## 12.16 Preferences

### Get Preferences

```
GET api/v1/common/preferences
Auth: Bearer Token
```

### Update Preferences

```
POST api/v1/common/preferences/store
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field         | Type                         |
| ------------- | ---------------------------- |
| `preferences` | JSON array of preference IDs |

## 12.17 Outstation Ready to Pickup

```
POST api/v1/request/ready-to-pickup
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field        | Type   |
| ------------ | ------ |
| `request_id` | string |

## 12.18 Goods Types (Delivery)

```
GET api/v1/common/goods-types
Auth: Bearer Token
```

**Response:**

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "goods_type_name": "Fragile",
      "goods_type": "fragile",
      "company_key": "company_1",
      "active": 1
    }
  ]
}
```

---

# 13. Owner/Fleet APIs

## 13.1 Owner Registration

```
POST api/v1/owner/register
Auth: Not required
Content-Type: multipart/form-data
```

**Body:** Same as driver registration

## 13.2 Owner Dashboard

```
POST api/v1/owner/dashboard
Auth: Bearer Token
```

## 13.3 Fleet Dashboard

```
POST api/v1/owner/fleet-dashboard
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field      | Type   |
| ---------- | ------ |
| `fleet_id` | string |

## 13.4 Driver Performance

```
POST api/v1/owner/fleet-driver-dashboard
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field       | Type   |
| ----------- | ------ |
| `driver_id` | string |

## 13.5 Manage Fleet Drivers

### List Drivers

```
GET api/v1/owner/list-drivers
Auth: Bearer Token
```

### Add Driver

```
POST api/v1/owner/add-drivers
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field    | Type   |
| -------- | ------ |
| `name`   | string |
| `mobile` | string |
| `email`  | string |

### Delete Driver

```
GET api/v1/owner/delete-driver/{driverId}
Auth: Bearer Token
```

## 13.6 Manage Fleet Vehicles

### List Vehicles

```
GET api/v1/owner/list-fleets
Auth: Bearer Token
```

### Add Vehicle

```
POST api/v1/owner/add-fleet
Auth: Bearer Token
Content-Type: multipart/form-data
```

### Assign Driver to Vehicle

```
POST api/v1/owner/assign-driver/{fleetId}
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field       | Type   |
| ----------- | ------ |
| `driver_id` | string |

### Fleet Document Needed

```
GET api/v1/owner/fleet/documents/needed?fleet_id={fleetId}
Auth: Bearer Token
```

---

# 14. Support & Complaints APIs

## 14.1 Complaint Titles

```
GET api/v1/common/complaint-titles
Auth: Bearer Token
```

**Response:**

```json
{
  "success": true,
  "data": [
    { "id": 1, "title": "Driver behavior" },
    { "id": 2, "title": "Pricing issue" }
  ]
}
```

## 14.2 Submit Complaint

```
POST api/v1/common/make-complaint
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field                | Type   | Description                 |
| -------------------- | ------ | --------------------------- |
| `complaint_title_id` | int    | Selected complaint category |
| `description`        | string | Min 10 characters           |
| `request_id`         | string | Related trip ID             |

## 14.3 Support Ticket Titles

```
GET api/v1/common/ticket-titles
Auth: Bearer Token
```

## 14.4 Create Support Ticket

```
POST api/v1/common/make-ticket
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field           | Type   | Description             |
| --------------- | ------ | ----------------------- |
| `title_id`      | int    | Ticket title category   |
| `description`   | string | Issue description       |
| `support_type`  | string | Support category        |
| `attachments[]` | File[] | Images, PDFs, DOC files |

**Accepted file types:** `png`, `jpg`, `jpeg`, `pdf`, `doc`

## 14.5 List Support Tickets

```
GET api/v1/common/list
Auth: Bearer Token
```

## 14.6 View Support Ticket

```
GET api/v1/common/view-ticket/{ticketId}
Auth: Bearer Token
```

**Response includes:**

- Ticket details (ID, title, description, status, support type)
- Assigned admin info
- User info
- Attachments list
- Reply messages with timestamps

**Ticket Status Values:**


| Code | Meaning      |
| ---- | ------------ |
| 0    | Pending      |
| 1    | Acknowledged |
| 2    | In Progress  |
| 3    | Closed       |

## 14.7 Reply to Ticket

```
POST api/v1/common/reply-message/{ticketId}
Auth: Bearer Token
Content-Type: multipart/form-data
```

**Body:**


| Field     | Type   |
| --------- | ------ |
| `message` | string |

**Note:** Replies are disabled when ticket status is 3 (Closed).

---

# 15. Data Models Reference

## 15.1 Fare Breakdown Structure (RequestBill)

```json
{
  "base_price": 2500,
  "base_distance": 2,
  "price_per_distance": 500,
  "distance_price": 2500,
  "price_per_time": 100,
  "time_price": 1500,
  "waiting_charge": 500,
  "waiting_charge_per_min": 50,
  "free_waiting_time_in_mins_before_trip_start": 5,
  "free_waiting_time_in_mins_after_trip_start": 3,
  "admin_commision": 1000,
  "driver_commision": 5500,
  "service_tax": 200,
  "service_tax_percentage": 5,
  "promo_discount": 500,
  "total_amount": 7500,
  "requested_currency_code": "IQD",
  "requested_currency_symbol": "د.ع",
  "cancellation_fee": 0,
  "airport_surge_fee": 0,
  "driver_tips": 500,
  "additional_charges": 0,
  "additional_charges_reason": null,
  "preference_price_total": 500
}
```

## 15.2 Ride Types


| ride_type  | Name       | Description                                     |
| ---------- | ---------- | ----------------------------------------------- |
| 1          | Regular    | Normal on-demand ride                           |
| 2          | Ride Later | Scheduled ride                                  |
| Outstation | Outstation | Long-distance ride (`is_outstation: 1`)         |
| Rental     | Rental     | Hourly/package-based rental                     |
| Delivery   | Delivery   | Package delivery (`transport_type: "delivery"`) |

## 15.3 Vehicle Type Icons


| Icon Key    | Vehicle Type                   |
| ----------- | ------------------------------ |
| `car`       | Sedan/Car                      |
| `bike`      | Motorcycle                     |
| `auto`      | Auto-rickshaw                  |
| `truck`     | Truck                          |
| `suv`       | SUV                            |
| `luxury`    | Luxury                         |
| `premium`   | Premium                        |
| `hatchback` | Hatchback                      |
| `lcv`       | Light Commercial Vehicle       |
| `mcv`       | Medium Commercial Vehicle      |
| `hcv`       | Heavy Commercial Vehicle       |
| `ehcv`      | Extra Heavy Commercial Vehicle |

## 15.4 Transport Types


| Value      | Description            |
| ---------- | ---------------------- |
| `taxi`     | Passenger taxi service |
| `delivery` | Package/goods delivery |
| `both`     | Both taxi and delivery |

## 15.5 Payment Type Codes


| Code | Name   | Description              |
| ---- | ------ | ------------------------ |
| `1`  | Cash   | Cash payment             |
| `2`  | Wallet | In-app wallet            |
| `0`  | Card   | Saved card (Stripe)      |
| `3`  | Online | External payment gateway |

## 15.6 Dispatch Types


| Type      | Description                       |
| --------- | --------------------------------- |
| `normal`  | Auto-dispatch to nearest driver   |
| `bidding` | Bidding-only rides                |
| `both`    | User can choose normal or bidding |

---

# 16. App Navigation Flow

## 16.1 User App Flow

```
LoaderPage (Splash)
  ├── No language selected → ChooseLanguagePage
  │     └── Select language → LandingPage (Onboarding)
  │           └── Complete/Skip → AuthPage (Login/Register)
  │                 ├── Enter phone → VerifyPage (OTP)
  │                 │     └── Verify OTP → HomePage
  │                 └── New user → RegisterPage → VerifyPage → ReferralPage → HomePage
  │
  ├── Not logged in + has language → AuthPage
  └── Logged in → HomePage
       ├── DestinationPage (Search addresses)
       │     └── ConfirmLocationPage (Pin on map)
       ├── BookingPage (Vehicle selection → Trip)
       │     ├── InvoicePage (Fare summary)
       │     └── ReviewPage (Rating)
       ├── AccountDrawer
       │     ├── ProfilePage → EditProfilePage
       │     ├── HistoryPage → TripSummaryPage
       │     ├── WalletPage → AddMoneyPage / TransferPage
       │     ├── NotificationPage
       │     ├── ComplaintPage → ComplaintDetailPage
       │     ├── SOSPage → SelectContactPage
       │     ├── FavouritePage → ConfirmFavLocationPage
       │     ├── AdminChatPage
       │     ├── SupportTicketPage → ViewTicketPage
       │     ├── ReferralPage
       │     └── SettingsPage → FAQPage / TermsPage
       └── OnGoingRidesPage
```

## 16.2 Driver App Flow

```
LoaderPage (Splash + Location Permission)
  ├── No language → ChooseLanguagePage
  │     └── Select → LoaderPage → LandingPage
  │           └── Skip → AuthPage (Login/Register)
  │                 ├── Phone → VerifyPage (OTP)
  │                 │     ├── Has service location → HomePage
  │                 │     └── No service location → DriverProfilePage
  │                 └── New → Register → Verify → Referral → DriverProfilePage
  │
  ├── Not logged in → AuthPage
  └── Logged in → HomePage
       ├── Map View (Online/Offline toggle)
       ├── Incoming Ride (Accept/Reject overlay)
       ├── On-Ride View (Navigate, Chat, SOS, Additional charges)
       │     ├── Arrive → Start → End → InvoicePage → ReviewPage
       │     ├── ChatPage (with user)
       │     ├── CancelReasonPage
       │     └── OTPEntryWidget / SignatureWidget / ProofWidget
       ├── Bidding View (List of available bids)
       │     └── BiddingRequestWidget (Accept/Counter-offer)
       ├── Outstation View (Upcoming outstation rides)
       │     └── OutstationRequestWidget (Accept/Counter-offer)
       ├── InstantRide (Create ride for user)
       ├── DiagnosticPage (System checks)
       ├── AccountDrawer
       │     ├── ProfilePage → EditProfilePage
       │     ├── VehicleInfoPage → DriverProfilePage
       │     ├── HistoryPage → TripSummaryPage
       │     ├── EarningsPage (Daily/Weekly stats)
       │     ├── WalletPage → WithdrawPage / TransferPage
       │     ├── NotificationPage
       │     ├── SubscriptionPage
       │     ├── IncentivePage
       │     ├── RewardsPage / LevelsPage
       │     ├── LeaderboardPage
       │     ├── BankInfoPage
       │     ├── SOSPage
       │     ├── ComplaintPage
       │     ├── AdminChatPage
       │     ├── SupportTicketPage
       │     ├── ReferralPage
       │     ├── ReportsPage
       │     ├── RouteBookingPage
       │     ├── CompanyInfoPage (Owner)
       │     ├── DashboardPage (Owner)
       │     ├── FleetDriversPage (Owner)
       │     ├── VehiclesPage (Owner)
       │     └── SettingsPage
       └── QuickActions (Instant ride, Help, Diagnostics, Preferences)
```

---

# 17. Shared Preferences Keys


| Key                | Type   | Description                                     |
| ------------------ | ------ | ----------------------------------------------- |
| `choosenLanguage`  | String | Selected language code (e.g., "ar")             |
| `direction`        | String | Text direction ("ltr" / "rtl")                  |
| `token`            | String | Auth Bearer token                               |
| `login`            | Bool   | Login status                                    |
| `landing`          | Bool   | Onboarding completed                            |
| `recentPlaces`     | String | JSON cached recent searches                     |
| `mapType`          | String | Map provider ("google_map" / "open_street_map") |
| `signInKey`        | String | Sign-in key                                     |
| `packageName`      | String | App package name                                |
| `dark`             | Bool   | Dark theme enabled                              |
| `userType`         | String | Driver app: "driver" / "owner"                  |
| `userId`           | String | User/Driver ID                                  |
| `skipSubscription` | Bool   | Driver: skipped subscription                    |

---

# 18. Constants & Configuration

## 18.1 User App Constants

```dart
App Name: "IQ Taxi"
Base URL: "https://iqttaxi.com/"
Package Name: "com.elnooronline.taxi.user"
Google Maps Key: "AIzaSyAhbj8Bq2YKX0PQsb_0LmVtSGO6Q6NayDE"
Primary Color: #FFB700 (Golden Yellow)
Secondary Color: #051f17 (Dark Green)
Default Language: Arabic (ar)
Default Direction: RTL
Supported Languages: Arabic, English
Fonts: Cairo (Google Fonts)
```

## 18.2 Driver App Constants

```dart
App Name: "IQ Taxi"
Base URL: "https://iqttaxi.com/"
Package Name: "com.elnooronline.taxi.driver"
Google Maps Key: Same as user
Primary Color: #FFB700
Secondary Color: #051f17
Default Language: Arabic (ar)
Fonts: Cairo (Google Fonts)
```

## 18.3 Firebase Configuration

```
Project ID: iq-taxi-5cc3f
Messaging Sender ID: 871702027202

Android:
  App ID: 1:871702027202:android:91cb7726d4d634b96f945b (Driver)
  API Key: AIzaSyCbuNsXQZ7ArEmdrgA3UmK-ur-IxI4bhGM

iOS:
  App ID: 1:871702027202:ios:c5899106a893eba66f945b (Driver)
  API Key: AIzaSyA9S2YO8Yth4Nh2R__m9u0BpCPWWgZFbaw
```

## 18.4 Driver Location Streaming Config

```
Distance Filter: 50 meters (minimum movement to trigger update)
Interval: 10 seconds
Accuracy: High
Firebase Update: Writes to /drivers/driver_{id}/l with geohash
Background Service: 10-minute interval location updates
```

## 18.5 Vehicle Marker Animation

```
Interpolation Steps: 15 points between positions
Max Jump Distance: 500 meters (adds intermediate points for larger jumps)
Rotation: Calculated from bearing between consecutive points
```

## 18.6 Theme Colors


| Color     | Hex       | Usage                           |
| --------- | --------- | ------------------------------- |
| Primary   | `#FFB700` | Buttons, headers, accents       |
| Secondary | `#051F17` | Dark backgrounds                |
| Green     | `#0BC333` | Online status, pickup indicator |
| Red       | `#FB270B` | Error, cancel, drop indicator   |
| Grey      | `#DAD4D4` | Backgrounds, borders            |
| Black     | `#000000` | Text                            |
| White     | `#FFFFFF` | Backgrounds, text on primary    |

---

# End of Documentation

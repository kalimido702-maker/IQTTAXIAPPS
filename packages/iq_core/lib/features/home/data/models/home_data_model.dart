import 'package:equatable/equatable.dart';

/// Banner image from API response.
class BannerModel extends Equatable {
  final int id;
  final String image;
  final String? redirectLink;

  const BannerModel({
    required this.id,
    required this.image,
    this.redirectLink,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      image: (json['image'] ?? '').toString(),
      redirectLink: json['redirect_link'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, image, redirectLink];
}

/// Favourite location (home / work / other).
class FavouriteLocationModel extends Equatable {
  final int id;
  final String address;
  final double lat;
  final double lng;

  /// Category: `"home"`, `"work"`, or custom name.
  final String addressName;

  const FavouriteLocationModel({
    required this.id,
    required this.address,
    required this.lat,
    required this.lng,
    this.addressName = '',
  });

  factory FavouriteLocationModel.fromJson(Map<String, dynamic> json) {
    return FavouriteLocationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      // The list‐favourite‐location API returns `pick_address`;
      // the home API returns `address`. Accept both.
      address:
          (json['pick_address'] ?? json['address'] ?? '').toString(),
      lat: (json['pick_lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['pick_lng'] as num?)?.toDouble() ?? 0.0,
      addressName: (json['address_name'] ?? '').toString(),
    );
  }

  @override
  List<Object?> get props => [id, address, lat, lng, addressName];
}

/// Wallet balance info.
class WalletModel extends Equatable {
  final double balance;
  final String currencyCode;
  final String currencySymbol;

  const WalletModel({
    this.balance = 0.0,
    this.currencyCode = 'IQD',
    this.currencySymbol = 'د.ع',
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      balance: (json['amount_balance'] as num?)?.toDouble() ?? 0.0,
      currencyCode: (json['currency_code'] ?? 'IQD').toString(),
      currencySymbol: (json['currency_symbol'] ?? 'د.ع').toString(),
    );
  }

  @override
  List<Object?> get props => [balance, currencyCode, currencySymbol];
}

/// Unified home data model parsed from `GET api/v1/user`.
///
/// Used by **both** passenger and driver home pages.
class HomeDataModel extends Equatable {
  // ── User info ──
  final String id;
  final String name;
  final String? lastName;
  final String phone;
  final String? email;
  final String? avatarUrl;
  final String role;
  final double? rating;

  // ── Feature flags ──
  final String enableModules; // 'taxi', 'delivery', 'both'
  final bool enableBidding;
  final bool showOutstation;
  final bool showRental;

  // ── Currency ──
  final String currencyCode;
  final String currencySymbol;

  // ── UI data ──
  final int notifyCount;
  final WalletModel wallet;
  final List<BannerModel> banners;
  final List<FavouriteLocationModel> homeLocations;
  final List<FavouriteLocationModel> workLocations;
  final List<FavouriteLocationModel> otherLocations;

  // ── Referral ──
  final String? refferalCode;
  // ─── Support Chat ──
  final String? conversationId;
  // ── SOS contacts (from API 'sos.data') ──
  final List<SosContactModel> sosContacts;
  // ── Driver-only fields ──
  final bool? isAvailable;
  final String? vehicleTypeName;
  final String? carMake;
  final String? carModel;
  final String? carColor;
  final String? carNumber;
  final int totalEarnings;
  final int totalKms;
  final int totalMinutesOnline;
  final int totalRidesTaken;
  final bool? isApproved;

  const HomeDataModel({
    required this.id,
    required this.name,
    this.lastName,
    required this.phone,
    this.email,
    this.avatarUrl,
    required this.role,
    this.rating,
    this.enableModules = 'taxi',
    this.enableBidding = false,
    this.showOutstation = false,
    this.showRental = false,
    this.currencyCode = 'IQD',
    this.currencySymbol = 'د.ع',
    this.notifyCount = 0,
    this.wallet = const WalletModel(),
    this.banners = const [],
    this.homeLocations = const [],
    this.workLocations = const [],
    this.otherLocations = const [],
    this.refferalCode,
    this.conversationId,
    this.sosContacts = const [],
    this.isAvailable,
    this.vehicleTypeName,
    this.carMake,
    this.carModel,
    this.carColor,
    this.carNumber,
    this.totalEarnings = 0,
    this.totalKms = 0,
    this.totalMinutesOnline = 0,
    this.totalRidesTaken = 0,
    this.isApproved,
  });

  /// Parse from `GET api/v1/user` → `response.data['data']`.
  factory HomeDataModel.fromJson(Map<String, dynamic> json) {
    // ── Favourite locations ──
    final fav = json['favouriteLocations'] as Map<String, dynamic>? ?? {};
    List<FavouriteLocationModel> parseLocList(dynamic raw) {
      if (raw is List) {
        return raw
            .whereType<Map<String, dynamic>>()
            .map(FavouriteLocationModel.fromJson)
            .toList();
      }
      return [];
    }

    // ── SOS Contacts ──
    final sosRaw = json['sos'] as Map<String, dynamic>? ?? {};
    final sosList = sosRaw['data'] as List<dynamic>? ?? [];
    final sosContacts = sosList
        .whereType<Map<String, dynamic>>()
        .map(SosContactModel.fromJson)
        .toList();

    // ── Banners ──
    final bannerRaw = json['bannerImage'];
    final banners = bannerRaw is List
        ? bannerRaw
            .whereType<Map<String, dynamic>>()
            .map(BannerModel.fromJson)
            .toList()
        : <BannerModel>[];

    // ── Wallet ──
    final walletRaw = json['wallet'] as Map<String, dynamic>?;
    final wallet =
        walletRaw != null ? WalletModel.fromJson(walletRaw) : const WalletModel();

    // ── Driver availability ──
    // The backend uses 'active' for online/offline status (toggled via
    // POST api/v1/driver/online-offline). 'available' is a secondary
    // field that the server always keeps true.
    bool? available;
    if (json['active'] != null) {
      final v = json['active'];
      available = v == true || v == 1 || v.toString() == '1';
    } else if (json['available'] != null) {
      available = json['available'].toString() == '1';
    }

    return HomeDataModel(
      id: (json['id'] ?? json['uuid'] ?? '').toString(),
      name: (json['name'] ?? json['firstname'] ?? '').toString(),
      lastName: json['last_name'] as String?,
      phone: (json['mobile'] ?? json['phone'] ?? '').toString(),
      email: json['email'] as String?,
      avatarUrl: json['profile_picture'] as String?,
      role: (json['role'] ?? 'passenger').toString(),
      rating: (json['rating'] as num?)?.toDouble(),
      enableModules:
          (json['enable_modules_for_applications'] ?? 'taxi').toString(),
      enableBidding: json['enableBiddingRideType'] == true,
      showOutstation: json['show_outstation_ride_feature']?.toString() == '1' ||
          json['show_outstation_ride_feature'] == true,
      showRental: json['show_rental_ride'] == true,
      currencyCode: (json['currency_code'] ?? 'IQD').toString(),
      currencySymbol: (json['currency_symbol'] ?? 'د.ع').toString(),
      notifyCount: (json['notify_count'] as num?)?.toInt() ?? 0,
      wallet: wallet,
      banners: banners,
      homeLocations: parseLocList(fav['home']),
      workLocations: parseLocList(fav['work']),
      otherLocations: parseLocList(fav['others']),
      refferalCode: json['refferal_code'] as String?,
      conversationId: json['conversation_id']?.toString(),
      sosContacts: sosContacts,
      isAvailable: available,
      vehicleTypeName: json['vehicle_type_name'] as String?,
      carMake: json['car_make'] as String?,
      carModel: json['car_model'] as String?,
      carColor: json['car_color'] as String?,
      carNumber: json['car_number'] as String?,
      totalEarnings:
          int.tryParse(json['total_earnings']?.toString() ?? '0') ?? 0,
      totalKms: int.tryParse(json['total_kms']?.toString() ?? '0') ?? 0,
      totalMinutesOnline:
          int.tryParse(json['total_minutes_online']?.toString() ?? '0') ?? 0,
      totalRidesTaken:
          int.tryParse(json['total_rides_taken']?.toString() ?? '0') ?? 0,
      isApproved: json['approve'] == 1 || json['approve'] == true,
    );
  }

  /// All favourite locations merged into one flat list.
  List<FavouriteLocationModel> get allFavouriteLocations =>
      [...homeLocations, ...workLocations, ...otherLocations];

  /// Driver subtitle text: vehicle type + car make + car model.
  String get driverSubtitle {
    final parts = <String>[
      if (vehicleTypeName != null && vehicleTypeName!.isNotEmpty)
        vehicleTypeName!,
      if (carMake != null && carMake!.isNotEmpty) carMake!,
      if (carModel != null && carModel!.isNotEmpty) carModel!,
    ];
    return parts.isNotEmpty ? parts.join(' - ') : 'سائق';
  }

  /// Active hours derived from total minutes.
  int get activeHours => totalMinutesOnline ~/ 60;

  /// Active remaining minutes.
  int get activeMinutes => totalMinutesOnline % 60;

  /// First admin SOS phone number, if any.
  String? get adminSosPhone {
    for (final c in sosContacts) {
      if (c.userType == 'admin' && c.number.isNotEmpty) return c.number;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        id, name, phone, role, avatarUrl, rating,
        enableModules, banners, wallet,
        homeLocations, workLocations, otherLocations,
        isAvailable, totalEarnings, totalKms,
        totalMinutesOnline, totalRidesTaken,
        sosContacts,
      ];
}

/// SOS contact entry from `sos.data[]` in the home API response.
class SosContactModel extends Equatable {
  final int id;
  final String name;
  final String number;
  final String userType; // 'admin' or 'user'

  const SosContactModel({
    required this.id,
    required this.name,
    required this.number,
    required this.userType,
  });

  factory SosContactModel.fromJson(Map<String, dynamic> json) {
    return SosContactModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '').toString(),
      number: (json['number'] ?? '').toString(),
      userType: (json['user_type'] ?? 'user').toString(),
    );
  }

  @override
  List<Object?> get props => [id, name, number, userType];
}

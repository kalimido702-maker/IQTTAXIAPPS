import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import '../models/active_trip_model.dart';
import '../models/incoming_request_model.dart';

/// Firebase Realtime Database data source for real-time trip updates.
abstract class TripStreamDataSource {
  /// Listen to active trip state at `requests/{requestId}`.
  Stream<ActiveTripModel?> watchTrip(String requestId);

  /// Listen for incoming ride requests for a driver via `request-meta`.
  /// Uses query by `driver_id`.
  Stream<IncomingRequestModel?> watchIncomingRequests(String driverId);

  /// Update driver location in Firebase at `requests/{requestId}`.
  Future<void> updateDriverLocation({
    required String requestId,
    required double lat,
    required double lng,
    required double bearing,
  });

  /// Write chat message count to sync chat updates.
  Future<void> updateChatCount({
    required String requestId,
    required String field,
    required int count,
  });

  /// Update the `requests/{requestId}` node with arbitrary data.
  Future<void> updateTripNode({
    required String requestId,
    required Map<String, dynamic> data,
  });

  /// Remove trip listener (cleanup).
  void dispose();
}

/// Firebase RTDB implementation of [TripStreamDataSource].
///
/// Performance considerations:
/// - Uses `.onValue` for efficient single-node listening
/// - Does NOT create child listeners — fewer connections
/// - Disposes subscriptions properly to prevent memory leaks
class TripStreamDataSourceImpl implements TripStreamDataSource {
  TripStreamDataSourceImpl({FirebaseDatabase? database})
      : _explicitDb = database;

  final FirebaseDatabase? _explicitDb;

  bool get _isFirebaseReady => Firebase.apps.isNotEmpty;

  /// Lazily resolve [FirebaseDatabase] so that [Firebase.initializeApp]
  /// has time to run before the first access.
  FirebaseDatabase get _db => _explicitDb ?? FirebaseDatabase.instance;

  final Map<String, StreamSubscription> _subscriptions = {};

  @override
  Stream<ActiveTripModel?> watchTrip(String requestId) {
    if (!_isFirebaseReady) {
      return Stream<ActiveTripModel?>.empty();
    }
    return _db.ref('requests/$requestId').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null || data is! Map) return null;
      return ActiveTripModel.fromFirebase(requestId, data);
    });
  }

  @override
  Stream<IncomingRequestModel?> watchIncomingRequests(String driverId) {
    if (!_isFirebaseReady) {
      debugPrint('⚠️ watchIncomingRequests: Firebase NOT ready — returning empty stream');
      return Stream<IncomingRequestModel?>.empty();
    }

    final queryValue = int.tryParse(driverId) ?? driverId;
    debugPrint('🔥 watchIncomingRequests: listening for driver_id=$queryValue (type: ${queryValue.runtimeType})');

    return _db
        .ref('request-meta')
        .orderByChild('driver_id')
        .equalTo(queryValue)
        .onValue
        .map((event) {
      final data = event.snapshot.value;
      debugPrint('🔥 request-meta event: ${data == null ? "null" : data.runtimeType} — children: ${event.snapshot.children.length}');
      if (data == null || data is! Map) return null;

      final entries = data.entries.toList();
      if (entries.isEmpty) return null;

      final first = entries.first;
      final key = first.key.toString();
      final value = first.value;
      if (value is! Map) return null;

      return IncomingRequestModel.fromFirebase(key, value);
    });
  }

  @override
  Future<void> updateDriverLocation({
    required String requestId,
    required double lat,
    required double lng,
    required double bearing,
  }) async {
    if (!_isFirebaseReady) return;
    await _db.ref('requests/$requestId').update({
      'lat': lat,
      'lng': lng,
      'bearing': bearing,
      'updated_at': ServerValue.timestamp,
    });
  }

  @override
  Future<void> updateChatCount({
    required String requestId,
    required String field,
    required int count,
  }) async {
    if (!_isFirebaseReady) return;
    await _db.ref('requests/$requestId').update({
      field: count,
      'updated_at': ServerValue.timestamp,
    });
  }

  @override
  Future<void> updateTripNode({
    required String requestId,
    required Map<String, dynamic> data,
  }) async {
    if (!_isFirebaseReady) return;
    await _db.ref('requests/$requestId').update({
      ...data,
      'updated_at': ServerValue.timestamp,
    });
  }

  @override
  void dispose() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
  }
}

import 'dart:developer';
import 'dart:math' as math;

import '../basic_user_model/basic_user_model.dart';
import 'shop_model1.dart';

/// Tolerant parser for shops arriving from the discovery endpoints.
///
/// [ShopModel1.fromJson] is generated with non-nullable casts and expects the
/// server's DTO shape. Deployed servers may still be returning raw ORM rows,
/// which differ in three ways that each throw:
///
///   * `locationInfo.longitude` — the client's field is misspelled
///     `longtitude`, and the generated parser casts it unconditionally.
///   * no nested `user` object — the row carries only `user_id`.
///   * `categories` as objects rather than names.
///
/// Rather than let the whole nearby-shops list fail to parse (which is what
/// used to happen — silently, as an empty list), normalise here and accept
/// either shape.
class ShopApiParser {
  ShopApiParser._();

  /// Parses one shop. Returns null if the row is too malformed to use, so a
  /// single bad record can't take out the page.
  static ShopModel1? parse(
    Map<String, dynamic> json, {
    double? originLat,
    double? originLng,
  }) {
    try {
      final location = _location(json['locationInfo']);
      final name = _string(json['name']);

      return ShopModel1(
        id: _int(json['id']),
        user: _user(json['user'], fallbackName: name),
        description: _string(json['description']),
        categories: _categories(json['categories']),
        ownerPicUrl: _string(json['ownerPicUrl']),
        locationInfo: location,
        ownerName: _string(json['ownerName']),
        shopPicUrl: _string(json['shopPicUrl']),
        pancardPicUrl: _string(json['pancardPicUrl']),
        ownerIdPicUrl: _string(json['ownerIdPicUrl']),
        businessLicense: _string(json['businessLicense']),
        address: _string(json['address']),
        phoneNumber: _string(json['phoneNumber']),
        name: name.isEmpty ? null : name,
        slug: _string(json['slug']).isEmpty ? null : _string(json['slug']),
        isVerified: _verified(json),
        // Prefer the server's number; fall back to computing it here so the
        // "1.2 km away" badge works against either server version.
        distanceKm: _double(json['distanceKm']) ??
            _haversineKm(originLat, originLng, location),
        productCount: _int(json['productCount']),
      );
    } catch (e) {
      log('ShopApiParser: skipping unparseable shop — $e');
      return null;
    }
  }

  static List<ShopModel1> parseList(
    Iterable<dynamic> rows, {
    double? originLat,
    double? originLng,
  }) =>
      rows
          .whereType<Map<String, dynamic>>()
          .map((row) =>
              parse(row, originLat: originLat, originLng: originLng))
          .whereType<ShopModel1>()
          .toList();

  // ── Field normalisers ───────────────────────────────────────────────

  static String _string(dynamic value) => value == null ? '' : '$value';

  static int? _int(dynamic value) =>
      value == null ? null : int.tryParse('$value');

  static double? _double(dynamic value) =>
      value == null ? null : double.tryParse('$value');

  static LocationInfo _location(dynamic value) {
    if (value is! Map<String, dynamic>) return LocationInfo.defaultValue();

    // Accept the client's misspelling and the server's correct spelling.
    final lat = _double(value['latitude']) ?? 0;
    final lng = _double(value['longtitude'] ?? value['longitude']) ?? 0;

    return LocationInfo(
      completeAddress: _string(value['completeAddress']),
      shortAddress: _string(value['shortAddress']).isNotEmpty
          ? _string(value['shortAddress'])
          : [
              _string(value['city']),
              _string(value['pincode']),
            ].where((e) => e.isNotEmpty).join(' '),
      latitude: lat,
      longtitude: lng,
    );
  }

  static BasicUserModel _user(dynamic value, {required String fallbackName}) {
    if (value is Map<String, dynamic>) {
      return BasicUserModel(
        id: _int(value['id']),
        username: _string(value['username']).isNotEmpty
            ? _string(value['username'])
            : fallbackName,
        // The hash must never reach the client; the model's field is
        // non-nullable, so it gets an empty placeholder.
        password: '',
        email: _string(value['email']),
      );
    }
    return BasicUserModel(username: fallbackName, password: '', email: '');
  }

  /// Categories arrive either as plain names or as full category objects.
  static List<String> _categories(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((entry) {
          if (entry is String) return entry;
          if (entry is Map<String, dynamic>) return _string(entry['name']);
          return '';
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static bool? _verified(Map<String, dynamic> json) {
    final flag = json['isVerified'];
    if (flag is bool) return flag;

    final verification = json['verification'];
    if (verification is Map<String, dynamic>) {
      return _string(verification['status']).toUpperCase() == 'APPROVED';
    }
    return null;
  }

  /// Great-circle distance in km, matching the server's Haversine filter.
  static double? _haversineKm(
    double? originLat,
    double? originLng,
    LocationInfo location,
  ) {
    if (originLat == null || originLng == null) return null;
    if (!location.hasCoordinates) return null;

    double toRad(double d) => d * math.pi / 180;

    final dLat = toRad(location.latitude - originLat);
    final dLng = toRad(location.longtitude - originLng);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(toRad(originLat)) *
            math.cos(toRad(location.latitude)) *
            math.pow(math.sin(dLng / 2), 2);

    final km = 6371 * 2 * math.asin(math.min(1, math.sqrt(a)));
    return double.parse(km.toStringAsFixed(2));
  }
}

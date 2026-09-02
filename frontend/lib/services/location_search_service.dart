import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../data/models/place_suggestion.dart';
import '../data/models/shop_model/shop_model1.dart';

/// Forward and reverse geocoding for the location picker.
///
/// Backed by OpenStreetMap Nominatim, which needs no API key — the app can
/// ship without the caller provisioning Google Places billing. Nominatim's
/// usage policy requires an identifying User-Agent and at most one request
/// per second, both of which are enforced here.
class LocationSearchService {
  LocationSearchService._();

  static const String _base = 'https://nominatim.openstreetmap.org';

  /// Required by the Nominatim usage policy. Point it at something real for
  /// production so they can reach you before rate-limiting the app.
  static const Map<String, String> _headers = {
    'User-Agent': 'Nearzy/1.0 (hyperlocal marketplace; contact@nearzy.app)',
    'Accept': 'application/json',
  };

  /// Nominatim allows 1 req/s. Requests are serialised behind this.
  static const Duration _minGap = Duration(milliseconds: 1100);
  static DateTime _lastCall = DateTime.fromMillisecondsSinceEpoch(0);

  /// Cheap memo so re-opening the picker with the same query is instant and
  /// doesn't spend the rate-limit budget.
  static final Map<String, List<PlaceSuggestion>> _cache = {};

  static Future<void> _throttle() async {
    final since = DateTime.now().difference(_lastCall);
    if (since < _minGap) await Future<void>.delayed(_minGap - since);
    _lastCall = DateTime.now();
  }

  /// Typeahead search. Returns `[]` rather than throwing — a failed
  /// autocomplete should degrade to "no suggestions", never to an error
  /// screen over the map.
  ///
  /// [near] biases results toward the map's current centre, so typing "mall"
  /// in Srinagar surfaces Srinagar malls first.
  static Future<List<PlaceSuggestion>> search(
    String query, {
    double? nearLat,
    double? nearLng,
    String countryCodes = 'in',
    int limit = 8,
  }) async {
    final trimmed = query.trim();
    if (trimmed.length < 3) return const [];

    final cacheKey = '$trimmed|$countryCodes';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    try {
      await _throttle();

      final params = <String, String>{
        'q': trimmed,
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '$limit',
        if (countryCodes.isNotEmpty) 'countrycodes': countryCodes,
      };

      // A ~1.1° box around the map centre — roughly 120km, wide enough to
      // keep nearby towns while still ranking the local match first.
      if (nearLat != null && nearLng != null) {
        params['viewbox'] = '${nearLng - 1.1},${nearLat + 1.1},'
            '${nearLng + 1.1},${nearLat - 1.1}';
        params['bounded'] = '0';
      }

      final response = await http
          .get(Uri.parse('$_base/search').replace(queryParameters: params),
              headers: _headers)
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        log('Nominatim search ${response.statusCode}');
        return const [];
      }

      final results = (jsonDecode(response.body) as List)
          .cast<Map<String, dynamic>>()
          .map(PlaceSuggestion.fromNominatim)
          .toList();

      _cache[cacheKey] = results;
      return results;
    } catch (e) {
      log('LocationSearchService.search failed: $e');
      return const [];
    }
  }

  /// Coordinates → address, for the draggable map pin.
  ///
  /// Falls back to a coordinate string so the picker's confirm button is
  /// never blocked by a geocoder outage.
  static Future<LocationInfo> reverse(double lat, double lng) async {
    try {
      await _throttle();

      final response = await http
          .get(
            Uri.parse('$_base/reverse').replace(queryParameters: {
              'lat': '$lat',
              'lon': '$lng',
              'format': 'jsonv2',
              'addressdetails': '1',
              'zoom': '18',
            }),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final address = (json['address'] as Map<String, dynamic>?) ?? const {};
        final display = (json['display_name'] as String?) ?? '';

        final locality = (address['suburb'] ??
            address['neighbourhood'] ??
            address['city'] ??
            address['town'] ??
            address['village']) as String?;
        final city = (address['city'] ??
            address['town'] ??
            address['village'] ??
            address['county']) as String?;
        final postcode = address['postcode'] as String?;

        return LocationInfo(
          completeAddress: display,
          shortAddress: _shortLabel(locality, city, postcode),
          latitude: lat,
          longtitude: lng,
        );
      }
    } catch (e) {
      log('LocationSearchService.reverse failed: $e');
    }

    return LocationInfo(
      completeAddress: '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
      shortAddress: 'Dropped pin',
      latitude: lat,
      longtitude: lng,
    );
  }

  /// Builds the compact one-line label shown in the app bar and location bar.
  static String _shortLabel(String? locality, String? city, String? postcode) {
    final parts = <String>[
      if (locality != null && locality.isNotEmpty) locality,
      if (city != null && city.isNotEmpty && city != locality) city,
    ];
    if (parts.isEmpty) return postcode ?? 'Selected location';
    final label = parts.join(', ');
    return postcode == null ? label : '$label $postcode';
  }

  /// Turns a suggestion into the app's canonical location value.
  static LocationInfo toLocationInfo(PlaceSuggestion place) => LocationInfo(
        completeAddress: place.fullAddress,
        shortAddress: _shortLabel(place.title, place.city, place.postcode),
        latitude: place.latitude,
        longtitude: place.longitude,
      );
}

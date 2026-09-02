/// One row in the location typeahead.
///
/// Deliberately provider-agnostic: Nominatim fills these today, but the
/// picker only ever sees this shape, so swapping in Google Places later is a
/// change to [LocationSearchService] alone.
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.title,
    required this.subtitle,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.postcode,
    this.country,
  });

  /// Short label — the place's own name ("Lal Chowk").
  final String title;

  /// The rest of the address, for disambiguating identical titles.
  final String subtitle;

  final double latitude;
  final double longitude;

  final String? city;
  final String? state;
  final String? postcode;
  final String? country;

  String get fullAddress =>
      subtitle.isEmpty ? title : '$title, $subtitle';

  /// Nominatim returns a single comma-joined `display_name`; the first
  /// segment is the place itself and the rest is its administrative chain.
  factory PlaceSuggestion.fromNominatim(Map<String, dynamic> json) {
    final display = (json['display_name'] as String?) ?? '';
    final parts = display.split(',').map((e) => e.trim()).toList();
    final address = (json['address'] as Map<String, dynamic>?) ?? const {};

    return PlaceSuggestion(
      title: (json['name'] as String?)?.trim().isNotEmpty == true
          ? json['name'] as String
          : (parts.isNotEmpty ? parts.first : display),
      subtitle: parts.length > 1 ? parts.sublist(1).join(', ') : '',
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      city: (address['city'] ??
              address['town'] ??
              address['village'] ??
              address['suburb'] ??
              address['county']) as String?,
      state: address['state'] as String?,
      postcode: address['postcode'] as String?,
      country: address['country'] as String?,
    );
  }
}

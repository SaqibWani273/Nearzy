/// A customer's saved delivery address.
///
/// The app had no address model at all until now — checkout collected a
/// free-text string that reached only Razorpay's notes, so every order was
/// stored with a null shipping address and nothing to deliver against.
/// Addresses are now real rows the customer picks from at checkout.
class Address {
  const Address({
    required this.id,
    required this.label,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.isDefault = false,
  });

  final int? id;
  final String label;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isDefault;

  static String _str(dynamic v) => v == null ? '' : v.toString();

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] is int ? json['id'] as int : int.tryParse(_str(json['id'])),
        label: _str(json['label']),
        line1: _str(json['line1']),
        line2: _str(json['line2']),
        city: _str(json['city']),
        state: _str(json['state']),
        postalCode: _str(json['postalCode']),
        country: _str(json['country']),
        latitude: _dbl(json['latitude']),
        longitude: _dbl(json['longitude']),
        isDefault: json['isDefault'] == true,
      );

  /// Only the fields the create/update endpoints accept. `id` is carried in
  /// the path, and `isDefault` is sent only when explicitly being set.
  Map<String, dynamic> toRequestBody({bool? asDefault}) => {
        if (label.isNotEmpty) 'label': label,
        'line1': line1,
        if (line2.isNotEmpty) 'line2': line2,
        'city': city,
        'state': state,
        'postalCode': postalCode,
        'country': country,
        'latitude': ?latitude,
        'longitude': ?longitude,
        'isDefault': ?asDefault,
      };

  /// "45 Gole Market, Near Hanuman Mandir, New Delhi, Delhi, 110001"
  ///
  /// Country is left off: every address is domestic today, so repeating
  /// "India" on each row is noise.
  String get singleLine => [line1, line2, city, state, postalCode]
      .where((part) => part.trim().isNotEmpty)
      .join(', ');

  /// The two-line form used on cards: street on top, region beneath.
  String get streetLine =>
      [line1, line2].where((p) => p.trim().isNotEmpty).join(', ');

  String get regionLine => [city, state, postalCode]
      .where((p) => p.trim().isNotEmpty)
      .join(', ');

  /// Falls back to the street when the customer never named the address.
  String get displayLabel => label.trim().isNotEmpty ? label : line1;

  bool get hasCoordinates => latitude != null && longitude != null;

  Address copyWith({
    int? id,
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) =>
      Address(
        id: id ?? this.id,
        label: label ?? this.label,
        line1: line1 ?? this.line1,
        line2: line2 ?? this.line2,
        city: city ?? this.city,
        state: state ?? this.state,
        postalCode: postalCode ?? this.postalCode,
        country: country ?? this.country,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        isDefault: isDefault ?? this.isDefault,
      );
}

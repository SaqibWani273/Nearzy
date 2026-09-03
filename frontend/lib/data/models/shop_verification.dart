import 'shop_model/shop_model1.dart';

/// A shop's application to trade, from `GET /admin/shop-verifications`.
///
/// The backend has been recording these since the shop model landed, but
/// nothing could read them until the admin routes were wired up, so the
/// review screen showed a hardcoded "no pending verifications" regardless of
/// what was actually queued.

/// One submitted document. The server omits slots the applicant left blank,
/// so an empty list genuinely means "supplied nothing" rather than "failed to
/// load".
class VerificationDocument {
  const VerificationDocument({required this.label, required this.url});

  final String label;
  final String url;

  factory VerificationDocument.fromJson(Map<String, dynamic> json) =>
      VerificationDocument(
        label: json['label'] as String? ?? '',
        url: json['url'] as String? ?? '',
      );
}

enum VerificationStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  const VerificationStatus(this.wire);

  final String wire;

  static VerificationStatus fromWire(String? value) =>
      VerificationStatus.values.firstWhere(
        (s) => s.wire == (value ?? '').toUpperCase(),
        orElse: () => VerificationStatus.pending,
      );
}

class ShopVerification {
  const ShopVerification({
    required this.id,
    required this.shopId,
    required this.ownerName,
    required this.status,
    required this.documents,
    this.submittedAt,
    this.shop,
  });

  final int id;
  final int shopId;
  final String ownerName;
  final VerificationStatus status;
  final List<VerificationDocument> documents;
  final DateTime? submittedAt;

  /// The full shop card — trading name, address, location — so the reviewer
  /// judges the business, not just its paperwork.
  final ShopModel1? shop;

  String get shopName {
    final name = shop?.name;
    return (name == null || name.isEmpty) ? ownerName : name;
  }

  factory ShopVerification.fromJson(Map<String, dynamic> json) {
    final rawShop = json['shop'] as Map<String, dynamic>?;
    return ShopVerification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      shopId: (json['shopId'] as num?)?.toInt() ?? 0,
      ownerName: json['ownerName'] as String? ?? '',
      status: VerificationStatus.fromWire(json['status'] as String?),
      documents: (json['documents'] as List<dynamic>? ?? const [])
          .map((e) => VerificationDocument.fromJson(e as Map<String, dynamic>))
          .toList(),
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? ''),
      shop: rawShop == null ? null : ShopModel1.fromJson(rawShop),
    );
  }
}

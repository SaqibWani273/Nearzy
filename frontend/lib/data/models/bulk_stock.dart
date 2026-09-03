// Request and result shapes for `POST /shop/products/bulk-stock`.
//
// Built for the barcode scanner: a shelf sweep produces dozens of adjustments,
// and they land in one transaction rather than one request per beep.

/// One scanned adjustment. Either a relative [delta] or an absolute
/// [stockQuantity] — sending both lets the server pick the absolute value, so
/// callers should set exactly one.
class BulkStockEntry {
  const BulkStockEntry.delta(this.sku, int this.delta) : stockQuantity = null;

  const BulkStockEntry.absolute(this.sku, int this.stockQuantity)
      : delta = null;

  final String sku;
  final int? delta;
  final int? stockQuantity;

  Map<String, dynamic> toJson() => {
        'sku': sku,
        if (delta != null) 'delta': delta,
        if (stockQuantity != null) 'stockQuantity': stockQuantity,
      };
}

/// What happened to one entry. A scanner will inevitably pick up a barcode the
/// shop has never listed, so [unmatched] is an ordinary outcome, not an error.
enum BulkStockOutcome {
  applied('APPLIED'),
  unmatched('UNMATCHED'),
  invalid('INVALID');

  const BulkStockOutcome(this.wire);

  final String wire;

  static BulkStockOutcome fromWire(String? value) =>
      BulkStockOutcome.values.firstWhere(
        (o) => o.wire == (value ?? '').toUpperCase(),
        orElse: () => BulkStockOutcome.invalid,
      );
}

class BulkStockRow {
  const BulkStockRow({
    required this.sku,
    required this.outcome,
    this.productId,
    this.name,
    this.stockQuantity,
    this.available,
    this.reason,
  });

  final String sku;
  final BulkStockOutcome outcome;
  final int? productId;
  final String? name;
  final int? stockQuantity;
  final bool? available;
  final String? reason;

  factory BulkStockRow.fromJson(Map<String, dynamic> json) => BulkStockRow(
        sku: json['sku'] as String? ?? '',
        outcome: BulkStockOutcome.fromWire(json['status'] as String?),
        productId: (json['productId'] as num?)?.toInt(),
        name: json['name'] as String?,
        stockQuantity: (json['stockQuantity'] as num?)?.toInt(),
        available: json['available'] as bool?,
        reason: json['reason'] as String?,
      );
}

class BulkStockResult {
  const BulkStockResult({
    required this.applied,
    required this.unmatched,
    required this.invalid,
    required this.rows,
  });

  final int applied;
  final int unmatched;
  final int invalid;
  final List<BulkStockRow> rows;

  /// Rows worth showing the owner afterwards — the ones that did not land.
  List<BulkStockRow> get needsReview =>
      rows.where((r) => r.outcome != BulkStockOutcome.applied).toList();

  factory BulkStockResult.fromJson(Map<String, dynamic> json) =>
      BulkStockResult(
        applied: (json['applied'] as num?)?.toInt() ?? 0,
        unmatched: (json['unmatched'] as num?)?.toInt() ?? 0,
        invalid: (json['invalid'] as num?)?.toInt() ?? 0,
        rows: (json['results'] as List<dynamic>? ?? const [])
            .map((e) => BulkStockRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

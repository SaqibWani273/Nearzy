import 'product.dart';

/// A product as its *owner* sees it.
///
/// Wraps the customer-facing [Product] with the operational fields the shop
/// endpoints add: markdown enrolment and the auto-unpublish stamp. These are
/// deliberately absent from the public product feed — a shop's pricing
/// strategy is not something to ship to every customer — so they live here
/// rather than being added to [Product] and its generated codec.
class ShopProduct {
  const ShopProduct({
    required this.product,
    required this.markdownEnabled,
    required this.markdownFloorPercent,
    required this.baseDiscountPercent,
    this.autoUnpublishedAt,
  });

  final Product product;

  /// Whether the end-of-day markdown engine may re-price this item.
  final bool markdownEnabled;

  /// The deepest discount the engine may reach. The engine never goes past it.
  final double markdownFloorPercent;

  /// The owner's own standing discount, restored each midnight.
  final double baseDiscountPercent;

  /// Set when the stockout hook hid this item, cleared when it puts it back.
  /// Non-null is what distinguishes "sold out" from "the owner hid it", which
  /// the inventory list needs in order to explain itself.
  final DateTime? autoUnpublishedAt;

  int get id => product.id ?? 0;
  String get name => product.name;
  String get sku => product.sku;
  int get stockQuantity => product.stockQuantity;
  bool get available => product.available;
  int get priceInPaise => product.price;
  double get discountPercent => product.discountInPercentage ?? 0;

  bool get isOutOfStock => stockQuantity <= 0;

  /// Hidden because it ran out, rather than by the owner's choice.
  bool get isAutoUnpublished => !available && autoUnpublishedAt != null;

  /// Hidden deliberately. Restocking will not bring it back.
  bool get isOwnerHidden => !available && autoUnpublishedAt == null;

  factory ShopProduct.fromJson(Map<String, dynamic> json) => ShopProduct(
        product: Product.fromJson(json),
        markdownEnabled: json['markdownEnabled'] as bool? ?? false,
        markdownFloorPercent:
            (json['markdownFloorPercent'] as num?)?.toDouble() ?? 0,
        baseDiscountPercent:
            (json['baseDiscountPercent'] as num?)?.toDouble() ?? 0,
        autoUnpublishedAt:
            DateTime.tryParse(json['autoUnpublishedAt'] as String? ?? ''),
      );
}

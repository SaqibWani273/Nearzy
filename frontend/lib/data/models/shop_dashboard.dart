import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// The shop owner's triage payload, from `GET /shop/dashboard`.
///
/// The shop home used to open straight onto an inventory list, which answers
/// "what do I sell?" when the owner's actual question is "what needs me?".
/// Everything modelled here is something they can act on.

/// Why an alert was raised. Wire values are the strings `ShopAlert.type`
/// stores, kept separate from the Dart names so parsing never depends on
/// `enum.name`.
enum ShopAlertType {
  lowStock('LOW_STOCK'),
  stockout('STOCKOUT'),
  markdownApplied('MARKDOWN_APPLIED'),
  unknown('UNKNOWN');

  const ShopAlertType(this.wire);

  final String wire;

  static ShopAlertType fromWire(String? value) => ShopAlertType.values.firstWhere(
        (t) => t.wire == (value ?? '').toUpperCase(),
        orElse: () => ShopAlertType.unknown,
      );

  IconData get icon => switch (this) {
        ShopAlertType.lowStock => Icons.trending_down_rounded,
        ShopAlertType.stockout => Icons.remove_shopping_cart_rounded,
        ShopAlertType.markdownApplied => Icons.sell_rounded,
        ShopAlertType.unknown => Icons.info_outline_rounded,
      };

  /// What the card's button offers to do. A markdown alert is telling the
  /// owner a price already changed, so "update stock" would name the wrong
  /// job entirely.
  String get actionLabel => switch (this) {
        ShopAlertType.lowStock => 'Update stock',
        ShopAlertType.stockout => 'Restock',
        ShopAlertType.markdownApplied => 'Review pricing',
        ShopAlertType.unknown => 'Review',
      };
}

/// How loudly to render it. Drives colour only — ordering is decided by the
/// server, which sorts CRITICAL first.
enum AlertSeverity {
  critical('CRITICAL'),
  warning('WARNING'),
  info('INFO');

  const AlertSeverity(this.wire);

  final String wire;

  static AlertSeverity fromWire(String? value) => AlertSeverity.values.firstWhere(
        (s) => s.wire == (value ?? '').toUpperCase(),
        orElse: () => AlertSeverity.info,
      );

  Color get color => switch (this) {
        AlertSeverity.critical => AppColors.error,
        AlertSeverity.warning => AppColors.warning,
        AlertSeverity.info => AppColors.info,
      };

  Color get surface => switch (this) {
        AlertSeverity.critical => AppColors.errorSurface,
        AlertSeverity.warning => AppColors.warningSurface,
        AlertSeverity.info => AppColors.infoSurface,
      };
}

/// The product an alert points at, carried inline so a card can render its
/// name and stock without a second request.
class AlertProduct {
  const AlertProduct({
    required this.id,
    required this.name,
    required this.sku,
    required this.stockQuantity,
  });

  final int id;
  final String name;
  final String sku;
  final int stockQuantity;

  factory AlertProduct.fromJson(Map<String, dynamic> json) => AlertProduct(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        sku: json['sku'] as String? ?? '',
        stockQuantity: (json['stockQuantity'] as num?)?.toInt() ?? 0,
      );
}

class ShopAlert {
  const ShopAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
    required this.status,
    this.createdAt,
    this.product,
  });

  final int id;
  final ShopAlertType type;
  final AlertSeverity severity;
  final String title;
  final String body;
  final String status;
  final DateTime? createdAt;
  final AlertProduct? product;

  bool get isUnread => status == 'UNREAD';

  factory ShopAlert.fromJson(Map<String, dynamic> json) => ShopAlert(
        id: (json['id'] as num?)?.toInt() ?? 0,
        type: ShopAlertType.fromWire(json['type'] as String?),
        severity: AlertSeverity.fromWire(json['severity'] as String?),
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        status: json['status'] as String? ?? 'UNREAD',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
        product: json['product'] == null
            ? null
            : AlertProduct.fromJson(json['product'] as Map<String, dynamic>),
      );
}

/// Inventory counts for the "at a glance" row.
class InventorySummary {
  const InventorySummary({
    required this.total,
    required this.unavailable,
    required this.outOfStock,
  });

  final int total;
  final int unavailable;
  final int outOfStock;

  factory InventorySummary.fromJson(Map<String, dynamic> json) => InventorySummary(
        total: (json['total'] as num?)?.toInt() ?? 0,
        unavailable: (json['unavailable'] as num?)?.toInt() ?? 0,
        outOfStock: (json['outOfStock'] as num?)?.toInt() ?? 0,
      );
}

class ShopDashboard {
  const ShopDashboard({
    required this.shopId,
    required this.shopName,
    required this.verificationStatus,
    required this.pendingOrders,
    required this.alerts,
    required this.criticalCount,
    required this.inventory,
  });

  final int shopId;
  final String shopName;
  final String verificationStatus;
  final int pendingOrders;
  final List<ShopAlert> alerts;
  final int criticalCount;
  final InventorySummary inventory;

  bool get isVerified => verificationStatus == 'APPROVED';

  /// True when there is genuinely nothing to do — which earns a real empty
  /// state rather than a screen of zeroes.
  bool get isClear => pendingOrders == 0 && alerts.isEmpty;

  factory ShopDashboard.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>? ?? const {};
    final alerts = json['alerts'] as Map<String, dynamic>? ?? const {};
    final items = (alerts['items'] as List<dynamic>? ?? const [])
        .map((e) => ShopAlert.fromJson(e as Map<String, dynamic>))
        .toList();

    return ShopDashboard(
      shopId: (shop['id'] as num?)?.toInt() ?? 0,
      shopName: shop['name'] as String? ?? '',
      verificationStatus: json['verificationStatus'] as String? ?? 'PENDING',
      pendingOrders: (json['pendingOrders'] as num?)?.toInt() ?? 0,
      alerts: items,
      criticalCount: (alerts['critical'] as num?)?.toInt() ?? 0,
      inventory: InventorySummary.fromJson(
        json['inventory'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

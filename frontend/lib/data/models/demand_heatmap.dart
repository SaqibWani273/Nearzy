/// Order density by delivery location, from `GET /admin/demand-heatmap`.
///
/// Plots where orders were *delivered* rather than where shops are: a shop pin
/// says where supply already exists, while a delivery address says where the
/// demand came from — which is the question the admin is asking when deciding
/// where to widen the discovery radius.
///
/// Orders only. Search queries are not logged anywhere in the backend, so
/// demand that never converted is invisible here.
class DemandPoint {
  const DemandPoint({
    required this.latitude,
    required this.longitude,
    required this.orders,
    required this.revenuePaise,
  });

  final double latitude;
  final double longitude;
  final int orders;
  final int revenuePaise;

  factory DemandPoint.fromJson(Map<String, dynamic> json) => DemandPoint(
        latitude: (json['lat'] as num?)?.toDouble() ?? 0,
        longitude: (json['lng'] as num?)?.toDouble() ?? 0,
        orders: (json['orders'] as num?)?.toInt() ?? 0,
        revenuePaise: (json['revenuePaise'] as num?)?.toInt() ?? 0,
      );
}

class DemandHeatmap {
  const DemandHeatmap({
    required this.windowDays,
    required this.maxOrders,
    required this.totalOrders,
    required this.points,
  });

  final int windowDays;

  /// The busiest cell's order count. The heat layer paints intensity as
  /// `orders / maxOrders`, so it is served rather than rescanned client-side.
  final int maxOrders;
  final int totalOrders;
  final List<DemandPoint> points;

  bool get isEmpty => points.isEmpty;

  factory DemandHeatmap.fromJson(Map<String, dynamic> json) => DemandHeatmap(
        windowDays: (json['windowDays'] as num?)?.toInt() ?? 30,
        maxOrders: (json['maxOrders'] as num?)?.toInt() ?? 0,
        totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
        points: (json['points'] as List<dynamic>? ?? const [])
            .map((e) => DemandPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

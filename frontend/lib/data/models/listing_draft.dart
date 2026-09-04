/// What the listing assistant read off a product photo.
///
/// Hand-written rather than generated: `confidence` is an open map of field
/// name to level, which `json_serializable` would only wrap in ceremony.
///
/// There is deliberately **no price field**. The server never drafts one — a
/// wrong name is a nuisance the owner fixes in a second, a wrong price costs
/// them money on a real sale. Anything that looks like a price on this class
/// would be a bug.
class ListingDraft {
  const ListingDraft({
    required this.name,
    required this.brand,
    required this.size,
    required this.categoryId,
    required this.shortDescription,
    required this.completeDescription,
    required this.confidence,
    required this.needsAttention,
  });

  final String name;
  final String brand;
  final String size;

  /// Null when the model could not settle on one of this deployment's
  /// categories — the owner has to pick.
  final int? categoryId;

  final String shortDescription;
  final String completeDescription;

  /// Field name to `high` / `medium` / `low`.
  final Map<String, String> confidence;

  /// Fields the photo did not show clearly, plus `categoryId` when unresolved.
  /// Flagged rather than hidden, so a guess never passes as read.
  final List<String> needsAttention;

  factory ListingDraft.fromJson(Map<String, dynamic> json) {
    final draft = (json['draft'] as Map?)?.cast<String, dynamic>() ?? const {};
    String text(String key) => (draft[key] as String?)?.trim() ?? '';

    return ListingDraft(
      name: text('name'),
      brand: text('brand'),
      size: text('size'),
      categoryId: (draft['categoryId'] as num?)?.toInt(),
      shortDescription: text('shortDescription'),
      completeDescription: text('completeDescription'),
      confidence: ((json['confidence'] as Map?) ?? const {})
          .map((key, value) => MapEntry(key.toString(), value.toString())),
      needsAttention: ((json['needsAttention'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  bool needsChecking(String field) => needsAttention.contains(field);
}

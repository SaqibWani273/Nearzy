/// What kind of value a product form field holds, which decides its keyboard
/// and its validator.
enum ProductFieldKind { text, rupees, whole }

/// One field on the product upload form.
///
/// This replaces the older convention of encoding "required" as a `**` suffix
/// inside the label and recovering the field key with `label.split(' ')[0]`.
/// That parsed the key out of display copy, so relabelling a field silently
/// detached it from its controller — and it had no way to express an optional
/// field at all.
class ProductFormField {
  const ProductFormField(
    this.key,
    this.label, {
    this.required = false,
    this.kind = ProductFieldKind.text,
    this.hint,
  });

  /// Payload key. Also the controller key — never change it to relabel a field.
  final String key;

  final String label;
  final bool required;
  final ProductFieldKind kind;

  /// Shown under the field. Use it for anything the label shouldn't carry.
  final String? hint;
}

class ProductConstants {
  /// Required fields first, so a shopkeeper in a hurry can stop after four.
  ///
  /// Only what the catalogue genuinely cannot work without is required: a name,
  /// a price, a count and one line of description. Brand, the long description
  /// and the SKU are all nullable in the database, and demanding them per item
  /// is what makes listing a 200-item shop a multi-day job.
  static const List<ProductFormField> formFields = [
    ProductFormField('name', 'Product name', required: true),
    ProductFormField(
      'price',
      'Price (₹)',
      required: true,
      kind: ProductFieldKind.rupees,
      hint: 'Rupees, e.g. 285.50',
    ),
    ProductFormField(
      'stockQuantity',
      'Quantity in stock',
      required: true,
      kind: ProductFieldKind.whole,
    ),
    ProductFormField(
      'shortDescription',
      'Short description',
      required: true,
      hint: 'One line customers see in the listing',
    ),
    ProductFormField('brand', 'Brand'),
    ProductFormField(
      'completeDescription',
      'Full description',
      hint: 'Optional — shown on the product page',
    ),
    ProductFormField(
      'sku',
      'Your item code',
      hint: 'Optional. Use the barcode number to scan this item later',
    ),
  ];
}

/// Rupee formatting.
///
/// Amounts travel as integer paise everywhere — the backend stores paise, the
/// DTOs send paise — so all rendering goes through here rather than each
/// screen dividing by 100 its own way.
class Money {
  Money._();

  /// Indian digit grouping: last three, then pairs. 1234567 -> "12,34,567".
  static String _group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      final needsComma = fromEnd > 3 ? (fromEnd - 3).isOdd : false;
      if (needsComma && fromEnd > 1) buffer.write(',');
    }
    return buffer.toString();
  }

  /// Whole rupees — "₹12,749".
  ///
  /// For cards and grids, where paise never change a buying decision and the
  /// extra glyphs are what push a discounted price pair out of the layout.
  static String rupees(int paise) {
    final value = (paise / 100).round();
    return '₹${value < 0 ? '-' : ''}${_group(value.abs().toString())}';
  }

  /// Exact to the paise, but only when there are paise to show:
  /// 119800 -> "₹1,198", 265408 -> "₹2,654.08".
  ///
  /// Used wherever the number has to reconcile — order receipts, checkout
  /// totals — because a rounded subtotal and a rounded total can disagree
  /// with a rounded discount by a rupee and look like a bug.
  static String exact(int paise) {
    final sign = paise < 0 ? '-' : '';
    final abs = paise.abs();
    final whole = abs ~/ 100;
    final fraction = abs % 100;
    final grouped = _group(whole.toString());
    if (fraction == 0) return '₹$sign$grouped';
    return '₹$sign$grouped.${fraction.toString().padLeft(2, '0')}';
  }

  /// "− ₹120.50", for a discount line on a receipt.
  static String negated(int paise) => '− ${exact(paise.abs())}';
}

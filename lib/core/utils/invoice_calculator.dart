import 'package:intl/intl.dart';

/// Pure, stateless invoice calculation utilities.
///
/// All methods are pure functions with no side-effects and no external dependencies,
/// making them 100% unit-testable and consistent across forms, screens, and PDFs.
class InvoiceCalculator {
  InvoiceCalculator._();

  static final NumberFormat _moneyFormatter = NumberFormat('#,##0.00', 'en_US');

  /// Rounds an amount to 2 decimal places to prevent floating point inaccuracies.
  static double roundMoney(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return (value * 100).round() / 100;
  }

  /// Computes the line subtotal: `price × quantity`.
  ///
  /// Returns 0.0 if either [price] or [quantity] is negative.
  static double subtotal({required double price, required int quantity}) {
    if (price < 0 || quantity < 0) return 0.0;
    return roundMoney(price * quantity);
  }

  /// Computes the gross/net total with optional discount:
  /// `(price × quantity) - discount`.
  ///
  /// Clamped at 0.0 if discount exceeds the subtotal.
  static double total({
    required double price,
    required int quantity,
    double discount = 0.0,
  }) {
    final sub = subtotal(price: price, quantity: quantity);
    final disc = discount < 0 ? 0.0 : roundMoney(discount);
    final tot = sub - disc;
    return tot < 0 ? 0.0 : roundMoney(tot);
  }

  /// Computes the remaining balance: `total − paid`.
  ///
  /// Clamped at 0.0 on the lower bound so remaining balance is never negative.
  /// If [paid] > [totalAmount], remaining balance is 0.0. Use [isOverpaid]
  /// to check if there is an overpayment/credit.
  static double remaining({
    required double totalAmount,
    required double paid,
  }) {
    final t = roundMoney(totalAmount);
    final p = roundMoney(paid);
    final diff = t - p;
    return diff <= 0 ? 0.0 : roundMoney(diff);
  }

  /// Returns `true` if the paid amount strictly exceeds the total amount.
  static bool isOverpaid({
    required double totalAmount,
    required double paid,
  }) {
    return roundMoney(paid) > roundMoney(totalAmount);
  }

  /// Computes the overpaid/credit amount if [paid] > [totalAmount], else 0.0.
  static double overpaidAmount({
    required double totalAmount,
    required double paid,
  }) {
    final t = roundMoney(totalAmount);
    final p = roundMoney(paid);
    return p > t ? roundMoney(p - t) : 0.0;
  }

  /// Returns `true` when the invoice is fully settled (remaining == 0.0 and totalAmount > 0).
  static bool isFullyPaid({
    required double totalAmount,
    required double paid,
  }) {
    return remaining(totalAmount: totalAmount, paid: paid) == 0.0;
  }

  /// Safely parses numeric user input for monetary amounts.
  static double parseMoney(String? text, [double defaultValue = 0.0]) {
    if (text == null) return defaultValue;
    final cleaned = text.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return defaultValue;
    return roundMoney(double.tryParse(cleaned) ?? defaultValue);
  }

  /// Safely parses numeric user input for quantities.
  static int parseQuantity(String? text, [int defaultValue = 1]) {
    if (text == null) return defaultValue;
    final cleaned = text.trim();
    if (cleaned.isEmpty) return defaultValue;
    final parsed = int.tryParse(cleaned);
    if (parsed == null || parsed < 0) return defaultValue;
    return parsed;
  }

  /// Formats monetary amounts to 2 decimal places with comma separators and currency.
  static String formatMoney(
    double amount, {
    String currency = 'ج.م',
    bool includeCurrency = true,
  }) {
    final rounded = roundMoney(amount);
    final formatted = _moneyFormatter.format(rounded);
    if (!includeCurrency || currency.isEmpty) {
      return formatted;
    }
    return '$formatted $currency';
  }
}

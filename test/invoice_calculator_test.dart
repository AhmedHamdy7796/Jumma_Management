import 'package:flutter_test/flutter_test.dart';
import 'package:gomaa_management/core/utils/invoice_calculator.dart';

void main() {
  group('InvoiceCalculator.roundMoney', () {
    test('rounds standard floats to 2 decimal places', () {
      expect(InvoiceCalculator.roundMoney(10.555), 10.56);
      expect(InvoiceCalculator.roundMoney(10.554), 10.55);
      expect(InvoiceCalculator.roundMoney(0.001), 0.0);
      expect(InvoiceCalculator.roundMoney(0.0), 0.0);
    });

    test('handles NaN and infinite values safely', () {
      expect(InvoiceCalculator.roundMoney(double.nan), 0.0);
      expect(InvoiceCalculator.roundMoney(double.infinity), 0.0);
      expect(InvoiceCalculator.roundMoney(double.negativeInfinity), 0.0);
    });
  });

  group('InvoiceCalculator.subtotal and total', () {
    test('computes price * quantity accurately', () {
      expect(InvoiceCalculator.subtotal(price: 150.50, quantity: 2), 301.0);
      expect(InvoiceCalculator.total(price: 150.50, quantity: 2), 301.0);
    });

    test('applies discount correctly to total', () {
      expect(
        InvoiceCalculator.total(price: 100.0, quantity: 3, discount: 50.0),
        250.0,
      );
    });

    test('clamps total to 0 if discount exceeds subtotal', () {
      expect(
        InvoiceCalculator.total(price: 100.0, quantity: 1, discount: 150.0),
        0.0,
      );
    });

    test('returns 0 for negative price or quantity', () {
      expect(InvoiceCalculator.subtotal(price: -10, quantity: 5), 0.0);
      expect(InvoiceCalculator.subtotal(price: 10, quantity: -5), 0.0);
      expect(InvoiceCalculator.total(price: -10, quantity: 5), 0.0);
    });

    test('ignores negative discount', () {
      expect(
        InvoiceCalculator.total(price: 100.0, quantity: 2, discount: -50.0),
        200.0,
      );
    });
  });

  group('InvoiceCalculator.remaining & overpayment', () {
    test('partial payment calculates exact remaining balance', () {
      expect(
        InvoiceCalculator.remaining(totalAmount: 1000.0, paid: 400.0),
        600.0,
      );
      expect(
        InvoiceCalculator.isOverpaid(totalAmount: 1000.0, paid: 400.0),
        isFalse,
      );
      expect(
        InvoiceCalculator.overpaidAmount(totalAmount: 1000.0, paid: 400.0),
        0.0,
      );
      expect(
        InvoiceCalculator.isFullyPaid(totalAmount: 1000.0, paid: 400.0),
        isFalse,
      );
    });

    test('full payment leaves 0 remaining balance', () {
      expect(
        InvoiceCalculator.remaining(totalAmount: 500.0, paid: 500.0),
        0.0,
      );
      expect(
        InvoiceCalculator.isOverpaid(totalAmount: 500.0, paid: 500.0),
        isFalse,
      );
      expect(
        InvoiceCalculator.isFullyPaid(totalAmount: 500.0, paid: 500.0),
        isTrue,
      );
    });

    test('overpayment clamps remaining to 0 and flags overpaid', () {
      expect(
        InvoiceCalculator.remaining(totalAmount: 500.0, paid: 650.0),
        0.0,
      );
      expect(
        InvoiceCalculator.isOverpaid(totalAmount: 500.0, paid: 650.0),
        isTrue,
      );
      expect(
        InvoiceCalculator.overpaidAmount(totalAmount: 500.0, paid: 650.0),
        150.0,
      );
      expect(
        InvoiceCalculator.isFullyPaid(totalAmount: 500.0, paid: 650.0),
        isTrue,
      );
    });

    test('zero or negative paid amount', () {
      expect(
        InvoiceCalculator.remaining(totalAmount: 300.0, paid: 0.0),
        300.0,
      );
      expect(
        InvoiceCalculator.remaining(totalAmount: 300.0, paid: -50.0),
        350.0,
      );
    });

    test('prevents floating point arithmetic epsilon issues', () {
      // 0.1 + 0.2 = 0.30000000000000004 in raw IEEE 754
      final total = InvoiceCalculator.total(price: 0.10, quantity: 3);
      expect(total, 0.30);
      final remaining = InvoiceCalculator.remaining(totalAmount: total, paid: 0.10);
      expect(remaining, 0.20);
    });
  });

  group('InvoiceCalculator.parseMoney & parseQuantity', () {
    test('parses normal string numbers', () {
      expect(InvoiceCalculator.parseMoney('125.75'), 125.75);
      expect(InvoiceCalculator.parseMoney('1,500.50'), 1500.50);
      expect(InvoiceCalculator.parseQuantity('5'), 5);
    });

    test('handles whitespace and empty or invalid inputs safely', () {
      expect(InvoiceCalculator.parseMoney('   '), 0.0);
      expect(InvoiceCalculator.parseMoney(null), 0.0);
      expect(InvoiceCalculator.parseMoney('abc', 10.0), 10.0);

      expect(InvoiceCalculator.parseQuantity(''), 1);
      expect(InvoiceCalculator.parseQuantity(null), 1);
      expect(InvoiceCalculator.parseQuantity('-2', 1), 1);
      expect(InvoiceCalculator.parseQuantity('xyz', 3), 3);
    });
  });

  group('InvoiceCalculator.formatMoney', () {
    test('formats numbers with thousands separators and 2 decimals', () {
      expect(InvoiceCalculator.formatMoney(1000), '1,000.00 ج.م');
      expect(InvoiceCalculator.formatMoney(50.5), '50.50 ج.م');
      expect(
        InvoiceCalculator.formatMoney(1234567.89, currency: 'USD'),
        '1,234,567.89 USD',
      );
      expect(
        InvoiceCalculator.formatMoney(1000, includeCurrency: false),
        '1,000.00',
      );
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:freelancer_mobile/services/tax_service.dart';
import 'package:freelancer_mobile/models/tax_model.dart';

void main() {
  group('TaxService Tests', () {
    test('calculateTotalTaxes should handle zero income', () {
      final result = TaxService.calculateTotalTaxes(0.0, 2024);
      
      expect(result.annualIncome, equals(0.0));
      expect(result.irgAmount, equals(0.0));
      expect(result.casnosAmount, equals(0.0));
      expect(result.totalTaxes, equals(0.0));
      expect(result.year, equals(2024));
    });

    test('calculateTotalTaxes should handle income below IRG threshold', () {
      final result = TaxService.calculateTotalTaxes(100000.0, 2024);
      
      expect(result.annualIncome, equals(100000.0));
      expect(result.irgAmount, equals(0.0)); // Below 120,000 threshold
      expect(result.casnosAmount, equals(15000.0)); // 15% of 100,000
      expect(result.totalTaxes, equals(15000.0));
    });

    test('calculateTotalTaxes should handle income above IRG threshold', () {
      final result = TaxService.calculateTotalTaxes(200000.0, 2024);
      
      expect(result.annualIncome, equals(200000.0));
      expect(result.irgAmount, equals(16000.0)); // 20% of (200,000 - 120,000)
      expect(result.casnosAmount, equals(30000.0)); // 15% of 200,000
      expect(result.totalTaxes, equals(46000.0));
    });

    test('calculateTotalTaxes should handle large income', () {
      final result = TaxService.calculateTotalTaxes(1000000.0, 2024);
      
      expect(result.annualIncome, equals(1000000.0));
      expect(result.irgAmount, equals(176000.0)); // 20% of (1,000,000 - 120,000)
      expect(result.casnosAmount, equals(150000.0)); // 15% of 1,000,000
      expect(result.totalTaxes, equals(326000.0));
    });

    test('TaxCalculationModel should serialize and deserialize correctly', () {
      final original = TaxCalculationModel(
        year: 2024,
        annualIncome: 200000.0,
        irgAmount: 16000.0,
        casnosAmount: 30000.0,
        totalTaxes: 46000.0,
        calculationMethod: "automatic",
        calculatedAt: DateTime(2024, 1, 1),
      );

      final json = original.toJson();
      final restored = TaxCalculationModel.fromJson(json);

      expect(restored.year, equals(original.year));
      expect(restored.annualIncome, equals(original.annualIncome));
      expect(restored.irgAmount, equals(original.irgAmount));
      expect(restored.casnosAmount, equals(original.casnosAmount));
      expect(restored.totalTaxes, equals(original.totalTaxes));
      expect(restored.calculationMethod, equals(original.calculationMethod));
    });
  });
}

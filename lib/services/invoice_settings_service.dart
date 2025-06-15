import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice_settings_model.dart';
import '../models/client_model.dart';

class InvoiceSettingsService {
  static const String _invoiceSettingsKey = 'invoice_settings';
  static InvoiceSettingsService? _instance;

  InvoiceSettingsService._();

  static InvoiceSettingsService get instance {
    _instance ??= InvoiceSettingsService._();
    return _instance!;
  }

  // Get invoice settings
  Future<InvoiceSettingsModel> getInvoiceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_invoiceSettingsKey);

      if (settingsJson != null) {
        final settingsData = jsonDecode(settingsJson);
        return InvoiceSettingsModel.fromJson(settingsData);
      }

      return InvoiceSettingsModel.defaultSettings;
    } catch (e) {
      print('Error loading invoice settings: $e');
      return InvoiceSettingsModel.defaultSettings;
    }
  }

  // Save invoice settings
  Future<bool> saveInvoiceSettings(InvoiceSettingsModel settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updatedSettings = settings.copyWith(
        updatedAt: DateTime.now(),
      );

      final settingsJson = jsonEncode(updatedSettings.toJson());
      await prefs.setString(_invoiceSettingsKey, settingsJson);

      return true;
    } catch (e) {
      print('Error saving invoice settings: $e');
      return false;
    }
  }

  // Generate next invoice number
  Future<String> generateNextInvoiceNumber() async {
    final settings = await getInvoiceSettings();
    final invoiceNumber = settings.generateInvoiceNumber();

    // Increment the next invoice number
    final updatedSettings = settings.copyWith(
      nextInvoiceNumber: settings.nextInvoiceNumber + 1,
    );
    await saveInvoiceSettings(updatedSettings);

    return invoiceNumber;
  }

  // Preview invoice number format
  String previewInvoiceNumber(InvoiceSettingsModel settings) {
    return settings.generateInvoiceNumber();
  }

  // Reset invoice numbering
  Future<bool> resetInvoiceNumbering(int startNumber) async {
    try {
      final settings = await getInvoiceSettings();
      final updatedSettings = settings.copyWith(
        nextInvoiceNumber: startNumber,
      );
      return await saveInvoiceSettings(updatedSettings);
    } catch (e) {
      print('Error resetting invoice numbering: $e');
      return false;
    }
  }

  // Validate invoice settings
  Map<String, String> validateInvoiceSettings(InvoiceSettingsModel settings) {
    final errors = <String, String>{};

    if (settings.invoicePrefix.trim().isEmpty) {
      errors['invoicePrefix'] = 'Invoice prefix is required';
    }

    if (settings.nextInvoiceNumber < 1) {
      errors['nextInvoiceNumber'] = 'Next invoice number must be at least 1';
    }

    if (settings.defaultDueDays < 0) {
      errors['defaultDueDays'] = 'Due days cannot be negative';
    }

    if (settings.enableTax && settings.defaultTaxRate < 0) {
      errors['defaultTaxRate'] = 'Tax rate cannot be negative';
    }

    if (settings.enableTax && settings.defaultTaxRate > 100) {
      errors['defaultTaxRate'] = 'Tax rate cannot exceed 100%';
    }

    if (settings.enableDiscount && settings.defaultDiscountValue < 0) {
      errors['defaultDiscountValue'] = 'Discount value cannot be negative';
    }

    if (settings.enableDiscount &&
        settings.defaultDiscountType == DiscountType.percentage &&
        settings.defaultDiscountValue > 100) {
      errors['defaultDiscountValue'] = 'Discount percentage cannot exceed 100%';
    }

    return errors;
  }

  // Get invoice number formats
  List<InvoiceNumberFormat> getInvoiceNumberFormats() {
    return InvoiceNumberFormat.values;
  }

  // Get discount types
  List<DiscountType> getDiscountTypes() {
    return DiscountType.values;
  }

  // Get invoice templates
  List<InvoiceTemplate> getInvoiceTemplates() {
    return InvoiceTemplate.values;
  }

  // Get currencies
  List<Currency> getCurrencies() {
    return Currency.values;
  }

  // Export invoice settings
  Future<Map<String, dynamic>> exportInvoiceSettings() async {
    final settings = await getInvoiceSettings();
    return settings.toJson();
  }

  // Import invoice settings
  Future<bool> importInvoiceSettings(Map<String, dynamic> settingsData) async {
    try {
      final settings = InvoiceSettingsModel.fromJson(settingsData);
      return await saveInvoiceSettings(settings);
    } catch (e) {
      print('Error importing invoice settings: $e');
      return false;
    }
  }

  // Reset invoice settings
  Future<bool> resetInvoiceSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_invoiceSettingsKey);
      return true;
    } catch (e) {
      print('Error resetting invoice settings: $e');
      return false;
    }
  }

  // Get default payment terms templates
  List<String> getDefaultPaymentTerms() {
    return [
      'Payment is due within 30 days of invoice date.',
      'Payment is due within 15 days of invoice date.',
      'Payment is due within 7 days of invoice date.',
      'Payment is due immediately upon receipt.',
      'Payment is due within 60 days of invoice date.',
      'Net 30 - Payment due in 30 days.',
      'Net 15 - Payment due in 15 days.',
      '2/10 Net 30 - 2% discount if paid within 10 days, otherwise due in 30 days.',
    ];
  }

  // Get default notes templates
  List<String> getDefaultNotes() {
    return [
      'Thank you for your business!',
      'We appreciate your prompt payment.',
      'Please contact us if you have any questions.',
      'Thank you for choosing our services.',
      'We look forward to working with you again.',
      'Payment can be made via bank transfer or cash.',
      'Late payments may incur additional charges.',
    ];
  }

  // Get default payment instructions templates
  List<String> getDefaultPaymentInstructions() {
    return [
      'Please make payment to the bank account details provided.',
      'Payment can be made via bank transfer, cash, or check.',
      'For international payments, please use the SWIFT code provided.',
      'Please include the invoice number as reference when making payment.',
      'Contact us for alternative payment methods if needed.',
      'Payment should be made in the currency specified on this invoice.',
    ];
  }

  // Calculate invoice totals with settings
  Map<String, double> calculateInvoiceTotals({
    required double subtotal,
    InvoiceSettingsModel? settings,
    double? customTaxRate,
    double? customDiscountValue,
    DiscountType? customDiscountType,
  }) {
    settings ??= InvoiceSettingsModel.defaultSettings;

    double discountAmount = 0.0;
    double taxAmount = 0.0;

    // Calculate discount
    if (settings.enableDiscount || customDiscountValue != null) {
      final discountValue = customDiscountValue ?? settings.defaultDiscountValue;
      final discountType = customDiscountType ?? settings.defaultDiscountType;

      if (discountType == DiscountType.percentage) {
        discountAmount = subtotal * (discountValue / 100);
      } else {
        discountAmount = discountValue;
      }
    }

    final afterDiscount = subtotal - discountAmount;

    // Calculate tax
    if (settings.enableTax || customTaxRate != null) {
      final taxRate = customTaxRate ?? settings.defaultTaxRate;
      taxAmount = afterDiscount * (taxRate / 100);
    }

    final total = afterDiscount + taxAmount;

    return {
      'subtotal': subtotal,
      'discountAmount': discountAmount,
      'taxAmount': taxAmount,
      'total': total,
    };
  }
}


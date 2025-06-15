class NumberToWords {
  static const List<String> _ones = [
    '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    'Seventeen', 'Eighteen', 'Nineteen'
  ];

  static const List<String> _tens = [
    '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
  ];

  static const List<String> _thousands = [
    '', 'Thousand', 'Million', 'Billion', 'Trillion'
  ];

  // Currency names for different currencies
  static const Map<String, Map<String, String>> _currencyNames = {
    'DA': {
      'major': 'Dinar',
      'majorPlural': 'Dinars',
      'minor': 'Centime',
      'minorPlural': 'Centimes',
    },
    'USD': {
      'major': 'Dollar',
      'majorPlural': 'Dollars',
      'minor': 'Cent',
      'minorPlural': 'Cents',
    },
    'EUR': {
      'major': 'Euro',
      'majorPlural': 'Euros',
      'minor': 'Cent',
      'minorPlural': 'Cents',
    },
  };

  /// Convert a number to words
  static String convertToWords(double amount, {String currency = 'DA'}) {
    if (amount == 0) {
      final currencyInfo = _currencyNames[currency] ?? _currencyNames['DA']!;
      return 'Zero ${currencyInfo['majorPlural']}';
    }

    // Split into major and minor units (e.g., dollars and cents)
    final majorAmount = amount.floor();
    final minorAmount = ((amount - majorAmount) * 100).round();

    String result = '';

    // Convert major amount
    if (majorAmount > 0) {
      final majorWords = _convertIntegerToWords(majorAmount);
      final currencyInfo = _currencyNames[currency] ?? _currencyNames['DA']!;
      final majorUnit = majorAmount == 1 ? currencyInfo['major'] : currencyInfo['majorPlural'];
      result = '$majorWords $majorUnit';
    }

    // Convert minor amount
    if (minorAmount > 0) {
      final minorWords = _convertIntegerToWords(minorAmount);
      final currencyInfo = _currencyNames[currency] ?? _currencyNames['DA']!;
      final minorUnit = minorAmount == 1 ? currencyInfo['minor'] : currencyInfo['minorPlural'];
      
      if (result.isNotEmpty) {
        result += ' and $minorWords $minorUnit';
      } else {
        result = '$minorWords $minorUnit';
      }
    }

    return result.trim();
  }

  /// Convert integer to words
  static String _convertIntegerToWords(int number) {
    if (number == 0) return 'Zero';
    if (number < 0) return 'Negative ${_convertIntegerToWords(-number)}';

    String result = '';
    int thousandIndex = 0;

    while (number > 0) {
      int chunk = number % 1000;
      if (chunk != 0) {
        String chunkWords = _convertChunkToWords(chunk);
        if (thousandIndex > 0) {
          chunkWords += ' ${_thousands[thousandIndex]}';
        }
        result = result.isEmpty ? chunkWords : '$chunkWords $result';
      }
      number ~/= 1000;
      thousandIndex++;
    }

    return result;
  }

  /// Convert a 3-digit chunk to words
  static String _convertChunkToWords(int number) {
    String result = '';

    // Hundreds
    int hundreds = number ~/ 100;
    if (hundreds > 0) {
      result = '${_ones[hundreds]} Hundred';
    }

    // Tens and ones
    int remainder = number % 100;
    if (remainder > 0) {
      if (result.isNotEmpty) result += ' ';
      
      if (remainder < 20) {
        result += _ones[remainder];
      } else {
        int tens = remainder ~/ 10;
        int ones = remainder % 10;
        result += _tens[tens];
        if (ones > 0) {
          result += '-${_ones[ones]}';
        }
      }
    }

    return result;
  }

  /// Get currency symbol for display
  static String getCurrencySymbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'DA':
        return 'DA';
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      default:
        return currency;
    }
  }

  /// Format amount with currency for display
  static String formatAmountWithCurrency(double amount, String currency) {
    final symbol = getCurrencySymbol(currency);
    return '${amount.toStringAsFixed(2)} $symbol';
  }
}


import 'package:intl/intl.dart';

class AppCurrencyFormatter {
  static String _currencyCode = 'VND';

  static void setCurrency(String currencyCode) {
    _currencyCode = currencyCode.toUpperCase() == 'USD' ? 'USD' : 'VND';
  }

  static String format(
    num amount, {
    String? currencyCode,
  }) {
    final resolvedCode = (currencyCode ?? _currencyCode).toUpperCase();
    final isUsd = resolvedCode == 'USD';

    final formatter = NumberFormat.currency(
      locale: isUsd ? 'en_US' : 'vi_VN',
      symbol: isUsd ? r'$' : 'VND ',
      decimalDigits: isUsd ? 2 : 0,
    );

    return formatter.format(amount);
  }
}

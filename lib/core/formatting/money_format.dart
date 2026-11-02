import '../currency/currency.dart';

/// Formats minor units as a grouped amount with a currency symbol.
///
/// `4860000` NGN becomes `₦48,600.00`. A negative value keeps the sign
/// in front of the symbol.
String formatMinor(int minor, String currencyCode) {
  final symbol = Currencies.symbolFor(currencyCode);
  final negative = minor < 0;
  final absolute = minor.abs();
  final major = absolute ~/ 100;
  final fraction = (absolute % 100).toString().padLeft(2, '0');
  final grouped = _groupThousands(major);
  return '${negative ? '-' : ''}$symbol$grouped.$fraction';
}

/// Parses a user-entered major amount into minor units.
///
/// Accepts `48600`, `48,600.50`, and `12.5`. Returns null when the text is
/// empty, not a positive amount, or has more than two decimal places.
int? parseMoneyInput(String input, {bool allowZero = false}) {
  final cleaned = input.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
  if (match == null) return null;
  final major = int.parse(match.group(1)!);
  final fractionDigits = match.group(2) ?? '';
  final fraction = int.parse(fractionDigits.padRight(2, '0'));
  final minor = major * 100 + fraction;
  if (minor < 0 || (minor == 0 && !allowZero)) return null;
  return minor;
}

String formatShortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _groupThousands(int major) {
  final digits = major.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

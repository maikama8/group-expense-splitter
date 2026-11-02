/// A currency the splitter knows how to display and convert.
class Currency {
  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  final String code;
  final String symbol;
  final String name;
}

/// Currencies supported by the offline demo rate table.
///
/// Every entry uses two decimal minor units (kobo, cents, pence, pesewas).
class Currencies {
  const Currencies._();

  static const ngn = Currency(
    code: 'NGN',
    symbol: '₦',
    name: 'Nigerian naira',
  );
  static const usd = Currency(
    code: 'USD',
    symbol: r'$',
    name: 'US dollar',
  );
  static const gbp = Currency(
    code: 'GBP',
    symbol: '£',
    name: 'British pound',
  );
  static const eur = Currency(
    code: 'EUR',
    symbol: '€',
    name: 'Euro',
  );
  static const ghs = Currency(
    code: 'GHS',
    symbol: '₵',
    name: 'Ghanaian cedi',
  );

  static const List<Currency> supported = [ngn, usd, gbp, eur, ghs];

  static bool isSupported(String code) =>
      supported.any((currency) => currency.code == code);

  static Currency byCode(String code) {
    for (final currency in supported) {
      if (currency.code == code) return currency;
    }
    return Currency(code: code, symbol: code, name: code);
  }

  static String symbolFor(String code) => byCode(code).symbol;
}

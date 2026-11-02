import 'exchange_rate_service.dart';

/// Offline rates pivoted through NGN so cross rates stay exact in tests.
///
/// Values are rounded demo fixtures, not live market quotes:
/// about ₦1,600 per US dollar, ₦2,000 per pound, ₦1,750 per euro,
/// and ₦100 per Ghanaian cedi.
class MockExchangeRateService extends ExchangeRateService {
  const MockExchangeRateService();

  /// Naira (major units) per one major unit of each currency.
  static const Map<String, double> ngnPerMajorUnit = {
    'NGN': 1,
    'USD': 1600,
    'GBP': 2000,
    'EUR': 1750,
    'GHS': 100,
  };

  @override
  double rate({required String base, required String quote}) {
    if (base == quote) return 1;
    final baseNgn = _ngnPerUnit(base);
    final quoteNgn = _ngnPerUnit(quote);
    return baseNgn / quoteNgn;
  }

  @override
  int convertMinor({
    required int amountMinor,
    required String from,
    required String to,
  }) {
    if (from == to) return amountMinor;
    final ngnMinor = amountMinor * _ngnPerUnit(from);
    return (ngnMinor / _ngnPerUnit(to)).round();
  }

  double _ngnPerUnit(String code) {
    final rate = ngnPerMajorUnit[code];
    if (rate == null) {
      throw ArgumentError.value(code, 'currency', 'Unsupported currency');
    }
    return rate;
  }
}

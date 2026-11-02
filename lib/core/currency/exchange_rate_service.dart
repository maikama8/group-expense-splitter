/// Converts money between currencies.
///
/// Implementations may be offline fixtures or a live rate feed. Callers depend
/// only on this type so the source of rates can change without touching split
/// or balance code.
abstract class ExchangeRateService {
  const ExchangeRateService();

  /// How many major units of [quote] equal one major unit of [base].
  double rate({required String base, required String quote});

  /// Converts an amount in minor units (two decimal places) from [from] to [to].
  int convertMinor({
    required int amountMinor,
    required String from,
    required String to,
  });
}

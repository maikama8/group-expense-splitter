import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/currency/exchange_rate_service.dart';
import '../core/currency/mock_exchange_rate_service.dart';
import '../data/group_book_repository.dart';
import '../data/seed_data.dart';

final exchangeRateServiceProvider = Provider<ExchangeRateService>(
  (ref) => const MockExchangeRateService(),
);

final groupBookRepositoryProvider = Provider<GroupBookRepository>(
  (ref) => InMemoryGroupBookRepository(initial: SeedData.build()),
);

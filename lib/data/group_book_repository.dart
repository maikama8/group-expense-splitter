import '../state/app_state.dart';

/// Storage port for a group's books.
///
/// [InMemoryGroupBookRepository] keeps the book in process memory and is the
/// default. A sqflite or hive implementation can replace it without changing
/// the screen layer.
abstract class GroupBookRepository {
  AppState load();

  void save(AppState state);
}

class InMemoryGroupBookRepository implements GroupBookRepository {
  InMemoryGroupBookRepository({required AppState initial}) : _state = initial;

  AppState _state;

  @override
  AppState load() => _state;

  @override
  void save(AppState state) => _state = state;
}

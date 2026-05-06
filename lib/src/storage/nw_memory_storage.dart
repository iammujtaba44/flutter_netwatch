import '../models/nw_response.dart';
import '../models/nw_transaction.dart';
import 'nw_storage.dart';

class NWMemoryStorage implements NWStorage {
  final int maxSize;
  final List<NWTransaction> _transactions = <NWTransaction>[];

  NWMemoryStorage({required this.maxSize});

  @override
  void add(NWTransaction transaction) {
    _transactions.insert(0, transaction);
    while (_transactions.length > maxSize) {
      _transactions.removeLast();
    }
  }

  @override
  void update(String id, NWResponse response) {
    final index = _transactions.indexWhere((t) => t.id == id);
    if (index == -1) return;
    _transactions[index] = _transactions[index].copyWithResponse(response);
  }

  @override
  void remove(String id) {
    _transactions.removeWhere((t) => t.id == id);
  }

  @override
  void clear() {
    _transactions.clear();
  }

  @override
  List<NWTransaction> getAll() => List.unmodifiable(_transactions);

  @override
  NWTransaction? getById(String id) {
    for (final t in _transactions) {
      if (t.id == id) return t;
    }
    return null;
  }

  @override
  int get count => _transactions.length;
}

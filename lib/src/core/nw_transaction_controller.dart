import 'dart:async';

import '../models/nw_transaction.dart';

class NWTransactionController {
  final _controller = StreamController<List<NWTransaction>>.broadcast();

  Stream<List<NWTransaction>> get stream => _controller.stream;

  void emit(List<NWTransaction> transactions) {
    if (_controller.isClosed) return;
    _controller.add(transactions);
  }

  void dispose() {
    _controller.close();
  }
}

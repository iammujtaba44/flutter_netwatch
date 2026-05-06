import '../models/nw_response.dart';
import '../models/nw_transaction.dart';

abstract class NWStorage {
  void add(NWTransaction transaction);
  void update(String id, NWResponse response);
  void remove(String id);
  void clear();
  List<NWTransaction> getAll();
  NWTransaction? getById(String id);
  int get count;
}

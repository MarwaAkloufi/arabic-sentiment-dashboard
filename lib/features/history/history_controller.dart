import 'package:flutter/foundation.dart';

import '../../data/models.dart';
import '../../data/sentiment_api.dart';

class HistoryController extends ChangeNotifier {
  HistoryController(this.api);

  final SentimentApi api;

  PagedLogs? page;
  bool loading = false;
  String? error;

  int pageNumber = 1;
  int limit = 20;
  String? label; 
  String search = '';

  int? sortColumn; 
  bool sortAscending = true;

  int _req = 0;

  Future<void> load() async {
    final id = ++_req;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final p = await api.getLogs(
        page: pageNumber,
        limit: limit,
        label: label,
        search: search,
      );
      if (id != _req) return;
      page = p;
    } catch (e) {
      if (id != _req) return;
      error = e is ApiException ? e.message : 'حدث خطأ غير متوقع';
    }
    loading = false;
    notifyListeners();
  }

  void setLabel(String? v) {
    label = v;
    pageNumber = 1;
    load();
  }

  void setSearch(String v) {
    final s = v.trim();
    if (s == search) return;
    search = s;
    pageNumber = 1;
    load();
  }

  void setLimit(int v) {
    limit = v;
    pageNumber = 1;
    load();
  }

  void goTo(int p) {
    final max = page?.pageCount ?? 1;
    pageNumber = p.clamp(1, max).toInt();
    load();
  }

  Future<String?> deleteOne(int id) async {
    try {
      await api.deleteLog(id);
    } catch (e) {
      return e is ApiException ? e.message : 'تعذّر حذف التقييم';
    }
    if ((page?.data.length ?? 0) <= 1 && pageNumber > 1) pageNumber--;
    await load();
    return null;
  }

  Future<String?> deleteAll() async {
    try {
      await api.deleteAllLogs();
    } catch (e) {
      return e is ApiException ? e.message : 'تعذّر حذف السجل';
    }
    pageNumber = 1;
    await load();
    return null;
  }

  void sortBy(int column, bool ascending) {
    sortColumn = column;
    sortAscending = ascending;
    notifyListeners();
  }

  List<SentimentLog> get rows {
    final list = [...(page?.data ?? const <SentimentLog>[])];
    final c = sortColumn;
    if (c == null) return list;
    int cmp(SentimentLog a, SentimentLog b) {
      if (c == 1) return a.label.compareTo(b.label);
      final x = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final y = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return x.compareTo(y);
    }

    list.sort((a, b) => sortAscending ? cmp(a, b) : cmp(b, a));
    return list;
  }
}

import 'package:flutter/foundation.dart';

import '../../data/models.dart';
import '../../data/sentiment_api.dart';

class OverviewController extends ChangeNotifier {
  OverviewController(this.api);

  final SentimentApi api;

  List<SentimentLog> recent = const [];
  int total = 0;
  bool loaded = false;
  bool loading = false;
  String? error;
  int _req = 0;

  Future<void> load() async {
    final id = ++_req;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final p = await api.getLogs(page: 1, limit: 10);
      if (id != _req) return;
      recent = p.data;
      total = p.total;
      loaded = true;
    } catch (e) {
      if (id != _req) return;
      error = e is ApiException ? e.message : 'حدث خطأ غير متوقع';
    }
    loading = false;
    notifyListeners();
  }
}

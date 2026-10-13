double _d(dynamic v) => v is num ? v.toDouble() : (double.tryParse('$v') ?? 0);
double? _dn(dynamic v) => v == null ? null : _d(v);
int _i(dynamic v) => v is num ? v.toInt() : (int.tryParse('$v') ?? 0);

/// يقابل SentimentLog / BatchItemResult في الباك إند.
/// ملاحظة: نتائج التحليل الجماعي لا تحتوي على id لذلك هو اختياري.
class SentimentLog {
  const SentimentLog({
    required this.id,
    required this.text,
    required this.cleanedText,
    required this.label,
    required this.confidence,
    required this.posProbability,
    required this.negProbability,
    required this.createdAt,
  });

  final int? id;
  final String text;
  final String cleanedText;
  final String label; // 'pos' | 'neg'
  final double confidence;
  final double? posProbability;
  final double? negProbability;
  final DateTime? createdAt;

  bool get isPositive => label == 'pos';
  bool get isNegative => label == 'neg';

  factory SentimentLog.fromJson(Map<String, dynamic> j) {
    return SentimentLog(
      id: j['id'] == null ? null : _i(j['id']),
      text: (j['text'] ?? '').toString(),
      cleanedText: (j['cleanedText'] ?? '').toString(),
      label: (j['label'] ?? '').toString(),
      confidence: _d(j['confidence']),
      posProbability: _dn(j['posProbability']),
      negProbability: _dn(j['negProbability']),
      createdAt: j['createdAt'] == null
          ? null
          : DateTime.tryParse(j['createdAt'].toString())?.toLocal(),
    );
  }
}

class DailyStat {
  const DailyStat({
    required this.date,
    required this.total,
    required this.pos,
    required this.neg,
  });

  final String date; // YYYY-MM-DD
  final int total;
  final int pos;
  final int neg;

  factory DailyStat.fromJson(Map<String, dynamic> j) => DailyStat(
        date: (j['date'] ?? '').toString(),
        total: _i(j['total']),
        pos: _i(j['pos']),
        neg: _i(j['neg']),
      );
}

class Stats {
  const Stats({
    required this.totalLogs,
    required this.positiveCount,
    required this.negativeCount,
    required this.positivePercentage,
    required this.negativePercentage,
    required this.averageConfidence,
    required this.daily,
  });

  final int totalLogs;
  final int positiveCount;
  final int negativeCount;
  final double positivePercentage; // 0..100
  final double negativePercentage; // 0..100
  final double averageConfidence;
  final List<DailyStat> daily;

  factory Stats.fromJson(Map<String, dynamic> j) {
    final raw = j['dailyDistribution'];
    return Stats(
      totalLogs: _i(j['totalLogs']),
      positiveCount: _i(j['positiveCount']),
      negativeCount: _i(j['negativeCount']),
      positivePercentage: _d(j['positivePercentage']),
      negativePercentage: _d(j['negativePercentage']),
      averageConfidence: _d(j['averageConfidence']),
      daily: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => DailyStat.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }
}

class PagedLogs {
  const PagedLogs({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<SentimentLog> data;
  final int total;
  final int page;
  final int limit;

  int get pageCount => total == 0 ? 1 : (total / limit).ceil();

  factory PagedLogs.fromJson(Map<String, dynamic> j) {
    final raw = j['data'];
    return PagedLogs(
      data: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => SentimentLog.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      total: _i(j['total']),
      page: _i(j['page']),
      limit: _i(j['limit']),
    );
  }
}

/// نتيجة analyze-batch أو analyze-file.
class BatchResult {
  const BatchResult({
    required this.succeeded,
    required this.failedCount,
    required this.skipped,
    required this.results,
    required this.fileName,
    required this.totalRows,
  });

  final int succeeded;
  final int failedCount;
  final int skipped;
  final List<SentimentLog> results;
  final String? fileName; // فقط لـ analyze-file
  final int? totalRows; // فقط لـ analyze-file

  factory BatchResult.fromJson(Map<String, dynamic> j) {
    final raw = j['results'];
    return BatchResult(
      succeeded: _i(j['succeeded']),
      failedCount: _i(j['failedCount']),
      skipped: _i(j['skipped']),
      results: raw is List
          ? raw
              .whereType<Map>()
              .map((e) => SentimentLog.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      fileName: j['fileName']?.toString(),
      totalRows: j['totalRows'] == null ? null : _i(j['totalRows']),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/config.dart';
import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// كل المسارات هنا مطابقة لما هو موجود فعلاً في الباك إند (NestJS):
///   GET  /ping
///   GET  /sentiment/stats
///   GET  /sentiment/logs?page&limit&label&search
///   POST /sentiment/analyze        { text }
///   POST /sentiment/analyze-batch  { texts: [] }
///   POST /sentiment/analyze-file   multipart (field: file)
///   DELETE /sentiment/logs/:id     حذف تقييم واحد
///   DELETE /sentiment/logs         حذف كل التقييمات
class SentimentApi {
  SentimentApi({String? baseUrl, http.Client? client})
      : _base = _trimSlash(baseUrl ?? AppConfig.apiBaseUrl),
        _client = client ?? http.Client();

  final String _base;
  final http.Client _client;

  static String _trimSlash(String s) =>
      s.endsWith('/') ? s.substring(0, s.length - 1) : s;

  Uri _uri(String path, [Map<String, String>? query]) {
    final u = Uri.parse('$_base$path');
    return query == null ? u : u.replace(queryParameters: query);
  }

  Future<dynamic> _send(
    Future<http.Response> Function() call, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    http.Response res;
    try {
      res = await call().timeout(timeout);
    } on TimeoutException {
      throw ApiException('انتهت مهلة الاتصال بالخادم، حاول مرة أخرى');
    } on http.ClientException {
      throw ApiException('تعذّر الاتصال بالخادم، تحقق من الإنترنت');
    } catch (_) {
      throw ApiException('حدث خطأ أثناء الاتصال بالخادم');
    }

    final body = utf8.decode(res.bodyBytes, allowMalformed: true);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (body.isEmpty) return null;
      try {
        return jsonDecode(body);
      } catch (_) {
        throw ApiException('رد غير متوقع من الخادم');
      }
    }
    throw ApiException(_errorMessage(res.statusCode, body),
        statusCode: res.statusCode);
  }

  String _errorMessage(int code, String body) {
    String? serverMsg;
    try {
      final j = jsonDecode(body);
      if (j is Map && j['message'] != null) {
        final m = j['message'];
        serverMsg = m is List ? m.join('، ') : m.toString();
      }
    } catch (_) {}

    switch (code) {
      case 400:
        return serverMsg ?? 'طلب غير صالح';
      case 413:
        return 'حجم الملف أكبر من المسموح به على الخادم';
      case 502:
        return 'تعذّر الاتصال بخدمة الذكاء الاصطناعي، حاول بعد قليل';
      case 500:
        return 'حدث خطأ في الخادم، حاول لاحقاً';
      default:
        return serverMsg ?? 'خطأ غير متوقع ($code)';
    }
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    throw ApiException('رد غير متوقع من الخادم');
  }

  Future<Stats> getStats() async {
    final j = await _send(() => _client.get(_uri('/sentiment/stats')));
    return Stats.fromJson(_asMap(j));
  }

  Future<SentimentLog> analyze(String text) async {
    final j = await _send(
      () => _client.post(
        _uri('/sentiment/analyze'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      ),
    );
    return SentimentLog.fromJson(_asMap(j));
  }

  Future<BatchResult> analyzeBatch(List<String> texts) async {
    final j = await _send(
      () => _client.post(
        _uri('/sentiment/analyze-batch'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'texts': texts}),
      ),
      timeout: const Duration(seconds: 120),
    );
    return BatchResult.fromJson(_asMap(j));
  }

  Future<BatchResult> analyzeFile(String fileName, Uint8List bytes) async {
    final j = await _send(
      () async {
        final req = http.MultipartRequest('POST', _uri('/sentiment/analyze-file'))
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );
        final streamed = await _client.send(req);
        return http.Response.fromStream(streamed);
      },
      timeout: const Duration(seconds: 180),
    );
    return BatchResult.fromJson(_asMap(j));
  }

  Future<PagedLogs> getLogs({
    int page = 1,
    int limit = 20,
    String? label,
    String? search,
  }) async {
    final query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (label != null) 'label': label,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final j = await _send(() => _client.get(_uri('/sentiment/logs', query)));
    return PagedLogs.fromJson(_asMap(j));
  }

  Future<void> deleteLog(int id) async {
    await _send(() => _client.delete(_uri('/sentiment/logs/$id')));
  }

  Future<void> deleteAllLogs() async {
    await _send(() => _client.delete(_uri('/sentiment/logs')));
  }
}

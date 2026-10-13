import 'dart:convert';
import 'dart:typed_data';

/// نفس منطق الباك إند: يبحث عن عمود باسم text / comment / review / نص ...
/// وإن لم يجد يستخدم العمود الأول.
final RegExp _headerRegex = RegExp(
  r'^(text|comment|review|tweet|body|نص|مراجعة|تغريدة|المراجعة|التغريدة|التعليق)$',
  caseSensitive: false,
);

List<String> extractTexts(Uint8List bytes, String extension) {
  var content = utf8.decode(bytes, allowMalformed: true);
  if (content.startsWith('\uFEFF')) content = content.substring(1);

  if (extension == 'txt') {
    return content
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
  }

  final rows = parseCsv(content);
  if (rows.isEmpty) return [];

  final header = rows.first.map((c) => c.trim()).toList();
  final headerIndex = header.indexWhere((h) => _headerRegex.hasMatch(h));
  final textColumn = headerIndex >= 0 ? headerIndex : 0;
  final firstDataRow = headerIndex >= 0 ? 1 : 0;

  final texts = <String>[];
  for (var i = firstDataRow; i < rows.length; i++) {
    final row = rows[i];
    var value = textColumn < row.length ? row[textColumn].trim() : '';
    if (value.isEmpty) {
      for (final cell in row) {
        if (cell.trim().isNotEmpty) {
          value = cell.trim();
          break;
        }
      }
    }
    if (value.isNotEmpty) texts.add(value);
  }
  return texts;
}

int _count(String s, String ch) => ch.allMatches(s).length;

/// محلل CSV بسيط يدعم علامات الاقتباس والأسطر المتعددة داخل الحقل
/// ويكتشف الفاصل (, أو ; أو Tab) من السطر الأول.
List<List<String>> parseCsv(String input) {
  final firstLine = input.split('\n').first;
  var delimiter = ',';
  var best = _count(firstLine, ',');
  for (final d in [';', '\t']) {
    final c = _count(firstLine, d);
    if (c > best) {
      best = c;
      delimiter = d;
    }
  }

  final rows = <List<String>>[];
  var row = <String>[];
  final sb = StringBuffer();
  var inQuotes = false;

  for (var i = 0; i < input.length; i++) {
    final ch = input[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        sb.write(ch);
      }
    } else if (ch == '"' && sb.isEmpty) {
      inQuotes = true;
    } else if (ch == delimiter) {
      row.add(sb.toString());
      sb.clear();
    } else if (ch == '\n' || ch == '\r') {
      if (ch == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
      row.add(sb.toString());
      sb.clear();
      rows.add(row);
      row = <String>[];
    } else {
      sb.write(ch);
    }
  }
  if (sb.isNotEmpty || row.isNotEmpty) {
    row.add(sb.toString());
    rows.add(row);
  }
  return rows;
}

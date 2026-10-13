import 'dart:math';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/aspects.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/sentiment_api.dart';
import '../../shared/widgets.dart';
import 'text_extractor.dart';

enum _Phase { idle, ready, running, done }

const _chunkSize = 20;
const _maxSheetBytes = 4 * 1024 * 1024; 
const _maxTextBytes = 10 * 1024 * 1024; 

class BulkPage extends StatefulWidget {
  const BulkPage({super.key, required this.api});

  final SentimentApi api;

  @override
  State<BulkPage> createState() => _BulkPageState();
}

class _BulkPageState extends State<BulkPage> {
  String? _name;
  Uint8List? _bytes;
  _Phase _phase = _Phase.idle;
  String? _error;
  bool _dragging = false;
  bool _cancel = false;

  int _processed = 0;
  int _total = 0;
  int _failed = 0;
  int _skipped = 0;
  final List<SentimentLog> _results = [];

  String get _ext => (_name ?? '').split('.').last.toLowerCase();
  bool get _isSheet => _ext == 'xlsx' || _ext == 'xls';

  void _setFile(String name, Uint8List bytes) {
    final ext = name.split('.').last.toLowerCase();
    if (!['csv', 'txt', 'xlsx', 'xls'].contains(ext)) {
      setState(() {
        _dragging = false;
        _error = 'نوع الملف غير مدعوم. المسموح: CSV أو TXT أو XLSX أو XLS';
      });
      return;
    }
    final isSheet = ext == 'xlsx' || ext == 'xls';
    if (isSheet && bytes.length > _maxSheetBytes) {
      setState(() {
        _dragging = false;
        _error = 'ملف Excel أكبر من 4MB. قسّمه إلى ملفات أصغر أو احفظه بصيغة CSV.';
      });
      return;
    }
    if (bytes.length > _maxTextBytes) {
      setState(() {
        _dragging = false;
        _error = 'حجم الملف أكبر من 10MB';
      });
      return;
    }
    setState(() {
      _dragging = false;
      _name = name;
      _bytes = bytes;
      _error = null;
      _phase = _Phase.ready;
      _results.clear();
      _processed = _total = _failed = _skipped = 0;
    });
  }

  Future<void> _pick() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv', 'txt', 'xlsx', 'xls'],
        withData: true,
      );
      if (res == null || res.files.isEmpty) return;
      final f = res.files.first;
      final bytes = f.bytes;
      if (bytes == null) {
        setState(() => _error = 'تعذّرت قراءة الملف');
        return;
      }
      _setFile(f.name, bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'تعذّر فتح نافذة اختيار الملف');
    }
  }

  Future<void> _start() async {
    final bytes = _bytes;
    final name = _name;
    if (bytes == null || name == null) return;

    setState(() {
      _phase = _Phase.running;
      _error = null;
      _cancel = false;
      _processed = 0;
      _failed = 0;
      _skipped = 0;
      _results.clear();
    });

    try {
      if (_isSheet) {
        final r = await widget.api.analyzeFile(name, bytes);
        if (!mounted) return;
        setState(() {
          _results.addAll(r.results);
          _failed = r.failedCount;
          _skipped = r.skipped;
          _total = r.totalRows ?? r.results.length;
          _processed = _total;
        });
      } else {
        final texts = extractTexts(bytes, _ext);
        if (texts.isEmpty) {
          throw ApiException(
              'لم نجد تقييمات داخل الملف. تأكد من وجود عمود باسم review أو text أو comment أو نص');
        }
        setState(() => _total = texts.length);

        var consecutiveFailures = 0;
        for (var i = 0; i < texts.length; i += _chunkSize) {
          if (_cancel || !mounted) break;
          final chunk = texts.sublist(i, min(i + _chunkSize, texts.length));
          try {
            final r = await widget.api.analyzeBatch(chunk);
            consecutiveFailures = 0;
            _results.addAll(r.results);
            _failed += r.failedCount;
            _skipped += r.skipped;
          } catch (_) {
            consecutiveFailures++;
            _failed += chunk.length;
            if (consecutiveFailures >= 3) {
              throw ApiException('توقف التحليل بسبب أخطاء متكررة في الاتصال');
            }
          }
          if (!mounted) return;
          setState(() => _processed = i + chunk.length);
        }
      }
      if (!mounted) return;
      setState(() => _phase = _Phase.done);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException ? e.message : 'حدث خطأ غير متوقع';
        _phase = _results.isEmpty ? _Phase.ready : _Phase.done;
      });
    }
  }

  void _reset() {
    setState(() {
      _name = null;
      _bytes = null;
      _phase = _Phase.idle;
      _error = null;
      _results.clear();
      _processed = _total = _failed = _skipped = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ContentScroll(
      children: [
        const PageHeader(
          icon: Icons.upload_file,
          title: 'تحليل ملف تقييمات',
          subtitle: 'ارفع ملف CSV أو TXT أو Excel فيه تقييمات النزلاء ونعطيك تقريراً كاملاً',
        ),
        _dropZone(context),
        if (_error != null) ...[
          const SizedBox(height: 14),
          InlineError(_error!),
        ],
        if (_phase == _Phase.ready) ...[
          const SizedBox(height: 16),
          _fileCard(),
        ],
        if (_phase == _Phase.running) ...[
          const SizedBox(height: 16),
          _progressCard(),
        ],
        if (_phase == _Phase.done) ...[
          const SizedBox(height: 16),
          _fileCard(finished: true),
          const SizedBox(height: 24),
          _summary(),
          const SizedBox(height: 24),/*
          AspectInsights(
            stats: computeAspectStats(_results.where((r) => hasArabic(r.text))),
            subtitle: 'مبني على التقييمات العربية داخل هذا الملف',
          ),*/
          const SizedBox(height: 24),
          _resultsList(),
        ],
      ],
    );
  }

  Widget _dropZone(BuildContext context) {
    final busy = _phase == _Phase.running;
    return DropTarget(
      enable: !busy,
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (d) async {
        if (d.files.isEmpty) {
          setState(() => _dragging = false);
          return;
        }
        final f = d.files.first;
        final bytes = await f.readAsBytes();
        if (!mounted) return;
        _setFile(f.name, bytes);
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: busy ? null : _pick,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 20),
          decoration: BoxDecoration(
            color: _dragging ? Palette.skySoft : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _dragging ? Palette.skyBright : const Color(0xFFA9D8F5),
              width: _dragging ? 2.5 : 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                    color: Palette.skySoft, shape: BoxShape.circle),
                child: const Icon(Icons.cloud_upload_outlined,
                    size: 34, color: Palette.sky),
              ),
              const SizedBox(height: 14),
              Text(
                'اسحب الملف وأفلته هنا، أو اضغط للاختيار',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileCard({bool finished = false}) {
    final size = _bytes == null ? 0 : _bytes!.length;
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: Palette.sky),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_name ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '${(size / 1024).toStringAsFixed(1)} كيلوبايت',
                  style: const TextStyle(color: Palette.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          if (!finished)
            FilledButton.icon(
              onPressed: _start,
              icon: const Icon(Icons.play_arrow),
              label: const Text('ابدأ التحليل'),
            ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'إزالة الملف',
            onPressed: _reset,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _progressCard() {
    final indeterminate = _isSheet || _total == 0;
    final value = indeterminate ? null : _processed / _total;
    return Panel(
      title: 'جارٍ تحليل التقييمات...',
      trailing: _isSheet
          ? null
          : TextButton(
              onPressed: _cancel ? null : () => setState(() => _cancel = true),
              child: Text(_cancel ? 'جارٍ الإيقاف...' : 'إيقاف'),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: value, minHeight: 12),
          ),
          const SizedBox(height: 10),
          Text(
            indeterminate
                ? 'يعالج الخادم الملف بالكامل، قد يستغرق ذلك بعض الوقت...'
                : 'تم تحليل $_processed من $_total تقييم',
            style: const TextStyle(color: Palette.muted),
          ),
        ],
      ),
    );
  }

  Widget _summary() {
    final pos = _results.where((r) => r.isPositive).length;
    final neg = _results.where((r) => r.isNegative).length;
    final analyzed = pos + neg;
    final satisfaction = analyzed == 0 ? 0.0 : pos * 100 / analyzed;
    return Panel(
      title: 'ملخص التقرير',
      subtitle: 'نتيجة تحليل الملف',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveGrid(
            minItemWidth: 170,
            spacing: 12,
            children: [
              _Mini('تقييمات تم تحليلها', formatInt(analyzed), Palette.sky),
              _Mini('إيجابية', formatInt(pos), Palette.positive),
              _Mini('سلبية', formatInt(neg), Palette.negative),
              _Mini('لم تُحلَّل', formatInt(_failed + _skipped), Palette.muted),
            ],
          ),
          if (analyzed > 0) ...[
            const SizedBox(height: 22),
            SplitBar(positive: pos.toDouble(), negative: neg.toDouble()),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('رضا النزلاء ${formatPercentRaw(satisfaction)}',
                    style: const TextStyle(
                        color: Palette.positiveDark, fontWeight: FontWeight.w700)),
                Text('عدم رضا ${formatPercentRaw(100 - satisfaction)}',
                    style: const TextStyle(
                        color: Palette.negativeDark, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _resultsList() {
    final shown = _results.take(50).toList();
    return Panel(
      title: _results.length > 50
          ? 'أول 50 تقييم من ${formatInt(_results.length)}'
          : 'التقييمات',
      child: shown.isEmpty
          ? const EmptyState('لا توجد نتائج')
          : Column(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Palette.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SentimentBadge(shown[i].label),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            shown[i].text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tint(color, 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Palette.muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

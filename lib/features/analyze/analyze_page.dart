import 'package:flutter/material.dart';

import '../../core/aspects.dart';
import '../../core/brand.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/sentiment_api.dart';
import '../../shared/hotel_art.dart';
import '../../shared/widgets.dart';

const _examples = [
  'الفندق نظيف جداً والموظفين محترمين والموقع ممتاز',
  'الغرفة كانت وسخة والاستقبال تعامل معنا بشكل سيء',
  'الإفطار رائع والمسبح جميل بس الواي فاي ضعيف',
];

class AnalyzePage extends StatefulWidget {
  const AnalyzePage({super.key, required this.api});

  final SentimentApi api;

  @override
  State<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends State<AnalyzePage> {
  final TextEditingController _c = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _loading = false;
  String? _error;
  SentimentLog? _result;
  List<Aspect> _aspects = const [];

  @override
  void dispose() {
    _scroll.dispose();
    _c.dispose();
    super.dispose();
  }

  String? _validate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 'اكتب تقييم النزيل أولاً';
    final arabic = RegExp(r'[\u0600-\u06FF]').allMatches(text).length;
    final latin = RegExp(r'[A-Za-z]').allMatches(text).length;
    if (arabic < 3 || latin > arabic) {
      return 'الرجاء كتابة التقييم باللغة العربية';
    }
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (words < 2) return 'اكتب جملة كاملة عن تجربة النزيل في الفندق';
    return null;
  }

  Future<void> _run() async {
    final problem = _validate(_c.text);
    if (problem != null) {
      setState(() {
        _error = problem;
        _result = null;
      });
      return;
    }
    final text = _c.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await widget.api.analyze(text);
      if (!mounted) return;
      setState(() {
        _result = r;
        _aspects = detectAspects(text);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _error = e is ApiException ? e.message : 'حدث خطأ غير متوقع');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentScroll(
      controller: _scroll,
      children: [
        const PageHeader(
          icon: Icons.edit_note,
          title: 'تحليل تقييم نزيل',
        ),
        LayoutBuilder(
          builder: (context, cons) {
            final form = _formPanel();
            if (cons.maxWidth < 900) {
              return Column(
                children: [
                  const _PhotoCard(height: 190, alignment: Alignment(0.3, -0.2)),
                  const SizedBox(height: 20),
                  form,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: form),
                const SizedBox(width: 24),
                const Expanded(
                  flex: 2,
                  child: _PhotoCard(height: 470, alignment: Alignment(0.44, 0)),
                ),
              ],
            );
          },
        ),
        if (_result != null) ...[
          const SizedBox(height: 24),
          _Verdict(result: _result!, aspects: _aspects),
        ],
      ],
    );
  }

  Widget _formPanel() {
    return Panel(
      title: 'نص التقييم',
      subtitle: 'اكتب أو الصق تقييماً باللغة العربية عن تجربة النزيل في فندقك',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _c,
            minLines: 5,
            maxLines: 9,
            textDirection: TextDirection.rtl,
            style: const TextStyle(height: 1.7),
            decoration: InputDecoration(
              hintText: 'مثال: الغرفة نظيفة والموظفين رائعين والموقع ممتاز...',
              filled: true,
              fillColor: Palette.bg,
              contentPadding: const EdgeInsets.all(18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Palette.skyBright, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('جرّب مثالاً:',
              style: TextStyle(color: Palette.muted, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _examples)
                ActionChip(
                  backgroundColor: Palette.skySoft,
                  side: BorderSide.none,
                  label: Text(e,
                      style: const TextStyle(fontSize: 12, color: Palette.skyDark)),
                  onPressed: _loading
                      ? null
                      : () => setState(() {
                            _c.text = e;
                            _error = null;
                          }),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              FilledButton.icon(
                onPressed: _loading ? null : _run,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.fact_check_outlined),
                label: Text(_loading ? 'جارٍ التحليل...' : 'حلّل التقييم'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                          _c.clear();
                          _result = null;
                          _aspects = const [];
                          _error = null;
                        }),
                child: const Text('مسح'),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            InlineError(_error!),
          ],
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.height, required this.alignment});

  final double height;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AssetPhoto(path: AppImages.analyze, alignment: alignment),
      ),
    );
  }
}

class _Verdict extends StatelessWidget {
  const _Verdict({required this.result, required this.aspects});

  final SentimentLog result;
  final List<Aspect> aspects;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final positive = result.isPositive;
    final color = positive ? Palette.positive : Palette.negative;
    final textColor = positive ? Palette.positiveDark : Palette.negativeDark;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tint(color, 0.09),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(
                    positive
                        ? Icons.sentiment_very_satisfied_rounded
                        : Icons.sentiment_very_dissatisfied_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        positive ? 'تقييم إيجابي' : 'تقييم سلبي',
                        style: t.headlineSmall
                            ?.copyWith(color: textColor, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        positive
                            ? 'النزيل راضٍ عن تجربته في الفندق'
                            : 'النزيل غير راضٍ، راجع الملاحظات التي ذكرها',
                        style: t.bodyMedium?.copyWith(color: Palette.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('الجوانب التي ذكرها النزيل',
              style: t.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (aspects.isEmpty)
            const Text(
              'لم نجد في النص ذكراً لجانب محدد من الفندق (نظافة، موظفين، موقع...). '
              'تأكد أن النص تقييم يخص الفندق.',
              style: TextStyle(color: Palette.muted),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final a in aspects) AspectChip(a)],
            ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: Palette.muted),
              SizedBox(width: 6),
              Text('تم حفظ التقييم في السجل',
                  style: TextStyle(color: Palette.muted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

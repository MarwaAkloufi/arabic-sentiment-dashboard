import 'package:flutter/material.dart';

import '../core/aspects.dart';
import '../core/format.dart';
import '../core/theme.dart';

class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.border),
        boxShadow: [
          BoxShadow(
            color: tint(Palette.skyDark, 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title!,
                            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        if (subtitle != null) ...[
                          const SizedBox(height: 3),
                          Text(subtitle!,
                              style: t.bodySmall?.copyWith(color: Palette.muted)),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// عنوان صفحة بسيط وواضح.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Palette.skySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Palette.sky, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: t.bodyMedium?.copyWith(color: Palette.muted)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// صفحة قابلة للتمرير بعرض أقصى مريح للقراءة.
class ContentScroll extends StatelessWidget {
  const ContentScroll({super.key, required this.children, this.controller});

  final List<Widget> children;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        final pad = cons.maxWidth < 600 ? 16.0 : 32.0;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: ListView(
              controller: controller,
              padding: EdgeInsets.all(pad),
              children: children,
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 230,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        final w = cons.maxWidth;
        final cols = (w / (minItemWidth + spacing))
            .floor()
            .clamp(1, children.length)
            .toInt();
        final itemW = (w - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final c in children) SizedBox(width: itemW, child: c),
          ],
        );
      },
    );
  }
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.label,
    required this.value,
    this.note,
  });

  final IconData icon;
  final Color color;
  final Color textColor;
  final String label;
  final String value;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Panel(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: tint(color, 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodyMedium?.copyWith(color: Palette.muted)),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(value,
                        style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    if (note != null) ...[
                      const SizedBox(width: 8),
                      Text(note!,
                          style: t.bodyMedium?.copyWith(
                              color: textColor, fontWeight: FontWeight.w700)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SentimentBadge extends StatelessWidget {
  const SentimentBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isPos = label == 'pos';
    final fill = isPos
        ? Palette.positive
        : (label == 'neg' ? Palette.negative : Palette.muted);
    final text = isPos
        ? Palette.positiveDark
        : (label == 'neg' ? Palette.negativeDark : Palette.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: tint(fill, 0.13),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPos ? Icons.thumb_up_alt_rounded : Icons.thumb_down_alt_rounded,
            size: 14,
            color: text,
          ),
          const SizedBox(width: 6),
          Text(
            labelAr(label),
            style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(this.message, {super.key, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 38, color: Palette.muted),
            const SizedBox(height: 10),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Palette.muted)),
          ],
        ),
      ),
    );
  }
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Panel(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 42, color: Palette.negative),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 6),
              const Text(
                'أول طلب بعد فترة توقف قد يستغرق بضع ثوانٍ.',
                style: TextStyle(color: Palette.muted, fontSize: 12),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InlineError extends StatelessWidget {
  const InlineError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint(Palette.negative, 0.09),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Palette.negativeDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(color: Palette.negativeDark)),
          ),
        ],
      ),
    );
  }
}

/// شريط يقسم المساحة بين نسبة إيجابي ونسبة سلبي.
class SplitBar extends StatelessWidget {
  const SplitBar({super.key, required this.positive, required this.negative});

  final double positive;
  final double negative;

  @override
  Widget build(BuildContext context) {
    final total = positive + negative;
    final frac = total > 0 ? positive / total : 0.5;
    return LayoutBuilder(
      builder: (context, cons) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Container(width: cons.maxWidth * frac, height: 12, color: Palette.positive),
              Expanded(child: Container(height: 12, color: Palette.negative)),
            ],
          ),
        );
      },
    );
  }
}

class AspectChip extends StatelessWidget {
  const AspectChip(this.aspect, {super.key});

  final Aspect aspect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Palette.skySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(aspect.icon, size: 16, color: Palette.skyDark),
          const SizedBox(width: 6),
          Text(aspect.name,
              style: const TextStyle(
                  color: Palette.skyDark, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }
}

/// ماذا يقول النزلاء عن كل جانب من الفندق: أولى نقطة للتحسين، أقوى نقطة،
/// ثم قائمة بكل الجوانب مع عدد الإشارات الإيجابية والسلبية.
class AspectInsights extends StatelessWidget {
  const AspectInsights({
    super.key,
    required this.stats,
    required this.subtitle,
  });

  final List<AspectStat> stats;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final used = stats.where((s) => s.total > 0).toList()
      ..sort((a, b) => b.total.compareTo(a.total));
    final ranked = used.where((s) => s.total >= 2).toList();

    final weakList = ranked.where((s) => s.neg > 0).toList()
      ..sort((a, b) {
        final c = b.neg.compareTo(a.neg);
        return c != 0 ? c : a.satisfaction.compareTo(b.satisfaction);
      });
    final strongList = ranked.where((s) => s.pos > 0).toList()
      ..sort((a, b) {
        final c = b.pos.compareTo(a.pos);
        return c != 0 ? c : b.satisfaction.compareTo(a.satisfaction);
      });
    final weak = weakList.isEmpty ? null : weakList.first;
    final strong = strongList.isEmpty ? null : strongList.first;

    return Panel(
      title: 'ماذا يقول النزلاء عن فندقك؟',
      subtitle: subtitle,
      child: used.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'لم نجد بعد تقييمات عربية تذكر جوانب الفندق (نظافة، موظفين، موقع...).\n'
                  'حلّل المزيد من التقييمات لتظهر هنا ملاحظات واضحة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Palette.muted, height: 1.7),
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, cons) {
                    final weakCard = _Callout(
                      fill: Palette.negative,
                      dark: Palette.negativeDark,
                      icon: weak?.aspect.icon ?? Icons.check_circle_outline,
                      label: 'أولى نقطة للتحسين',
                      title: weak?.aspect.name ?? 'لا توجد شكاوى متكررة',
                      detail: weak == null
                          ? 'لم يتكرر ذكر أي جانب بشكل سلبي حتى الآن'
                          : '${weak.neg} من ${weak.total} تقييم ذكر هذا الجانب بشكل سلبي',
                      example: weak?.negExample,
                    );
                    final strongCard = _Callout(
                      fill: Palette.positive,
                      dark: Palette.positiveDark,
                      icon: strong?.aspect.icon ?? Icons.hourglass_empty,
                      label: 'أقوى نقطة في فندقك',
                      title: strong?.aspect.name ?? 'لا توجد إشادات متكررة',
                      detail: strong == null
                          ? 'لم يتكرر ذكر أي جانب بشكل إيجابي حتى الآن'
                          : '${strong.pos} من ${strong.total} تقييم ذكر هذا الجانب بشكل إيجابي',
                      example: strong?.posExample,
                    );
                    if (cons.maxWidth >= 720) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: weakCard),
                          const SizedBox(width: 16),
                          Expanded(child: strongCard),
                        ],
                      );
                    }
                    return Column(
                      children: [weakCard, const SizedBox(height: 12), strongCard],
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: Text('كل الجوانب المذكورة',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const _Dot(color: Palette.positive, label: 'إيجابي'),
                    const SizedBox(width: 14),
                    const _Dot(color: Palette.negative, label: 'سلبي'),
                  ],
                ),
                const SizedBox(height: 6),
                for (final s in used.take(8)) _AspectRow(stat: s),
              ],
            ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Palette.muted, fontSize: 12)),
      ],
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({
    required this.fill,
    required this.dark,
    required this.icon,
    required this.label,
    required this.title,
    required this.detail,
    required this.example,
  });

  final Color fill;
  final Color dark;
  final IconData icon;
  final String label;
  final String title;
  final String detail;
  final String? example;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tint(fill, 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tint(fill, 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodySmall?.copyWith(color: Palette.muted)),
                const SizedBox(height: 2),
                Text(title,
                    style: t.titleLarge?.copyWith(color: dark, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(detail, style: t.bodyMedium),
                if (example != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '«$example»',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(color: Palette.muted, height: 1.6),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AspectRow extends StatelessWidget {
  const _AspectRow({required this.stat});

  final AspectStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Palette.skySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stat.aspect.icon, size: 21, color: Palette.sky),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(stat.aspect.name,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    Text('ذُكر ${stat.total} مرة',
                        style: const TextStyle(color: Palette.muted, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: SizedBox(
                    height: 10,
                    child: Row(
                      children: [
                        if (stat.pos > 0)
                          Expanded(
                            flex: stat.pos,
                            child: const ColoredBox(color: Palette.positive),
                          ),
                        if (stat.neg > 0)
                          Expanded(
                            flex: stat.neg,
                            child: const ColoredBox(color: Palette.negative),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text('إيجابي ${stat.pos}',
                        style: const TextStyle(
                            color: Palette.positiveDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('سلبي ${stat.neg}',
                        style: const TextStyle(
                            color: Palette.negativeDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

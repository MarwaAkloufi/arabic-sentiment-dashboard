import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../shared/hotel_art.dart';
import '../../shared/widgets.dart';
import 'overview_controller.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    super.key,
    required this.controller,
    required this.onAnalyze,
    required this.onUpload,
    required this.onShowAll,
  });

  final OverviewController controller;
  final VoidCallback onAnalyze;
  final VoidCallback onUpload;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ContentScroll(
          children: [
            PageHeader(
              icon: Icons.space_dashboard,
              title: 'لوحة التحكم',
              subtitle: 'آخر ما قاله نزلاء فندقك',
            ),
            OverviewHero(onAnalyze: onAnalyze, onUpload: onUpload),
            const SizedBox(height: 28),
            if (controller.loading && controller.loaded)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (!controller.loaded && controller.loading)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (!controller.loaded && controller.error != null)
              ErrorView(message: controller.error!, onRetry: controller.load)
            else if (controller.loaded) ...[
              if (controller.error != null) ...[
                InlineError('تعذّر التحديث: ${controller.error}'),
                const SizedBox(height: 16),
              ],
              _recentPanel(context),
            ],
          ],
        );
      },
    );
  }

  Widget _recentPanel(BuildContext context) {
    final rows = controller.recent;
    return Panel(
      title: 'آخر التقييمات',
      subtitle: 'أحدث ما تم تحليله',
      trailing: rows.isEmpty
          ? null
          : TextButton.icon(
              onPressed: onShowAll,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text('عرض الكل (${formatInt(controller.total)})'),
            ),
      child: rows.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.rate_review_outlined, size: 44, color: Palette.sky),
                    const SizedBox(height: 12),
                    const Text('لا توجد تقييمات بعد',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    const SizedBox(height: 4),
                    const Text('ابدأ بتحليل أول تقييم لأحد نزلائك',
                        style: TextStyle(color: Palette.muted)),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: onAnalyze,
                      icon: const Icon(Icons.edit_note),
                      label: const Text('تحليل تقييم الآن'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: Palette.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SentimentBadge(rows[i].label),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            rows[i].text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(height: 1.6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          formatDateTime(rows[i].createdAt),
                          style: const TextStyle(color: Palette.muted, fontSize: 12),
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

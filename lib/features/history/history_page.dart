import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/aspects.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../shared/widgets.dart';
import 'history_controller.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, required this.controller});

  final HistoryController controller;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;

  HistoryController get c => widget.controller;

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => c.setSearch(v));
    setState(() {});
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(body, style: const TextStyle(height: 1.7)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Palette.negative),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _deleteOne(SentimentLog r) async {
    final id = r.id;
    if (id == null) return;
    final ok = await _confirm(
      title: 'حذف التقييم',
      body: 'سيتم حذف هذا التقييم نهائياً من السجل.',
      action: 'حذف',
    );
    if (!ok) return;
    final err = await c.deleteOne(id);
    if (!mounted) return;
    _toast(err ?? 'تم حذف التقييم');
  }

  Future<void> _deleteAll() async {
    final total = c.page?.total ?? 0;
    final ok = await _confirm(
      title: 'حذف كل السجل',
      body: 'سيتم حذف جميع التقييمات ($total تقييم) نهائياً، ولا يمكن التراجع عن ذلك.',
      action: 'حذف الكل',
    );
    if (!ok) return;
    final err = await c.deleteAll();
    if (!mounted) return;
    _toast(err ?? 'تم حذف كل السجل');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final p = c.page;
        final hasRows = (p?.total ?? 0) > 0;
        return ContentScroll(
          children: [
            PageHeader(
              icon: Icons.history,
              title: 'سجل التقييمات',
              subtitle: 'كل تقييمات النزلاء التي تم تحليلها',
              trailing: (AppConfig.allowDelete && hasRows)
                  ? OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Palette.negativeDark,
                        side: const BorderSide(color: Palette.negative, width: 1.3),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                      onPressed: c.loading ? null : _deleteAll,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('حذف كل السجل'),
                    )
                  : null,
            ),
            _filters(),
            const SizedBox(height: 18),
            if (c.loading && p != null)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (p == null && c.loading)
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (p == null && c.error != null)
              ErrorView(message: c.error!, onRetry: c.load)
            else if (p != null) ...[
              if (c.error != null) ...[
                InlineError('تعذّر التحديث: ${c.error}'),
                const SizedBox(height: 12),
              ],
              _table(context),
              const SizedBox(height: 16),
              _footer(p),
            ],
          ],
        );
      },
    );
  }

  Widget _filters() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 340,
          child: TextField(
            controller: _search,
            onChanged: _onSearchChanged,
            onSubmitted: c.setSearch,
            decoration: InputDecoration(
              hintText: 'ابحث داخل التقييمات...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _search.clear();
                        c.setSearch('');
                        setState(() {});
                      },
                    ),
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
        ),
        _FilterPill(
          label: 'الكل',
          icon: Icons.apps_rounded,
          fill: Palette.sky,
          dark: Palette.skyDark,
          selected: c.label == null,
          onTap: () => c.setLabel(null),
        ),
        _FilterPill(
          label: 'الإيجابية',
          icon: Icons.thumb_up_alt_rounded,
          fill: Palette.positive,
          dark: Palette.positiveDark,
          selected: c.label == 'pos',
          onTap: () => c.setLabel('pos'),
        ),
        _FilterPill(
          label: 'السلبية',
          icon: Icons.thumb_down_alt_rounded,
          fill: Palette.negative,
          dark: Palette.negativeDark,
          selected: c.label == 'neg',
          onTap: () => c.setLabel('neg'),
        ),
      ],
    );
  }

  Widget _table(BuildContext context) {
    final rows = c.rows;
    if (rows.isEmpty) {
      return const Panel(child: EmptyState('لا توجد تقييمات مطابقة'));
    }
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, cons) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: cons.maxWidth),
              child: DataTable(
                sortColumnIndex: c.sortColumn,
                sortAscending: c.sortAscending,
                showCheckboxColumn: false,
                columnSpacing: 28,
                headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w800, color: Palette.skyDark),
                dataRowMinHeight: 60,
                dataRowMaxHeight: 80,
                columns: [
                  const DataColumn(label: Text('نص التقييم')),
                  DataColumn(
                    label: const Text('التقييم'),
                    onSort: (i, asc) => c.sortBy(i, asc),
                  ),
                  DataColumn(
                    label: const Text('التاريخ'),
                    onSort: (i, asc) => c.sortBy(i, asc),
                  ),
                  if (AppConfig.allowDelete) const DataColumn(label: Text('')),
                ],
                rows: [
                  for (final r in rows)
                    DataRow(
                      onSelectChanged: (_) => _showDetails(context, r),
                      cells: [
                        DataCell(
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Text(
                              r.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(height: 1.5),
                            ),
                          ),
                        ),
                        DataCell(SentimentBadge(r.label)),
                        DataCell(Text(
                          formatDateTime(r.createdAt),
                          style: const TextStyle(color: Palette.muted),
                        )),
                        if (AppConfig.allowDelete)
                          DataCell(
                            IconButton(
                              tooltip: 'حذف',
                              icon: const Icon(Icons.delete_outline,
                                  color: Palette.negativeDark),
                              onPressed: () => _deleteOne(r),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _footer(PagedLogs p) {
    final pages = p.pageCount;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Text(
          'الصفحة ${p.page} من $pages · الإجمالي ${formatInt(p.total)} تقييم',
          style: const TextStyle(color: Palette.muted),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('عدد الصفوف: '),
            DropdownButton<int>(
              value: c.limit,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 20, child: Text('20')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: (v) {
                if (v != null) c.setLimit(v);
              },
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: c.loading || p.page <= 1 ? null : () => c.goTo(p.page - 1),
              child: const Text('السابق'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed:
                  c.loading || p.page >= pages ? null : () => c.goTo(p.page + 1),
              child: const Text('التالي'),
            ),
          ],
        ),
      ],
    );
  }

  void _showDetails(BuildContext context, SentimentLog r) {
    final aspects = detectAspects(r.text);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            SentimentBadge(r.label),
            const SizedBox(width: 12),
            Text(
              formatDateTime(r.createdAt),
              style: const TextStyle(color: Palette.muted, fontSize: 13),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SelectableText(r.text, style: const TextStyle(height: 1.8)),
                const SizedBox(height: 18),
                const Text('الجوانب المذكورة',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (aspects.isEmpty)
                  const Text('لا يوجد ذكر لجانب محدد من الفندق',
                      style: TextStyle(color: Palette.muted))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [for (final a in aspects) AspectChip(a)],
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }
}

/// زر فلترة بلون خاص: الكل سماوي، الإيجابية خضراء، السلبية حمراء.
class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.fill,
    required this.dark,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color fill;
  final Color dark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? fill : tint(fill, 0.10),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : dark),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

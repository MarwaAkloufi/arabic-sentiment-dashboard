import 'package:flutter/material.dart';

import 'core/brand.dart';
import 'core/theme.dart';
import 'data/sentiment_api.dart';
import 'features/analyze/analyze_page.dart';
import 'features/bulk/bulk_page.dart';
import 'features/history/history_controller.dart';
import 'features/history/history_page.dart';
import 'features/overview/overview_controller.dart';
import 'features/overview/overview_page.dart';

class _Dest {
  const _Dest(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const _destinations = [
  _Dest('الرئيسية', Icons.space_dashboard_outlined, Icons.space_dashboard),
  _Dest('تحليل تقييم', Icons.edit_note_outlined, Icons.edit_note),
  _Dest('تحليل ملف', Icons.upload_file_outlined, Icons.upload_file),
  _Dest('سجل التقييمات', Icons.history_outlined, Icons.history),
];

class Shell extends StatefulWidget {
  const Shell({super.key, required this.api});

  final SentimentApi api;

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late final OverviewController _overview = OverviewController(widget.api);
  late final HistoryController _history = HistoryController(widget.api);
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _overview.load();
  }

  @override
  void dispose() {
    _overview.dispose();
    _history.dispose();
    super.dispose();
  }

  void _select(int i) {
    setState(() => _index = i);
    if (i == 0) _overview.load();
    if (i == 3) _history.load();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      OverviewPage(
        controller: _overview,
        onAnalyze: () => _select(1),
        onUpload: () => _select(2),
        onShowAll: () => _select(3),
      ),
      AnalyzePage(api: widget.api),
      BulkPage(api: widget.api),
      HistoryPage(controller: _history),
    ];
    final body = IndexedStack(index: _index, children: pages);

    return LayoutBuilder(
      builder: (context, cons) {
        if (cons.maxWidth >= 960) {
          return Scaffold(
            body: Row(
              children: [
                _Sidebar(index: _index, onSelect: _select),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            title: const Row(
              children: [
                _Logo(size: 36),
                SizedBox(width: 10),
                Text(Brand.name,
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: Palette.skyDark)),
              ],
            ),
          ),
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _select,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon, color: Palette.sky),
                  label: d.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Palette.sky,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(Icons.apartment_rounded, color: Colors.white, size: size * 0.6),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.index, required this.onSelect});

  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Palette.border)),
      ),
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              children: [
                _Logo(size: 48),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(Brand.name,
                          style: TextStyle(
                              color: Palette.ink,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: 1.1)),
                      SizedBox(height: 2),
                      Text('تحليل آراء النزلاء',
                          style: TextStyle(color: Palette.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
          for (var i = 0; i < _destinations.length; i++)
            _NavItem(
              dest: _destinations[i],
              selected: i == index,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.dest, required this.selected, required this.onTap});

  final _Dest dest;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : Palette.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? Palette.sky : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          hoverColor: Palette.skySoft,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(selected ? dest.selectedIcon : dest.icon,
                    color: selected ? Colors.white : Palette.muted, size: 22),
                const SizedBox(width: 14),
                Text(
                  dest.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

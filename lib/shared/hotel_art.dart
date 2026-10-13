import 'package:flutter/material.dart';

import '../core/brand.dart';
import '../core/theme.dart';

class AssetPhoto extends StatelessWidget {
  const AssetPhoto({super.key, required this.path, this.alignment = Alignment.center});

  final String path;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: BoxFit.cover,
      alignment: alignment,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stack) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF27AEF5), Color(0xFF0A7BD0)],
          ),
        ),
      ),
    );
  }
}

class OverviewHero extends StatelessWidget {
  const OverviewHero({super.key, required this.onAnalyze, required this.onUpload});

  final VoidCallback onAnalyze;
  final VoidCallback onUpload;

  Widget _content({required bool wide}) {
    const shadow = [Shadow(color: Color(0x59000000), blurRadius: 12)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Brand.name,
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 58 : 48,
            fontWeight: FontWeight.w800,
            height: 1.1,
            shadows: shadow,
          ),
        ),
        const SizedBox(height: 28),
        Text(
          Brand.tagline,
          style: TextStyle(
            color: Colors.white,
            fontSize: wide ? 19 : 17,
            fontWeight: FontWeight.w600,
            height: 1.55,
            shadows: shadow,
          ),
        ),
        const SizedBox(height: 42),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Palette.sky,
              ),
              onPressed: onAnalyze,
              icon: const Icon(Icons.edit_note),
              label: const Text('تحليل تقييم جديد'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xD9FFFFFF), width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
              onPressed: onUpload,
              icon: const Icon(Icons.upload_file),
              label: const Text('رفع ملف تقييمات'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, cons) {
        final wide = cons.maxWidth >= 760;

        if (wide) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 420,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const AssetPhoto(path: AppImages.home, alignment: Alignment(0, -0.56)),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        stops: [0.0, 0.30, 0.58, 1.0],
                        colors: [
                          Color(0x00042442),
                          Color(0x00042442),
                          Color(0x85042442),
                          Color(0xCC042442),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(44),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SizedBox(width: 400, child: _content(wide: true)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              const SizedBox(
                height: 230,
                width: double.infinity,
                child: AssetPhoto(path: AppImages.home, alignment: Alignment(-0.3, -0.4)),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [Color(0xFF0B93EA), Color(0xFF0A7BD0)],
                  ),
                ),
                child: _content(wide: false),
              ),
            ],
          ),
        );
      },
    );
  }
}

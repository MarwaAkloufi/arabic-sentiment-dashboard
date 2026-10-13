import 'package:flutter/material.dart';

import '../data/models.dart';

class Aspect {
  const Aspect(this.name, this.icon, this.keywords);

  final String name;
  final IconData icon;
  final List<String> keywords;
}

const List<Aspect> kAspects = [
  Aspect('النظافة', Icons.cleaning_services_outlined, [
    'نظافة', 'نظيف', 'نظيفة', 'وسخ', 'وسخة', 'متسخ', 'متسخة', 'اوساخ',
    'قذر', 'قذارة', 'غبار', 'رائحة', 'روائح', 'حشرات', 'صراصير', 'بق',
  ]),
  Aspect('الموظفون والاستقبال', Icons.support_agent_outlined, [
    'موظف', 'موظفين', 'موظفون', 'موظفة', 'استقبال', 'طاقم', 'تعامل',
    'تعاملات', 'كادر', 'عاملين', 'ضيافة', 'ترحيب', 'خدمة العملاء',
  ]),
  Aspect('الموقع', Icons.place_outlined, [
    'موقع', 'قريب', 'بعيد', 'قرب', 'مواصلات', 'وسط', 'محطة',
  ]),
  Aspect('الغرف', Icons.bed_outlined, [
    'غرفة', 'غرف', 'سرير', 'اسرة', 'فراش', 'فرشة', 'مخدة', 'مخدات',
    'وسادة', 'ستائر', 'بطانية', 'شرشف', 'شراشف', 'تلفاز', 'تلفزيون',
    'اطلالة', 'شرفة', 'بلكونة', 'جناح',
  ]),
  Aspect('الحمام والمياه', Icons.bathtub_outlined, [
    'حمام', 'حمامات', 'دش', 'مياه', 'تسريب', 'منشفة', 'مناشف', 'تواليت',
    'ماء حار', 'ماء ساخن',
  ]),
  Aspect('التكييف والتدفئة', Icons.ac_unit, [
    'تكييف', 'مكيف', 'مكيفات', 'تدفئة', 'حرارة', 'برد',
  ]),
  Aspect('الطعام والإفطار', Icons.restaurant_outlined, [
    'فطور', 'افطار', 'بوفيه', 'مطعم', 'اكل', 'طعام', 'وجبات', 'وجبة',
    'قهوة', 'عشاء', 'غداء',
  ]),
  Aspect('الأسعار والقيمة', Icons.payments_outlined, [
    'سعر', 'اسعار', 'غالي', 'غالية', 'رخيص', 'تكلفة', 'قيمة', 'يستاهل',
    'مبالغ', 'فاتورة', 'رسوم',
  ]),
  Aspect('الهدوء والضوضاء', Icons.volume_off_outlined, [
    'ضجيج', 'ازعاج', 'هدوء', 'هادئ', 'هادي', 'ضوضاء', 'صوت', 'اصوات',
  ]),
  Aspect('الإنترنت', Icons.wifi, [
    'انترنت', 'وايفاي', 'wifi', 'واي فاي', 'wi fi',
  ]),
  Aspect('المرافق', Icons.pool_outlined, [
    'مسبح', 'سباحة', 'جيم', 'نادي', 'سبا', 'ساونا', 'جاكوزي', 'مصعد',
    'مصاعد', 'مواقف', 'موقف', 'باركينج', 'ملعب', 'مرافق', 'لوبي',
  ]),
];

/// توحيد الحروف وإزالة التشكيل والرموز لتسهيل المطابقة.
String normalizeAr(String s) {
  var t = s.replaceAll(RegExp(r'[\u0617-\u061A\u064B-\u0652\u0640]'), '');
  t = t
      .replaceAll(RegExp(r'[إأآ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
  t = t.replaceAll(RegExp(r'[^\u0600-\u06FFa-zA-Z0-9\s]'), ' ');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
}

class _Compiled {
  _Compiled(this.aspect, this.tokens, this.phrases);

  final Aspect aspect;
  final Set<String> tokens;
  final List<String> phrases;
}

_Compiled _compile(Aspect a) {
  final tokens = <String>{};
  final phrases = <String>[];
  for (final raw in a.keywords) {
    final k = normalizeAr(raw);
    final isPhrase = k.contains(' ');
    for (final p in const ['', 'ال', 'وال', 'بال', 'لل', 'و', 'ب', 'ل', 'ف']) {
      if (isPhrase) {
        phrases.add('$p$k');
      } else {
        tokens.add('$p$k');
      }
    }
  }
  return _Compiled(a, tokens, phrases);
}

final List<_Compiled> _compiled = [for (final a in kAspects) _compile(a)];

List<Aspect> detectAspects(String text) {
  final n = normalizeAr(text);
  final words = n.split(' ').toSet();
  final padded = ' $n ';
  final found = <Aspect>[];
  for (final c in _compiled) {
    final hit = words.any(c.tokens.contains) ||
        c.phrases.any((p) => padded.contains(' $p '));
    if (hit) found.add(c.aspect);
  }
  return found;
}

class AspectStat {
  AspectStat(this.aspect);

  final Aspect aspect;
  int pos = 0;
  int neg = 0;
  String? posExample;
  String? negExample;

  int get total => pos + neg;
  double get satisfaction => total == 0 ? 0 : pos / total;
}

/// هل في النص حروف عربية كافية ليُعتبر تقييماً عربياً؟
bool hasArabic(String text) =>
    RegExp(r'[\u0600-\u06FF]').allMatches(text).length >= 3;

String _snippet(String text) {
  final s = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  return s.length <= 90 ? s : '${s.substring(0, 90)}…';
}

/// عدد مرات ذكر كل جانب في التقييمات الإيجابية والسلبية.
List<AspectStat> computeAspectStats(Iterable<SentimentLog> logs) {
  final map = {for (final a in kAspects) a.name: AspectStat(a)};
  for (final log in logs) {
    for (final a in detectAspects(log.text)) {
      final s = map[a.name]!;
      if (log.isPositive) {
        s.pos++;
        s.posExample ??= _snippet(log.text);
      } else if (log.isNegative) {
        s.neg++;
        s.negExample ??= _snippet(log.text);
      }
    }
  }
  return map.values.toList();
}

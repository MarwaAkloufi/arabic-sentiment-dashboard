String two(int n) => n.toString().padLeft(2, '0');

String formatDateTime(DateTime? d) {
  if (d == null) return '-';
  return '${d.year}-${two(d.month)}-${two(d.day)}  ${two(d.hour)}:${two(d.minute)}';
}

String formatPercentRaw(double v, {int digits = 0}) =>
    '${v.toStringAsFixed(digits)}%';

String formatInt(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

String labelAr(String label) {
  switch (label) {
    case 'pos':
      return 'إيجابي';
    case 'neg':
      return 'سلبي';
    default:
      return label.isEmpty ? '-' : label;
  }
}

const _weekdays = [
  'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
];
const _months = [
  'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
  'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
];

String formatToday(DateTime d) =>
    '${_weekdays[d.weekday - 1]}، ${d.day} ${_months[d.month - 1]} ${d.year}';

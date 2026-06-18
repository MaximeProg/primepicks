import 'package:intl/intl.dart';

class Fmt {
  static final _date     = DateFormat('dd MMM yyyy', 'fr_FR');
  static final _dateTime = DateFormat('dd MMM yyyy • HH:mm', 'fr_FR');
  static final _time     = DateFormat('HH:mm', 'fr_FR');
  static final _currency = NumberFormat.currency(locale: 'fr_FR', symbol: 'F CFA', decimalDigits: 0);

  static String date(DateTime? d)     => d == null ? '—' : _date.format(d.toLocal());
  static String dateTime(DateTime? d) => d == null ? '—' : _dateTime.format(d.toLocal());
  static String time(DateTime? d)     => d == null ? '—' : _time.format(d.toLocal());
  static String currency(num amount)  => _currency.format(amount);
  static String percent(double v)     => '${v.toStringAsFixed(1)} %';
  static String odds(double? v)       => v == null ? '—' : v.toStringAsFixed(2);

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d.toLocal());
    if (diff.inMinutes < 1)  return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1)    return 'Hier';
    if (diff.inDays < 7)     return 'Il y a ${diff.inDays} jours';
    return date(d);
  }
}

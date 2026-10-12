// ******************* FILE INFO *******************
// File Name: display_format.dart
// Purpose: ONE place for how the admin shows dates, money, durations, work
//          types and phone numbers (BUG-304 / BUG-172 / BUG-157 / BUG-241).
//          Before, the same value was printed three different ways
//          ("09/10/2026" vs "8 Oct 2026" vs "8/10/2026", "45000 – 65000" vs
//          "45000 - 65000", "6 Month", "Remotely", "+200000000000").
// Created by: Amr Mesbah

import 'package:intl/intl.dart';

class DisplayFormat {
  DisplayFormat._();

  static final DateFormat _day = DateFormat('d MMM yyyy');
  static final NumberFormat _int = NumberFormat.decimalPattern('en');

  /// "8 Oct 2026" — the admin's date format everywhere (BUG-304).
  static String date(DateTime? d, {String empty = '—'}) =>
      d == null ? empty : _day.format(d.toLocal());

  /// "45,000" — thousands separators (BUG-304).
  static String number(num n) => _int.format(n);

  /// "45,000 – 65,000 EGP" (en dash, separators, currency) — BUG-304.
  static String salaryRange(num min, num max, String currency,
      {String empty = '—'}) {
    if (min <= 0 && max <= 0) return empty;
    final range = '${number(min)} – ${number(max)}';
    return currency.trim().isEmpty ? range : '$range ${currency.trim()}';
  }

  /// "1 application" / "3 applications" (BUG-280).
  static String plural(int n, String singular, [String? pluralForm]) =>
      '$n ${n == 1 ? singular : (pluralForm ?? '${singular}s')}';

  /// Employment duration: "Open", "1 Month", "12 Months", "6 Weeks",
  /// "2 Years" (BUG-172: was "12 Month"). [unit] is the stored label
  /// (Open / Month / Week / Year, any case, singular or plural).
  static String duration(String count, String unit) {
    final u = unit.trim();
    if (u.toLowerCase() == 'open') return 'Open';
    final n = int.tryParse(count.trim());
    if (u.isEmpty) return count.trim().isEmpty ? '—' : count.trim();
    final base = u.endsWith('s') ? u.substring(0, u.length - 1) : u;
    if (n == null) {
      return [count.trim(), u].where((s) => s.isNotEmpty).join(' ');
    }
    return '$n ${n == 1 ? base : '${base}s'}';
  }

  /// A duration stored as one string ("6 Month", "12 Months", "Open").
  static String durationText(String raw) {
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length == 2) return duration(parts[0], parts[1]);
    if (parts.length == 1 && parts[0].toLowerCase() == 'open') return 'Open';
    return raw.trim().isEmpty ? '—' : raw.trim();
  }

  /// "Remote" (stored value is "Remotely") — BUG-157.
  static String workType(String raw) {
    final v = raw.trim();
    if (v.toLowerCase() == 'remotely' || v.toLowerCase() == 'remote') {
      return 'Remote';
    }
    return v;
  }

  /// "+20 0000000000" — country code and number separated (BUG-241).
  static String phone(String countryCode, String number) {
    final cc = countryCode.trim();
    final n = number.trim();
    if (cc.isEmpty) return n;
    if (n.isEmpty) return cc;
    return '$cc $n';
  }
}

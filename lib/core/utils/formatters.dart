import 'package:intl/intl.dart';

/// Formatting helpers used across the app.
class Formatters {
  Formatters._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static final NumberFormat _decimal = NumberFormat.decimalPattern('id_ID');

  /// Format a Rupiah amount, e.g. `Rp 110.000`.
  static String rupiah(num? value) => _currency.format(value ?? 0);

  /// Format a plain number with thousands separators.
  static String number(num? value) => _decimal.format(value ?? 0);

  /// Parse an ISO timestamp and render `dd MMM yyyy, HH:mm`.
  static String dateTime(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
  }

  /// Render just the time portion `HH:mm`.
  static String time(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    return DateFormat('HH:mm', 'id_ID').format(dt.toLocal());
  }

  /// Render a date string `dd MMM yyyy`.
  static String date(String? value) {
    if (value == null) return '-';
    final dt = DateTime.tryParse(value);
    if (dt == null) return value;
    return DateFormat('dd MMM yyyy', 'id_ID').format(dt.toLocal());
  }

  /// Trim a trailing `:00` off a `HH:mm:ss` shift time.
  static String shiftTime(String? value) {
    if (value == null || value.isEmpty) return '-';
    final parts = value.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return value;
  }
}

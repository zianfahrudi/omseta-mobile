import 'dart:convert';

import '../../../core/utils/formatters.dart';
import '../models/receipt_settings.dart';
import '../models/sale.dart';

/// Builds raw ESC/POS bytes for a thermal receipt from a [Sale] and the
/// company [ReceiptSettings] ("Pengaturan Faktur").
class ReceiptBuilder {
  ReceiptBuilder(this.settings) : width = settings.paperWidth;

  final ReceiptSettings settings;
  final int width;

  final List<int> _b = [];

  // --- ESC/POS commands ---
  static const _esc = 0x1B;
  static const _gs = 0x1D;

  void _init() => _b.addAll([_esc, 0x40]); // ESC @
  void _align(int n) => _b.addAll([_esc, 0x61, n]); // 0 left,1 center,2 right
  void _bold(bool on) => _b.addAll([_esc, 0x45, on ? 1 : 0]);
  void _size(int n) => _b.addAll([_gs, 0x21, n]); // 0 normal, 0x11 double
  void _feed(int n) => _b.addAll([_esc, 0x64, n]); // feed n lines
  void _cut() => _b.addAll([_gs, 0x56, 0x01]); // partial cut

  void _line([String s = '']) {
    _b.addAll(_encode(s));
    _b.add(0x0A);
  }

  /// Thermal printers expect single-byte encoding; keep to ASCII to stay safe.
  List<int> _encode(String s) {
    final ascii = s
        .replaceAll('·', '-')
        .replaceAll('✓', 'v')
        .replaceAll('—', '-')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), '');
    return latin1.encode(ascii);
  }

  String _divider([String ch = '-']) => ch * width;

  /// Left text + right text on one line, right-aligned within [width].
  String _row(String left, String right) {
    if (left.length + right.length >= width) {
      final maxLeft = (width - right.length - 1).clamp(0, width);
      left = left.length > maxLeft ? left.substring(0, maxLeft) : left;
    }
    final space = width - left.length - right.length;
    return left + (' ' * (space < 1 ? 1 : space)) + right;
  }

  List<int> build(Sale sale) {
    _init();

    // Header
    _align(1);
    _bold(true);
    _size(0x11); // double w/h
    _line(settings.name);
    _size(0x00);
    _bold(false);
    if ((settings.address ?? '').isNotEmpty) _line(settings.address!);
    if ((settings.phone ?? '').isNotEmpty) _line('Telp: ${settings.phone}');
    if ((settings.email ?? '').isNotEmpty) _line(settings.email!);

    _align(0);
    _line(_divider());

    // Meta
    _line(_row('No', sale.number));
    if (sale.paidAt != null) _line(_row('Waktu', sale.paidAt!));
    if (sale.cashierName != null) _line(_row('Kasir', sale.cashierName!));
    if (sale.customerName != null) {
      _line(_row('Pelanggan', sale.customerName!));
    }
    if (sale.vehiclePlateNumber != null) {
      _line(_row('Kendaraan', sale.vehiclePlateNumber!));
    }
    _line(_divider());

    // Items
    for (final item in sale.items) {
      _line(item.name);
      _line(
        _row(
          '  ${Formatters.number(item.quantity)} x ${Formatters.number(item.unitPrice)}',
          Formatters.number(item.lineTotal),
        ),
      );
      if (item.employeeName != null) {
        _line('  Petugas: ${item.employeeName}');
      }
    }
    _line(_divider());

    // Totals
    _line(_row('Subtotal', Formatters.number(sale.subtotal)));
    if (sale.discountTotal > 0) {
      _line(_row('Diskon', '-${Formatters.number(sale.discountTotal)}'));
    }
    if (sale.serviceFeeTotal > 0) {
      _line(_row('Biaya layanan', Formatters.number(sale.serviceFeeTotal)));
    }
    if (sale.taxTotal > 0) {
      _line(_row('Pajak', Formatters.number(sale.taxTotal)));
    }
    _bold(true);
    _line(_row('TOTAL', Formatters.number(sale.grandTotal)));
    _bold(false);

    // Payments
    if (sale.payments.length > 1) {
      for (final p in sale.payments) {
        _line(_row(_method(p.method), Formatters.number(p.amount)));
      }
    } else {
      _line(_row('Bayar', Formatters.number(sale.paidAmount)));
    }
    if (sale.changeAmount > 0) {
      _line(_row('Kembali', Formatters.number(sale.changeAmount)));
    }
    if (sale.debtAmount > 0) {
      _line(_row('Utang', Formatters.number(sale.debtAmount)));
    }
    _line(_row('Status', sale.paymentStatusLabel ?? sale.paymentStatus));

    // Bank info (useful for debt / transfer)
    if (settings.hasBank && sale.debtAmount > 0) {
      _line(_divider());
      _line('Pembayaran transfer ke:');
      if ((settings.bankName ?? '').isNotEmpty) _line(settings.bankName!);
      if ((settings.bankAccount ?? '').isNotEmpty) {
        _line('${settings.bankAccount} a/n ${settings.bankHolder ?? ''}');
      }
    }

    _line(_divider());

    // Footer note
    _align(1);
    if ((settings.note ?? '').isNotEmpty) {
      for (final l in settings.note!.split('\n')) {
        _line(l);
      }
    } else {
      _line('Terima kasih');
    }

    _feed(3);
    _cut();
    return _b;
  }

  String _method(String m) {
    switch (m) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'qris':
        return 'QRIS';
      default:
        return m;
    }
  }
}

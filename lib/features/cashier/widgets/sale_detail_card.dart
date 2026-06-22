import 'package:fluent_ui/fluent_ui.dart';

import '../../../core/utils/formatters.dart';
import '../models/sale.dart';

/// Reusable breakdown of a [Sale]: items + totals. Used on the receipt and the
/// transaction detail view.
class SaleDetailCard extends StatelessWidget {
  const SaleDetailCard({super.key, required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).typography;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sale.customerName != null) ...[
            _kv('Pelanggan', sale.customerName!),
            if (sale.vehiclePlateNumber != null)
              _kv('Kendaraan', sale.vehiclePlateNumber!),
            const SizedBox(height: 8),
          ],
          _kv('Metode', sale.paymentMethod.toUpperCase()),
          _kv('Status', sale.paymentStatusLabel ?? sale.paymentStatus),
          if (sale.paidAt != null) _kv('Waktu', sale.paidAt!),
          const Divider(),
          ...sale.items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: typography.body),
                        Text(
                          '${Formatters.rupiah(item.unitPrice)} × ${Formatters.number(item.quantity)}'
                          '${item.refundedQuantity > 0 ? ' · retur ${Formatters.number(item.refundedQuantity)}' : ''}',
                          style: typography.caption,
                        ),
                        if (item.employeeName != null)
                          Text(
                            'Petugas: ${item.employeeName}',
                            style: typography.caption,
                          ),
                      ],
                    ),
                  ),
                  Text(
                    Formatters.rupiah(item.lineTotal),
                    style: typography.body,
                  ),
                ],
              ),
            ),
          ),
          const Divider(),
          _row(context, 'Subtotal', Formatters.rupiah(sale.subtotal)),
          if (sale.discountTotal > 0)
            _row(
              context,
              'Diskon',
              '- ${Formatters.rupiah(sale.discountTotal)}',
            ),
          if (sale.serviceFeeTotal > 0)
            _row(
              context,
              'Biaya layanan',
              Formatters.rupiah(sale.serviceFeeTotal),
            ),
          if (sale.taxTotal > 0)
            _row(context, 'Pajak', Formatters.rupiah(sale.taxTotal)),
          _row(
            context,
            'Total',
            Formatters.rupiah(sale.grandTotal),
            bold: true,
          ),
          _row(context, 'Dibayar', Formatters.rupiah(sale.paidAmount)),
          if (sale.changeAmount > 0)
            _row(context, 'Kembalian', Formatters.rupiah(sale.changeAmount)),
          if (sale.debtAmount > 0)
            _row(context, 'Utang', Formatters.rupiah(sale.debtAmount)),
          if (sale.payments.length > 1) ...[
            const Divider(),
            ...sale.payments.map(
              (p) => _row(
                context,
                '${_methodLabel(p.method)}${p.isSettlement ? ' (pelunasan)' : ''}',
                Formatters.rupiah(p.amount),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Tunai';
      case 'transfer':
        return 'Transfer';
      case 'qris':
        return 'QRIS';
      default:
        return method;
    }
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool bold = false,
  }) {
    final style = bold
        ? FluentTheme.of(context).typography.bodyStrong
        : FluentTheme.of(context).typography.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

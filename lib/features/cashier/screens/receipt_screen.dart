import 'package:fluent_ui/fluent_ui.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/bounded_content.dart';
import '../models/sale.dart';
import '../widgets/sale_detail_card.dart';
import '../widgets/thermal_print_button.dart';

/// Shows the result of a completed checkout (the digital receipt) and lets the
/// cashier print it to a Bluetooth thermal printer.
class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key, required this.sale});

  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).typography;
    return ScaffoldPage(
      header: const PageHeader(title: Text('Struk')),
      content: BoundedContent(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  Icon(
                    sale.isPaid
                        ? FluentIcons.completed_solid
                        : FluentIcons.warning,
                    size: 48,
                    color: sale.isPaid
                        ? Colors.green
                        : Colors.warningPrimaryColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sale.isPaid ? 'Transaksi Berhasil' : 'Transaksi Utang',
                    style: typography.subtitle,
                  ),
                  Text(sale.number, style: typography.caption),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (sale.changeAmount > 0)
              _highlightCard(
                context,
                'Kembalian',
                Formatters.rupiah(sale.changeAmount),
                Colors.green,
              ),
            if (sale.debtAmount > 0)
              _highlightCard(
                context,
                'Sisa utang',
                Formatters.rupiah(sale.debtAmount),
                Colors.red,
              ),
            const SizedBox(height: 8),
            SaleDetailCard(sale: sale),
            const SizedBox(height: 24),
            ThermalPrintButton(sale: sale),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Selesai'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightCard(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Card(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: FluentTheme.of(context).typography.bodyStrong),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

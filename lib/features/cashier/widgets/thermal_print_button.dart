import 'package:fluent_ui/fluent_ui.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/responsive.dart';
import '../../../core/utils/ui_helpers.dart';
import '../models/receipt_settings.dart';
import '../models/sale.dart';
import '../services/cashier_service.dart';
import '../services/receipt_builder.dart';
import '../services/thermal_printer_service.dart';

/// A button that prints a [Sale] to a Bluetooth thermal printer, following the
/// company invoice settings. Renders nothing on unsupported platforms
/// (web/linux). Reused by the receipt and transaction-detail screens.
class ThermalPrintButton extends StatefulWidget {
  const ThermalPrintButton({
    super.key,
    required this.sale,
    this.filled = false,
    this.label = 'Cetak Struk (Thermal)',
  });

  final Sale sale;
  final bool filled;
  final String label;

  @override
  State<ThermalPrintButton> createState() => _ThermalPrintButtonState();
}

class _ThermalPrintButtonState extends State<ThermalPrintButton> {
  final _printer = ThermalPrinterService();
  bool _printing = false;

  Future<void> _print() async {
    setState(() => _printing = true);
    try {
      await _printer.ensureReady();
      final printers = await _printer.pairedPrinters();
      if (printers.isEmpty) {
        if (mounted) {
          UiHelpers.showInfo(
            context,
            'Belum ada printer Bluetooth terpasang. Pasangkan printer thermal dulu.',
          );
        }
        return;
      }
      final lastMac = await _printer.lastPrinterMac();
      if (!mounted) return;
      final selected = await _choosePrinter(printers, lastMac);
      if (selected == null) return;

      final settings =
          await context.read<CashierService>().receiptSettings() ??
          ReceiptSettings.fallback(widget.sale.storeName ?? 'omsetaPOS');
      final bytes = ReceiptBuilder(settings).build(widget.sale);

      await _printer.printBytes(mac: selected.macAdress, bytes: bytes);
      if (mounted) UiHelpers.showSuccess(context, 'Struk dikirim ke printer.');
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<BluetoothInfo?> _choosePrinter(
    List<BluetoothInfo> printers,
    String? lastMac,
  ) {
    return showDialog<BluetoothInfo>(
      context: context,
      builder: (_) => ContentDialog(
        title: const Text('Pilih Printer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: printers.map((p) {
            final isLast = p.macAdress == lastMac;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Button(
                onPressed: () => Navigator.of(context).pop(p),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(FluentIcons.print),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.name),
                            Text(
                              p.macAdress,
                              style: FluentTheme.of(context).typography.caption,
                            ),
                          ],
                        ),
                      ),
                      if (isLast) const Icon(FluentIcons.history, size: 12),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isThermalPrintingSupported) return const SizedBox.shrink();

    final child = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _printing
          ? const SizedBox(
              height: 18,
              width: 18,
              child: ProgressRing(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(FluentIcons.print),
                const SizedBox(width: 8),
                Text(widget.label),
              ],
            ),
    );

    return SizedBox(
      width: double.infinity,
      child: widget.filled
          ? FilledButton(onPressed: _printing ? null : _print, child: child)
          : Button(onPressed: _printing ? null : _print, child: child),
    );
  }
}

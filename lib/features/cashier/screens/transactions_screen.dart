import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_text_box.dart';
import '../../../core/widgets/bounded_content.dart';
import '../models/sale.dart';
import '../providers/cart_provider.dart';
import '../services/cashier_service.dart';
import '../widgets/sale_detail_card.dart';
import '../widgets/thermal_print_button.dart';

/// Lists the cashier's transactions for the active outlet.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Sale> _sales = [];
  bool _loading = false;
  int? _loadedStoreId;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _load(value));
  }

  Future<void> _load([String? query]) async {
    final storeId = context.read<CartProvider>().storeId;
    if (storeId == null) return;
    setState(() => _loading = true);
    try {
      final sales = await context.read<CashierService>().transactions(
        storeId: storeId,
        query: query,
      );
      if (mounted) {
        setState(() {
          _sales = sales;
          _loadedStoreId = storeId;
        });
      }
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openDetail(Sale sale) async {
    await Navigator.of(context).push(
      FluentPageRoute(
        builder: (_) => _TransactionDetailScreen(
          sale: sale,
          onChanged: () => _load(_searchController.text),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeId = context.watch<CartProvider>().storeId;
    if (storeId != null && storeId != _loadedStoreId && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Transaksi'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Muat ulang'),
              onPressed: () => _load(_searchController.text),
            ),
          ],
        ),
      ),
      content: BoundedContent(
        maxWidth: 820,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AppTextBox(
                controller: _searchController,
                placeholder: 'Cari nomor invoice',
                prefixIcon: FluentIcons.search,
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: ProgressRing())
                  : _sales.isEmpty
                  ? const Center(child: Text('Belum ada transaksi.'))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _sales.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final sale = _sales[index];
                        return _SaleTile(
                          sale: sale,
                          onTap: () => _openDetail(sale),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale, required this.onTap});

  final Sale sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Button(
      onPressed: onTap,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(const EdgeInsets.all(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sale.number,
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(
                  '${sale.customerName ?? 'Walk-in'} · ${sale.paidAt ?? ''}',
                  style: FluentTheme.of(context).typography.caption,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Formatters.rupiah(sale.grandTotal),
                style: FluentTheme.of(context).typography.bodyStrong,
              ),
              const SizedBox(height: 4),
              _StatusBadge(sale: sale),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.sale});
  final Sale sale;

  @override
  Widget build(BuildContext context) {
    final paid = sale.isPaid;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: (paid ? Colors.green : Colors.warningPrimaryColor).withValues(
          alpha: 0.15,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        sale.paymentStatusLabel ?? (paid ? 'Lunas' : 'Belum lunas'),
        style: TextStyle(
          fontSize: 11,
          color: paid ? Colors.green.darker : Colors.warningPrimaryColor,
        ),
      ),
    );
  }
}

class _TransactionDetailScreen extends StatefulWidget {
  const _TransactionDetailScreen({required this.sale, required this.onChanged});

  final Sale sale;
  final VoidCallback onChanged;

  @override
  State<_TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<_TransactionDetailScreen> {
  late Sale _sale = widget.sale;
  bool _marking = false;
  bool _voiding = false;

  bool get _isVoid => _sale.status == 'void';

  Future<void> _markPaid() async {
    setState(() => _marking = true);
    try {
      final updated = await context.read<CashierService>().markPaid(_sale.id);
      setState(() => _sale = updated);
      widget.onChanged();
      if (mounted) UiHelpers.showSuccess(context, 'Transaksi dilunasi.');
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _marking = false);
    }
  }

  Future<void> _void() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => ContentDialog(
        title: const Text('Batalkan Transaksi?'),
        content: Text(
          'Transaksi ${_sale.number} akan dibatalkan: stok dikembalikan, '
          'jurnal dibalik, dan utang pelanggan (bila ada) dihapus. '
          'Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.red),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _voiding = true);
    try {
      final updated = await context.read<CashierService>().voidSale(_sale.id);
      setState(() => _sale = updated);
      widget.onChanged();
      if (mounted) UiHelpers.showSuccess(context, 'Transaksi dibatalkan.');
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _voiding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        leading: const AppBackButton(),
        title: Text(_sale.number),
      ),
      content: BoundedContent(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isVoid)
              const InfoBar(
                title: Text('Transaksi dibatalkan'),
                content: Text('Transaksi ini sudah di-void.'),
                severity: InfoBarSeverity.warning,
              ),
            if (_isVoid) const SizedBox(height: 12),
            SaleDetailCard(sale: _sale),
            const SizedBox(height: 16),
            ThermalPrintButton(sale: _sale, label: 'Cetak Struk'),
            if (!_sale.isPaid && !_isVoid) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _marking ? null : _markPaid,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _marking
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: ProgressRing(strokeWidth: 2),
                          )
                        : const Text('Tandai Lunas'),
                  ),
                ),
              ),
            ],
            if (!_isVoid) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Button(
                  onPressed: _voiding ? null : _void,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: _voiding
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: ProgressRing(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(FluentIcons.cancel, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(
                                'Void / Batalkan Transaksi',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

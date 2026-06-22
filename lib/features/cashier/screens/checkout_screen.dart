import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_text_box.dart';
import '../../../core/widgets/bounded_content.dart';
import '../models/pricing.dart';
import '../providers/cart_provider.dart';
import '../services/cashier_service.dart';
import 'receipt_screen.dart';

/// Available tender methods.
const _methodLabels = {'cash': 'Tunai', 'transfer': 'Transfer', 'qris': 'QRIS'};

/// Quick cash denominations for fast exact-amount entry.
const _denominations = [10000, 20000, 50000, 100000, 500000, 1000000];

/// A single tender row in the (possibly combined) payment.
class _PayRow {
  _PayRow({this.method = 'cash'});
  String method;
  final controller = TextEditingController();
}

/// Collects payment details (single or combined) and submits the checkout.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final List<_PayRow> _rows = [_PayRow()];
  bool _isDebt = false;
  bool _submitting = false;

  Pricing? _pricing;
  bool _loadingTotal = true;
  num _subtotal = 0;

  @override
  void initState() {
    super.initState();
    _subtotal = context.read<CartProvider>().subtotal;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPricing());
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.controller.dispose();
    }
    super.dispose();
  }

  num get _grandTotal => _pricing?.grandTotal ?? _subtotal;

  num _rowAmount(_PayRow r) {
    final digits = r.controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  /// Tender lines that actually have an amount.
  List<PaymentEntry> get _activePayments => _rows
      .where((r) => _rowAmount(r) > 0)
      .map((r) => PaymentEntry(method: r.method, amount: _rowAmount(r)))
      .toList();

  num get _tender => _activePayments.fold<num>(0, (sum, p) => sum + p.amount);

  /// `split` when more than one method is used; otherwise the single method.
  String get _effectiveMethod {
    final active = _activePayments;
    if (active.length > 1) return 'split';
    if (active.isNotEmpty) return active.first.method;
    return _rows.first.method;
  }

  Future<void> _loadPricing() async {
    final cart = context.read<CartProvider>();
    if (cart.storeId == null || cart.isEmpty) {
      setState(() => _loadingTotal = false);
      return;
    }
    setState(() => _loadingTotal = true);
    try {
      final pricing = await context.read<CashierService>().pricing(
        storeId: cart.storeId!,
        subtotal: cart.subtotal,
        discountCode: cart.discountCode,
      );
      if (!mounted) return;
      setState(() {
        _pricing = pricing;
        _subtotal = cart.subtotal;
      });
      cart.setPricing(pricing);
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _loadingTotal = false);
    }
  }

  void _addRow() => setState(() => _rows.add(_PayRow(method: 'transfer')));

  void _removeRow(int index) {
    setState(() {
      _rows[index].controller.dispose();
      _rows.removeAt(index);
      if (_rows.isEmpty) _rows.add(_PayRow());
    });
  }

  /// Fill the first row with the exact remaining total (uang pas).
  void _payExact() {
    setState(() {
      _rows.first.controller.text = '${_grandTotal.round()}';
    });
  }

  /// Add a quick cash denomination to the first (cash) row.
  void _addDenomination(int value) {
    final row = _rows.first;
    final current = _rowAmount(row);
    setState(() {
      row.controller.text = '${(current + value).round()}';
    });
  }

  /// Clear all entered tender amounts.
  void _clearAmounts() {
    setState(() {
      for (final r in _rows) {
        r.controller.clear();
      }
    });
  }

  Future<void> _submit() async {
    final cart = context.read<CartProvider>();
    if (cart.storeId == null || cart.isEmpty) return;

    if (_loadingTotal) {
      UiHelpers.showInfo(context, 'Sedang menghitung total, tunggu sebentar.');
      return;
    }

    final method = _effectiveMethod;
    final payments = _activePayments;

    if (!_isDebt && _tender < _grandTotal) {
      UiHelpers.showInfo(
        context,
        'Jumlah bayar kurang dari total. Aktifkan "Transaksi utang" bila ingin bon.',
      );
      return;
    }
    if (_isDebt && _tender > _grandTotal) {
      UiHelpers.showInfo(
        context,
        'Pembayaran melebihi total, matikan "utang".',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final sale = await context.read<CashierService>().checkout(
        storeId: cart.storeId!,
        paymentMethod: method,
        paidAmount: _tender,
        // Only send the breakdown for true combined payments.
        payments: payments.length > 1 ? payments : const [],
        items: cart.lines
            .map(
              (l) => CheckoutItem(
                productId: l.product.id,
                quantity: l.quantity,
                employeeId: l.employee?.id,
              ),
            )
            .toList(),
        customerId: cart.customer?.id,
        discountCode: cart.discountCode,
        isDebt: _isDebt,
      );
      cart.clear();
      cart.markSaleCompleted();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        FluentPageRoute(builder: (_) => ReceiptScreen(sale: sale)),
      );
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CartProvider>();
    final change = _tender - _grandTotal;

    return ScaffoldPage(
      header: const PageHeader(
        leading: AppBackButton(),
        title: Text('Pembayaran'),
      ),
      content: BoundedContent(
        maxWidth: 560,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _totalCard(),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Metode pembayaran',
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                const Spacer(),
                Button(onPressed: _payExact, child: const Text('Uang pas')),
              ],
            ),
            const SizedBox(height: 8),
            ..._rows.asMap().entries.map((e) => _payRowTile(e.key, e.value)),
            const SizedBox(height: 8),
            _denominationButtons(),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Button(
                onPressed: _addRow,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(FluentIcons.add, size: 12),
                    SizedBox(width: 6),
                    Text('Tambah metode (combine)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _row('Total bayar', Formatters.rupiah(_tender)),
                  if (!_isDebt && _tender > 0)
                    _row(
                      change >= 0 ? 'Kembalian' : 'Kurang',
                      Formatters.rupiah(change.abs()),
                      bold: true,
                    ),
                  if (_isDebt)
                    _row(
                      'Sisa utang',
                      Formatters.rupiah(
                        (_grandTotal - _tender).clamp(0, _grandTotal),
                      ),
                      bold: true,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Checkbox(
              checked: _isDebt,
              onChanged: (v) => setState(() => _isDebt = v ?? false),
              content: const Text('Transaksi utang (bon / bayar sebagian)'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: ProgressRing(strokeWidth: 2),
                        )
                      : const Text('Proses Transaksi'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _denominationButtons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in _denominations)
          Button(
            onPressed: () => _addDenomination(value),
            child: Text(Formatters.number(value)),
          ),
        Button(onPressed: _clearAmounts, child: const Text('Reset')),
      ],
    );
  }

  Widget _payRowTile(int index, _PayRow row) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: ComboBox<String>(
              value: row.method,
              isExpanded: true,
              items: _methodLabels.entries
                  .map(
                    (e) => ComboBoxItem<String>(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => row.method = v ?? 'cash'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppTextBox(
              controller: row.controller,
              placeholder: '0',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefix: const Padding(
                padding: EdgeInsetsDirectional.only(start: 12),
                child: Text('Rp'),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_rows.length > 1)
            IconButton(
              icon: const Icon(FluentIcons.delete),
              onPressed: () => _removeRow(index),
            ),
        ],
      ),
    );
  }

  Widget _totalCard() {
    if (_loadingTotal) {
      return const Card(
        child: SizedBox(height: 60, child: Center(child: ProgressRing())),
      );
    }
    final pricing = _pricing;
    return Card(
      child: Column(
        children: [
          _row('Subtotal', Formatters.rupiah(_subtotal)),
          if (pricing != null) ...[
            if (pricing.discountTotal > 0)
              _row(
                'Diskon${pricing.discountName != null ? ' (${pricing.discountName})' : ''}',
                '- ${Formatters.rupiah(pricing.discountTotal)}',
              ),
            if (pricing.serviceFeeTotal > 0)
              _row('Biaya layanan', Formatters.rupiah(pricing.serviceFeeTotal)),
            if (pricing.taxTotal > 0)
              _row('Pajak', Formatters.rupiah(pricing.taxTotal)),
          ],
          const Divider(),
          _row('Total tagihan', Formatters.rupiah(_grandTotal), bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold
        ? FluentTheme.of(context).typography.subtitle
        : FluentTheme.of(context).typography.body;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

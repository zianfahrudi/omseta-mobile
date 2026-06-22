import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_text_box.dart';
import '../models/staff_member.dart';
import '../providers/cart_provider.dart';
import '../services/cashier_service.dart';
import '../screens/checkout_screen.dart';
import '../screens/customer_picker_screen.dart';

/// Reusable cart contents: line items, customer, discount, totals and the
/// proceed-to-payment action. Used as a persistent side panel on desktop and
/// inside the full-screen cart on mobile.
class CartPanel extends StatefulWidget {
  const CartPanel({super.key, this.showHeader = false});

  /// Show a small "Keranjang" header (used in the desktop side panel).
  final bool showHeader;

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final _discountController = TextEditingController();
  bool _applyingDiscount = false;

  List<StaffMember> _staff = [];
  int? _staffStoreId;

  Timer? _priceDebounce;
  bool _autoPricing = false;
  String? _pricedSignature;

  @override
  void dispose() {
    _priceDebounce?.cancel();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff(int storeId) async {
    _staffStoreId = storeId;
    try {
      final staff = await context.read<CashierService>().employees(
        storeId: storeId,
      );
      if (mounted) setState(() => _staff = staff);
    } catch (_) {
      // Staff list is optional; ignore failures (dropdown just stays empty).
    }
  }

  /// Recompute the authoritative total (incl. outlet tax & service fee) via
  /// `/pricing` whenever the cart contents change.
  Future<void> _autoPrice() async {
    final cart = context.read<CartProvider>();
    if (cart.storeId == null || cart.isEmpty) return;
    _autoPricing = true;
    _pricedSignature = '${cart.subtotal}|${cart.discountCode ?? ''}';
    try {
      final pricing = await context.read<CashierService>().pricing(
        storeId: cart.storeId!,
        subtotal: cart.subtotal,
        discountCode: cart.discountCode,
      );
      cart.setPricing(pricing);
    } catch (_) {
      // Ignore; checkout re-prices authoritatively before payment anyway.
    } finally {
      _autoPricing = false;
    }
  }

  Future<void> _recalculate() async {
    final cart = context.read<CartProvider>();
    if (cart.storeId == null || cart.isEmpty) return;
    setState(() => _applyingDiscount = true);
    try {
      final pricing = await context.read<CashierService>().pricing(
        storeId: cart.storeId!,
        subtotal: cart.subtotal,
        discountCode: _discountController.text.trim(),
      );
      cart.setDiscountCode(_discountController.text.trim());
      cart.setPricing(pricing);
      if (mounted) UiHelpers.showSuccess(context, 'Harga diperbarui.');
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _applyingDiscount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final typography = FluentTheme.of(context).typography;

    // Load the staff list once per active outlet.
    if (cart.storeId != null && cart.storeId != _staffStoreId) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadStaff(cart.storeId!),
      );
    }

    // Recompute the authoritative total whenever the cart changes (pricing is
    // reset to null on add/remove/quantity/discount changes).
    final signature = '${cart.subtotal}|${cart.discountCode ?? ''}';
    if (!cart.isEmpty &&
        cart.storeId != null &&
        cart.pricing == null &&
        !_autoPricing &&
        signature != _pricedSignature) {
      _priceDebounce?.cancel();
      _priceDebounce = Timer(const Duration(milliseconds: 350), _autoPrice);
    }

    if (cart.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              FluentIcons.shopping_cart,
              size: 40,
              color: FluentTheme.of(context).resources.textFillColorDisabled,
            ),
            const SizedBox(height: 8),
            Text('Keranjang kosong', style: typography.body),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('Keranjang', style: typography.subtitle),
                const Spacer(),
                Text('${cart.itemCount} item', style: typography.caption),
              ],
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...cart.lines.map(
                (line) => _CartLineTile(
                  line: line,
                  staff: _staff,
                  onChanged: (qty) => cart.setQuantity(line.product.id, qty),
                  onRemove: () => cart.remove(line.product.id),
                  onEmployeeChanged: (staff) =>
                      cart.setLineEmployee(line.product.id, staff),
                ),
              ),
              const SizedBox(height: 8),
              _customerSection(cart),
              const SizedBox(height: 12),
              _discountSection(),
              const SizedBox(height: 12),
              _summary(cart),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).push(FluentPageRoute(builder: (_) => const CheckoutScreen())),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Lanjut ke Pembayaran'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _customerSection(CartProvider cart) {
    return Card(
      child: Row(
        children: [
          const Icon(FluentIcons.contact),
          const SizedBox(width: 12),
          Expanded(
            child: cart.customer == null
                ? const Text('Tanpa pelanggan (walk-in)')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cart.customer!.name,
                        style: FluentTheme.of(context).typography.bodyStrong,
                      ),
                      if (cart.customer!.phone != null)
                        Text(
                          cart.customer!.phone!,
                          style: FluentTheme.of(context).typography.caption,
                        ),
                    ],
                  ),
          ),
          if (cart.customer != null)
            IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: () => cart.setCustomer(null),
            ),
          Button(
            onPressed: () async {
              final selected = await Navigator.of(context).push(
                FluentPageRoute<dynamic>(
                  builder: (_) => const CustomerPickerScreen(),
                ),
              );
              if (selected != null) cart.setCustomer(selected);
            },
            child: const Text('Pilih'),
          ),
        ],
      ),
    );
  }

  Widget _discountSection() {
    return Card(
      child: Row(
        children: [
          Expanded(
            child: AppTextBox(
              controller: _discountController,
              placeholder: 'Kode diskon (opsional)',
              prefixIcon: FluentIcons.ticket,
            ),
          ),
          const SizedBox(width: 8),
          Button(
            onPressed: _applyingDiscount ? null : _recalculate,
            child: _applyingDiscount
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: ProgressRing(strokeWidth: 2),
                  )
                : const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  Widget _summary(CartProvider cart) {
    final pricing = cart.pricing;
    return Card(
      child: Column(
        children: [
          _row('Subtotal', Formatters.rupiah(cart.subtotal)),
          if (pricing != null) ...[
            if (pricing.discountTotal > 0)
              _row(
                'Diskon (${pricing.discountName ?? pricing.discountCode})',
                '- ${Formatters.rupiah(pricing.discountTotal)}',
              ),
            if (pricing.serviceFeeTotal > 0)
              _row('Biaya layanan', Formatters.rupiah(pricing.serviceFeeTotal)),
            if (pricing.taxTotal > 0)
              _row('Pajak', Formatters.rupiah(pricing.taxTotal)),
          ],
          const Divider(),
          _row('Total', Formatters.rupiah(cart.grandTotal), bold: true),
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
          Flexible(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.staff,
    required this.onChanged,
    required this.onRemove,
    required this.onEmployeeChanged,
  });

  final CartLine line;
  final List<StaffMember> staff;
  final ValueChanged<int> onChanged;
  final VoidCallback onRemove;
  final ValueChanged<StaffMember?> onEmployeeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.product.name,
            style: FluentTheme.of(context).typography.bodyStrong,
          ),
          const SizedBox(height: 2),
          Text(
            Formatters.rupiah(line.product.unitPrice),
            style: FluentTheme.of(context).typography.caption,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(FluentIcons.remove),
                onPressed: () => onChanged(line.quantity - 1),
              ),
              SizedBox(
                width: 28,
                child: Center(
                  child: Text(
                    '${line.quantity}',
                    style: FluentTheme.of(context).typography.bodyStrong,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(FluentIcons.add),
                onPressed: () => onChanged(line.quantity + 1),
              ),
              const Spacer(),
              Text(
                Formatters.rupiah(line.lineTotal),
                style: FluentTheme.of(context).typography.body,
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(FluentIcons.delete),
                onPressed: onRemove,
              ),
            ],
          ),
          if (staff.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  FluentIcons.medical,
                  size: 13,
                  color: FluentTheme.of(
                    context,
                  ).resources.textFillColorSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ComboBox<int?>(
                    value: line.employee?.id,
                    isExpanded: true,
                    placeholder: const Text('Pilih petugas (opsional)'),
                    items: [
                      const ComboBoxItem<int?>(
                        value: null,
                        child: Text('Tanpa petugas'),
                      ),
                      ...staff.map(
                        (s) => ComboBoxItem<int?>(
                          value: s.id,
                          child: Text(s.label, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (id) => onEmployeeChanged(
                      id == null ? null : staff.firstWhere((s) => s.id == id),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

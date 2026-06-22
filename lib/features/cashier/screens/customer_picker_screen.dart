import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_back_button.dart';
import '../../../core/widgets/app_text_box.dart';
import '../models/customer.dart';
import '../providers/cart_provider.dart';
import '../services/cashier_service.dart';

/// Search and select a customer (or create a new one). Returns the chosen
/// [Customer] via `Navigator.pop`.
class CustomerPickerScreen extends StatefulWidget {
  const CustomerPickerScreen({super.key});

  @override
  State<CustomerPickerScreen> createState() => _CustomerPickerScreenState();
}

class _CustomerPickerScreenState extends State<CustomerPickerScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Customer> _customers = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

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
      final customers = await context.read<CashierService>().customers(
        storeId: storeId,
        query: query,
      );
      if (mounted) setState(() => _customers = customers);
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createCustomer() async {
    final result = await showDialog<Customer>(
      context: context,
      builder: (_) => const _NewCustomerDialog(),
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        leading: const AppBackButton(),
        title: const Text('Pilih Pelanggan'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.add_friend),
              label: const Text('Baru'),
              onPressed: _createCustomer,
            ),
          ],
        ),
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppTextBox(
              controller: _searchController,
              placeholder: 'Cari nama / nomor HP',
              prefixIcon: FluentIcons.search,
              onChanged: _onChanged,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loading
                ? const Center(child: ProgressRing())
                : _customers.isEmpty
                ? const Center(child: Text('Tidak ada pelanggan.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _customers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final c = _customers[index];
                      return Card(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    style: FluentTheme.of(
                                      context,
                                    ).typography.bodyStrong,
                                  ),
                                  if (c.phone != null)
                                    Text(
                                      c.phone!,
                                      style: FluentTheme.of(
                                        context,
                                      ).typography.caption,
                                    ),
                                  if (c.outstandingDebt > 0)
                                    Text(
                                      'Utang: ${Formatters.rupiah(c.outstandingDebt)}',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(c),
                              child: const Text('Pilih'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _NewCustomerDialog extends StatefulWidget {
  const _NewCustomerDialog();

  @override
  State<_NewCustomerDialog> createState() => _NewCustomerDialogState();
}

class _NewCustomerDialogState extends State<_NewCustomerDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _plate = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _plate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      UiHelpers.showInfo(context, 'Nama wajib diisi.');
      return;
    }
    final storeId = context.read<CartProvider>().storeId;
    if (storeId == null) return;
    setState(() => _saving = true);
    try {
      final customer = await context.read<CashierService>().createCustomer(
        storeId: storeId,
        name: _name.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        vehiclePlateNumber: _plate.text.trim().isEmpty
            ? null
            : _plate.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(customer);
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      title: const Text('Pelanggan Baru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InfoLabel(
            label: 'Nama',
            child: AppTextBox(controller: _name, autofocus: true),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: 'Nomor HP',
            child: AppTextBox(
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
          ),
          const SizedBox(height: 12),
          InfoLabel(
            label: 'Plat kendaraan (opsional)',
            child: AppTextBox(controller: _plate),
          ),
        ],
      ),
      actions: [
        Button(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: ProgressRing(strokeWidth: 2),
                )
              : const Text('Simpan'),
        ),
      ],
    );
  }
}

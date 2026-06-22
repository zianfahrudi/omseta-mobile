import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_text_box.dart';
import '../../../core/widgets/bounded_content.dart';
import '../models/cashier_session.dart';
import '../providers/cart_provider.dart';
import '../services/cashier_service.dart';

/// Open and close the cashier's cash drawer session for the active outlet.
class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  CashierSession? _session;
  bool _loading = false;
  bool _busy = false;
  int? _loadedStoreId;
  int _loadedSalesVersion = 0;

  Future<void> _load() async {
    final cart = context.read<CartProvider>();
    final storeId = cart.storeId;
    if (storeId == null) return;
    setState(() => _loading = true);
    try {
      final session = await context.read<CashierService>().currentSession(
        storeId,
      );
      if (mounted) {
        setState(() {
          _session = session;
          _loadedStoreId = storeId;
          _loadedSalesVersion = cart.salesVersion;
        });
      }
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open() async {
    final amount = await _promptAmount(
      title: 'Buka Sesi Kasir',
      label: 'Modal awal (kas)',
    );
    if (amount == null) return;
    final storeId = context.read<CartProvider>().storeId!;
    setState(() => _busy = true);
    try {
      final session = await context.read<CashierService>().openSession(
        storeId: storeId,
        openingCash: amount.value,
      );
      setState(() => _session = session);
      if (mounted) UiHelpers.showSuccess(context, 'Sesi dibuka.');
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _close() async {
    final amount = await _promptAmount(
      title: 'Tutup Sesi Kasir',
      label: 'Uang dihitung (kas fisik)',
      withNotes: true,
    );
    if (amount == null) return;
    setState(() => _busy = true);
    try {
      final session = await context.read<CashierService>().closeSession(
        sessionId: _session!.id,
        countedCash: amount.value,
        notes: amount.notes,
      );
      setState(() => _session = session);
      if (mounted) {
        UiHelpers.showSuccess(
          context,
          'Sesi ditutup. Selisih: ${Formatters.rupiah(session.cashDifference)}',
        );
      }
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<_AmountResult?> _promptAmount({
    required String title,
    required String label,
    bool withNotes = false,
  }) async {
    final controller = TextEditingController();
    final notesController = TextEditingController();
    final result = await showDialog<_AmountResult>(
      context: context,
      builder: (_) => ContentDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InfoLabel(
              label: label,
              child: AppTextBox(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                prefix: const Padding(
                  padding: EdgeInsetsDirectional.only(start: 12),
                  child: Text('Rp'),
                ),
              ),
            ),
            if (withNotes) ...[
              const SizedBox(height: 12),
              InfoLabel(
                label: 'Catatan (opsional)',
                child: AppTextBox(controller: notesController),
              ),
            ],
          ],
        ),
        actions: [
          Button(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              final digits = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
              final value = int.tryParse(digits) ?? 0;
              Navigator.of(context).pop(
                _AmountResult(
                  value,
                  notes: notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
                ),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final storeId = cart.storeId;
    // Reload when the outlet changes or a new sale has been completed (so the
    // cash-sales total / expected cash stay in sync).
    if (storeId != null &&
        !_loading &&
        (storeId != _loadedStoreId ||
            cart.salesVersion != _loadedSalesVersion)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Sesi Kasir'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Muat ulang'),
              onPressed: _load,
            ),
          ],
        ),
      ),
      content: _loading
          ? const Center(child: ProgressRing())
          : BoundedContent(
              maxWidth: 560,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _session == null || !_session!.isOpen
                    ? _closedView()
                    : _openView(_session!),
              ),
            ),
    );
  }

  Widget _closedView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(FluentIcons.money, size: 48),
        const SizedBox(height: 12),
        const Text('Belum ada sesi terbuka.'),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _open,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('Buka Sesi'),
          ),
        ),
      ],
    );
  }

  Widget _openView(CashierSession session) {
    return ListView(
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                session.number,
                style: FluentTheme.of(context).typography.subtitle,
              ),
              const SizedBox(height: 8),
              _kv('Dibuka', Formatters.dateTime(session.openedAt)),
              _kv('Modal awal', Formatters.rupiah(session.openingCash)),
              _kv('Penjualan tunai', Formatters.rupiah(session.cashSalesTotal)),
              _kv(
                'Ekspektasi kas',
                Formatters.rupiah(session.expectedCashLive),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _busy ? null : _close,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Tutup Sesi'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(key), Text(value)],
      ),
    );
  }
}

class _AmountResult {
  _AmountResult(this.value, {this.notes});
  final num value;
  final String? notes;
}

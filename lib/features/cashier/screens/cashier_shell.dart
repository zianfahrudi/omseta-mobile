import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_title_bar.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import 'pos_screen.dart';
import 'session_screen.dart';
import 'transactions_screen.dart';

/// Top-level navigation shell for the cashier (POS) experience.
class CashierShell extends StatefulWidget {
  const CashierShell({super.key});

  @override
  State<CashierShell> createState() => _CashierShellState();
}

class _CashierShellState extends State<CashierShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Default the active outlet to the user's first store.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      final cart = context.read<CartProvider>();
      final stores = auth.user?.stores ?? const [];
      if (cart.storeId == null && stores.isNotEmpty) {
        cart.setStore(stores.first.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final stores = auth.user?.stores ?? const [];

    return NavigationView(
      titleBar: const AppTitleBar(title: 'omsetaPOS · Kasir'),
      pane: NavigationPane(
        selected: _index,
        onChanged: (i) => setState(() => _index = i),
        displayMode: PaneDisplayMode.auto,
        header: stores.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: InfoLabel(
                  label: 'Outlet',
                  child: ComboBox<int>(
                    value: cart.storeId,
                    placeholder: const Text('Pilih outlet'),
                    isExpanded: true,
                    items: stores
                        .map(
                          (s) => ComboBoxItem<int>(
                            value: s.id,
                            child: Text(s.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => cart.setStore(value),
                  ),
                ),
              ),
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.shopping_cart),
            title: const Text('Kasir'),
            body: const PosScreen(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.history),
            title: const Text('Transaksi'),
            body: const TransactionsScreen(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.money),
            title: const Text('Sesi Kasir'),
            body: const SessionScreen(),
          ),
        ],
        footerItems: [
          PaneItemAction(
            icon: const Icon(FluentIcons.sign_out),
            title: Text('Keluar (${auth.user?.name ?? ''})'),
            onTap: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_text_box.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/cashier_service.dart';
import '../widgets/cart_panel.dart';
import 'cart_screen.dart';

/// Product search + add to cart. Adapts between a single-column phone layout
/// (with a cart bottom bar) and a two-pane desktop layout (products grid plus a
/// persistent cart panel).
class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Product> _products = [];
  bool _loading = false;
  int? _loadedStoreId;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _load(query: value);
    });
  }

  Future<void> _load({String? query}) async {
    final storeId = context.read<CartProvider>().storeId;
    if (storeId == null) {
      UiHelpers.showInfo(context, 'Pilih outlet terlebih dahulu.');
      return;
    }
    setState(() => _loading = true);
    try {
      final products = await context.read<CashierService>().products(
        storeId: storeId,
        query: query,
      );
      if (mounted) {
        setState(() {
          _products = products;
          _loadedStoreId = storeId;
        });
      }
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    // Reload when the active outlet changes.
    if (cart.storeId != null && cart.storeId != _loadedStoreId && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }

    final wide = context.isWide;

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Kasir'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Muat ulang'),
              onPressed: () => _load(query: _searchController.text),
            ),
          ],
        ),
      ),
      content: wide ? _wideLayout() : _narrowLayout(cart),
    );
  }

  // --- Desktop / tablet: products grid + persistent cart panel ---
  Widget _wideLayout() {
    final theme = FluentTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              _searchField(),
              const SizedBox(height: 12),
              Expanded(child: _buildProducts(grid: true)),
            ],
          ),
        ),
        Container(
          width: 380,
          margin: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.resources.cardStrokeColorDefault),
          ),
          child: const CartPanel(showHeader: true),
        ),
      ],
    );
  }

  // --- Phone: single column + cart bottom bar ---
  Widget _narrowLayout(CartProvider cart) {
    return Column(
      children: [
        _searchField(),
        const SizedBox(height: 12),
        Expanded(child: _buildProducts(grid: false)),
        _CartBar(cart: cart),
      ],
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppTextBox(
        controller: _searchController,
        placeholder: 'Cari produk (nama / SKU / barcode)',
        prefixIcon: FluentIcons.search,
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildProducts({required bool grid}) {
    if (_loading) {
      return const Center(child: ProgressRing());
    }
    if (_products.isEmpty) {
      return const Center(child: Text('Tidak ada produk.'));
    }

    if (!grid) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _products.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _ProductTile(product: _products[index]),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 260).floor().clamp(1, 4);
        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: 150,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _products.length,
          itemBuilder: (context, index) =>
              _ProductCard(product: _products[index]),
        );
      },
    );
  }
}

/// Compact card used in the desktop grid.
class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final outOfStock = !product.isService && product.stock <= 0;
    return Card(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.typography.bodyStrong,
          ),
          const SizedBox(height: 2),
          Text(
            product.isService
                ? 'Jasa'
                : 'Stok ${Formatters.number(product.stock)} ${product.unit ?? ''}',
            style: theme.typography.caption,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  Formatters.rupiah(product.unitPrice),
                  style: theme.typography.bodyStrong,
                ),
              ),
              FilledButton(
                onPressed: outOfStock
                    ? null
                    : () => context.read<CartProvider>().add(product),
                child: Icon(outOfStock ? FluentIcons.blocked : FluentIcons.add),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Row tile used in the phone list.
class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final outOfStock = !product.isService && product.stock <= 0;
    return Card(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: FluentTheme.of(context).typography.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(
                  '${product.code} · ${product.isService ? 'Jasa' : 'Stok ${Formatters.number(product.stock)} ${product.unit ?? ''}'}',
                  style: FluentTheme.of(context).typography.caption,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.rupiah(product.unitPrice),
                  style: FluentTheme.of(context).typography.body,
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: outOfStock
                ? null
                : () {
                    context.read<CartProvider>().add(product);
                    UiHelpers.showSuccess(
                      context,
                      '${product.name} ditambahkan.',
                      title: 'Keranjang',
                    );
                  },
            child: Text(outOfStock ? 'Habis' : 'Tambah'),
          ),
        ],
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  const _CartBar({required this.cart});

  final CartProvider cart;

  @override
  Widget build(BuildContext context) {
    if (cart.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: FluentTheme.of(context).resources.dividerStrokeColorDefault,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cart.itemCount} item',
                  style: FluentTheme.of(context).typography.caption,
                ),
                Text(
                  Formatters.rupiah(cart.subtotal),
                  style: FluentTheme.of(context).typography.subtitle,
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              context,
            ).push(FluentPageRoute(builder: (_) => const CartScreen())),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('Lihat Keranjang'),
            ),
          ),
        ],
      ),
    );
  }
}

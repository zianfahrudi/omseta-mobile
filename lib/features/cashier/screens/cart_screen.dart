import 'package:fluent_ui/fluent_ui.dart';

import '../../../core/widgets/app_back_button.dart';
import '../widgets/cart_panel.dart';

/// Full-screen cart used on phones. Reuses [CartPanel] for the contents.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ScaffoldPage(
      header: PageHeader(leading: AppBackButton(), title: Text('Keranjang')),
      content: CartPanel(),
    );
  }
}

import 'package:fluent_ui/fluent_ui.dart';

/// A back button intended for [PageHeader.leading] on pushed pages.
///
/// Pops the current route. Hidden automatically when there is nothing to pop.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Navigator.of(context).canPop()) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 4),
      child: Tooltip(
        message: 'Kembali (Esc)',
        child: IconButton(
          icon: const Icon(FluentIcons.back, size: 16),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

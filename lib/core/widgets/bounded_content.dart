import 'package:fluent_ui/fluent_ui.dart';

/// Centers its [child] and caps the width on large (desktop) windows so forms
/// and lists stay comfortably readable instead of stretching edge to edge.
class BoundedContent extends StatelessWidget {
  const BoundedContent({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

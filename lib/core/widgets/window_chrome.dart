import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/responsive.dart';

/// Window caption buttons (minimize, maximize/restore, close) for the custom
/// hidden title bar on desktop.
class WindowCaptionButtons extends StatefulWidget {
  const WindowCaptionButtons({super.key});

  @override
  State<WindowCaptionButtons> createState() => _WindowCaptionButtonsState();
}

class _WindowCaptionButtonsState extends State<WindowCaptionButtons>
    with WindowListener {
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _sync();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _sync() async {
    final maximized = await windowManager.isMaximized();
    if (mounted) setState(() => _maximized = maximized);
  }

  @override
  void onWindowMaximize() => setState(() => _maximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _maximized = false);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CaptionButton(
          icon: FluentIcons.chrome_minimize,
          onPressed: windowManager.minimize,
        ),
        _CaptionButton(
          icon: _maximized ? FluentIcons.chrome_restore : FluentIcons.checkbox,
          onPressed: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
        ),
        _CaptionButton(
          icon: FluentIcons.chrome_close,
          isClose: true,
          onPressed: windowManager.close,
        ),
      ],
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.icon,
    required this.onPressed,
    this.isClose = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool isClose;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final hoverColor = widget.isClose
        ? const Color(0xFFC42B1C)
        : theme.resources.subtleFillColorSecondary;
    final iconColor = widget.isClose && _hovered
        ? Colors.white
        : theme.resources.textFillColorPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: 36,
          color: _hovered ? hoverColor : Colors.transparent,
          alignment: Alignment.center,
          child: Icon(widget.icon, size: 13, color: iconColor),
        ),
      ),
    );
  }
}

/// Wraps a page with a slim draggable title bar (app title + window caption
/// buttons) on desktop. On mobile it simply returns [child].
///
/// Used for screens that aren't hosted inside a [NavigationView] (e.g. the
/// login / role-selection flow) so the window stays movable and closable.
class DesktopWindowScaffold extends StatelessWidget {
  const DesktopWindowScaffold({
    super.key,
    required this.child,
    this.title = 'omsetaPOS',
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (!isDesktopPlatform) return child;

    final theme = FluentTheme.of(context);
    return Column(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (_) => windowManager.startDragging(),
          onDoubleTap: () async {
            if (await windowManager.isMaximized()) {
              await windowManager.unmaximize();
            } else {
              await windowManager.maximize();
            }
          },
          child: Container(
            height: 36,
            padding: EdgeInsetsDirectional.only(
              // Leave room for the macOS native traffic lights.
              start: isMacOSPlatform ? 78 : 14,
            ),
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              children: [
                Icon(FluentIcons.shop, size: 14, color: theme.accentColor),
                const SizedBox(width: 8),
                Text(title, style: theme.typography.caption),
                const Spacer(),
                if (usesCustomCaptionButtons) const WindowCaptionButtons(),
              ],
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}

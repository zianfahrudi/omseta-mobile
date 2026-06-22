import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/responsive.dart';
import 'window_chrome.dart';

/// A [TitleBar] configured for the current platform:
///
/// - macOS: leaves room on the left for the native traffic-light buttons and
///   does NOT draw custom caption controls (macOS provides its own).
/// - Windows/Linux: draws custom minimize/maximize/close buttons.
/// - Mobile: a plain top bar (no window chrome).
class AppTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTitleBar({super.key, required this.title, this.endHeader});

  final String title;
  final Widget? endHeader;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return TitleBar(
      // The shell is a root view — no automatic back button (it overlapped the
      // pane toggle / traffic lights). Pushed pages provide their own back.
      isBackButtonVisible: false,
      // Reserve space for the macOS traffic-light buttons so the icon/title
      // doesn't get covered by them.
      leftHeader: isMacOSPlatform ? const SizedBox(width: 70) : null,
      icon: const Icon(FluentIcons.shop, size: 16),
      title: Text(title),
      endHeader: endHeader,
      captionControls: usesCustomCaptionButtons
          ? const WindowCaptionButtons()
          : null,
      onDragStarted: isDesktopPlatform ? windowManager.startDragging : null,
      onDoubleTap: isDesktopPlatform
          ? () async {
              if (await windowManager.isMaximized()) {
                await windowManager.unmaximize();
              } else {
                await windowManager.maximize();
              }
            }
          : null,
    );
  }
}

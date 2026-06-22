import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart';

/// Layout breakpoints used to adapt the UI between phone, tablet and desktop.
class Breakpoints {
  Breakpoints._();

  static const double tablet = 720;
  static const double desktop = 1100;
}

enum ScreenSize { phone, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  ScreenSize get screenSize {
    final width = screenWidth;
    if (width >= Breakpoints.desktop) return ScreenSize.desktop;
    if (width >= Breakpoints.tablet) return ScreenSize.tablet;
    return ScreenSize.phone;
  }

  /// Wide enough to show side-by-side master/detail layouts.
  bool get isWide => screenWidth >= Breakpoints.tablet;

  bool get isDesktopSize => screenWidth >= Breakpoints.desktop;
}

/// True when running on a desktop operating system (controls window chrome,
/// hover affordances, etc.). Independent of window width.
bool get isDesktopPlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// macOS draws its own (native) window caption buttons — the traffic lights.
bool get isMacOSPlatform =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// Mobile platforms (where Bluetooth thermal printing is available).
bool get isMobilePlatform =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

/// Platforms where print_bluetooth_thermal is supported
/// (Android, iOS, macOS, Windows). Web and Linux are not supported.
bool get isThermalPrintingSupported =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows);

/// Windows/Linux need custom caption buttons when the native title bar is
/// hidden.
bool get usesCustomCaptionButtons =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux);

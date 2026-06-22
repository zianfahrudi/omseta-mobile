import 'package:fluent_ui/fluent_ui.dart';

/// Centralized Fluent UI theming for omsetaPOS.
class AppTheme {
  AppTheme._();

  static const Color brand = Color(0xFF0F6CBD);

  static FluentThemeData light() {
    return FluentThemeData(
      brightness: Brightness.light,
      accentColor: _accent,
      scaffoldBackgroundColor: const Color(0xFFF3F3F3),
      visualDensity: VisualDensity.standard,
    );
  }

  static FluentThemeData dark() {
    return FluentThemeData(
      brightness: Brightness.dark,
      accentColor: _accent,
      visualDensity: VisualDensity.standard,
    );
  }

  static final AccentColor _accent = AccentColor.swatch(const {
    'darkest': Color(0xFF06243F),
    'darker': Color(0xFF093860),
    'dark': Color(0xFF0C4C81),
    'normal': brand,
    'light': Color(0xFF3A8AD0),
    'lighter': Color(0xFF6FA9DE),
    'lightest': Color(0xFFA9CCEC),
  });
}

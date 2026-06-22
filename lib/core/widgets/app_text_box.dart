import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';

/// Shared, cleaner-looking text inputs for the whole app.
///
/// Wraps Fluent's [TextBox]/[PasswordBox] with consistent rounded corners,
/// roomier padding, a soft fill and a subtle border that highlights with the
/// accent color on focus.
const _kRadius = 8.0;
const _kContentPadding = EdgeInsetsDirectional.fromSTEB(12, 10, 10, 10);

WidgetStateProperty<BoxDecoration> _decoration(FluentThemeData theme) {
  final resources = theme.resources;
  return WidgetStateProperty.resolveWith((states) {
    final focused = states.isFocused;
    return BoxDecoration(
      borderRadius: BorderRadius.circular(_kRadius),
      color: states.isDisabled
          ? resources.controlFillColorDisabled
          : resources.controlFillColorDefault,
      border: Border.all(
        width: focused ? 1.6 : 1,
        color: focused
            ? theme.accentColor.defaultBrushFor(theme.brightness)
            : resources.controlStrokeColorDefault,
      ),
    );
  });
}

class AppTextBox extends StatelessWidget {
  const AppTextBox({
    super.key,
    this.controller,
    this.placeholder,
    this.prefixIcon,
    this.prefix,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final IconData? prefixIcon;
  final Widget? prefix;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool autofocus;
  final bool enabled;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return TextBox(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofocus: autofocus,
      enabled: enabled,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      padding: _kContentPadding,
      decoration: _decoration(theme),
      highlightColor: Colors.transparent,
      placeholderStyle: theme.typography.body?.copyWith(
        color: theme.resources.textFillColorTertiary,
      ),
      prefix:
          prefix ??
          (prefixIcon == null
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(start: 10),
                  child: Icon(
                    prefixIcon,
                    size: 16,
                    color: theme.resources.textFillColorSecondary,
                  ),
                )),
      suffix: suffix,
    );
  }
}

class AppPasswordBox extends StatelessWidget {
  const AppPasswordBox({
    super.key,
    this.controller,
    this.placeholder,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    return PasswordBox(
      controller: controller,
      placeholder: placeholder,
      autofocus: autofocus,
      onSubmitted: onSubmitted,
      revealMode: PasswordRevealMode.peekAlways,
      padding: _kContentPadding,
      decoration: _decoration(theme),
      highlightColor: Colors.transparent,
      placeholderStyle: theme.typography.body?.copyWith(
        color: theme.resources.textFillColorTertiary,
      ),
    );
  }
}

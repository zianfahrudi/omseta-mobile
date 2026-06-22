import 'package:flutter/foundation.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../api/api_exception.dart';

/// Small helpers for surfacing feedback with Fluent UI.
class UiHelpers {
  UiHelpers._();

  static void showError(BuildContext context, Object error) {
    final String message;
    if (error is ApiException) {
      message = error.message;
    } else if (kDebugMode) {
      // Surface the real cause during development to ease debugging.
      message = 'Terjadi kesalahan tak terduga: $error';
    } else {
      message = 'Terjadi kesalahan tak terduga.';
    }
    _show(context, 'Gagal', message, InfoBarSeverity.error);
  }

  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'Berhasil',
  }) {
    _show(context, title, message, InfoBarSeverity.success);
  }

  static void showInfo(
    BuildContext context,
    String message, {
    String title = 'Info',
  }) {
    _show(context, title, message, InfoBarSeverity.info);
  }

  static void _show(
    BuildContext context,
    String title,
    String message,
    InfoBarSeverity severity,
  ) {
    displayInfoBar(
      context,
      builder: (context, close) => InfoBar(
        title: Text(title),
        content: Text(message),
        severity: severity,
        isLong: message.length > 60,
        onClose: close,
      ),
    );
  }
}

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/storage/token_storage.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/window_chrome.dart';
import 'features/attendance/screens/attendance_shell.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/cashier/screens/cashier_shell.dart';

class OmsetaApp extends StatelessWidget {
  const OmsetaApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return FluentApp(
      title: 'omsetaPOS',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      builder: (context, child) => _EscToPop(child: child ?? const SizedBox()),
      home: const _RootGate(),
    );
  }
}

/// Pops the top route when Escape is pressed (desktop convenience). The key
/// event bubbles up from whatever currently has focus, so this works without
/// stealing focus from text fields.
class _EscToPop extends StatelessWidget {
  const _EscToPop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          final navigator = OmsetaApp.navigatorKey.currentState;
          if (navigator != null && navigator.canPop()) {
            navigator.pop();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }
}

/// Decides which experience to show based on the current auth state.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  @override
  void initState() {
    super.initState();
    // Restore any saved session once at startup.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.bootstrapping) {
      return const DesktopWindowScaffold(
        child: ScaffoldPage(content: Center(child: ProgressRing())),
      );
    }

    if (!auth.isLoggedIn) {
      return const DesktopWindowScaffold(child: RoleSelectScreen());
    }

    switch (auth.role!) {
      case AppRole.cashier:
        return const CashierShell();
      case AppRole.employee:
        return const AttendanceShell();
    }
  }
}

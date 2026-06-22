import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/storage/token_storage.dart';
import 'core/utils/responsive.dart';
import 'features/attendance/services/attendance_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/services/auth_service.dart';
import 'features/cashier/providers/cart_provider.dart';
import 'features/cashier/services/cashier_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Locale data for Rupiah / date formatting.
  await initializeDateFormatting('id_ID');

  // Configure the desktop window (Windows/macOS/Linux).
  if (isDesktopPlatform) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 832),
      minimumSize: Size(960, 640),
      center: true,
      title: 'omsetaPOS',
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Colors.transparent,
    );
    unawaited(
      windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      }),
    );
  }

  // Shared singletons.
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage: tokenStorage);
  final authService = AuthService(apiClient);

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<AuthService>.value(value: authService),
        Provider<CashierService>(create: (_) => CashierService(apiClient)),
        Provider<AttendanceService>(
          create: (_) => AttendanceService(apiClient),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(
            api: apiClient,
            authService: authService,
            tokenStorage: tokenStorage,
          ),
        ),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
      ],
      child: const OmsetaApp(),
    ),
  );
}

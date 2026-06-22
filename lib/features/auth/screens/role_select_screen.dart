import 'package:fluent_ui/fluent_ui.dart';

import '../../../core/theme/app_theme.dart';
import 'cashier_login_screen.dart';
import 'employee_login_screen.dart';

/// Entry screen that lets the user choose which app experience to log into:
/// Kasir (POS) or Absensi (employee attendance).
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      content: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _Brand(),
                const SizedBox(height: 8),
                Text(
                  'Pilih jenis akun untuk masuk',
                  style: FluentTheme.of(context).typography.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                _RoleCard(
                  icon: FluentIcons.shopping_cart,
                  title: 'Kasir',
                  subtitle: 'Penjualan, transaksi & sesi kasir',
                  onPressed: () => Navigator.of(context).push(
                    FluentPageRoute(builder: (_) => const CashierLoginScreen()),
                  ),
                ),
                const SizedBox(height: 14),
                _RoleCard(
                  icon: FluentIcons.contact,
                  title: 'Absensi Karyawan',
                  subtitle: 'Presensi mandiri dengan lokasi',
                  onPressed: () => Navigator.of(context).push(
                    FluentPageRoute(
                      builder: (_) => const EmployeeLoginScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppTheme.brand,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(FluentIcons.shop, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 16),
        Text('omsetaPOS', style: FluentTheme.of(context).typography.titleLarge),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final typography = FluentTheme.of(context).typography;
    return Button(
      onPressed: onPressed,
      style: ButtonStyle(
        padding: WidgetStateProperty.all(const EdgeInsets.all(18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: AppTheme.brand),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typography.bodyStrong),
                const SizedBox(height: 2),
                Text(subtitle, style: typography.caption),
              ],
            ),
          ),
          const Icon(FluentIcons.chevron_right, size: 14),
        ],
      ),
    );
  }
}

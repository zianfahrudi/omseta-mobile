import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_title_bar.dart';
import '../../auth/providers/auth_provider.dart';
import 'attendance_home_screen.dart';
import 'history_screen.dart';
import 'schedule_screen.dart';

/// Top-level navigation shell for the employee attendance experience.
class AttendanceShell extends StatefulWidget {
  const AttendanceShell({super.key});

  @override
  State<AttendanceShell> createState() => _AttendanceShellState();
}

class _AttendanceShellState extends State<AttendanceShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return NavigationView(
      titleBar: const AppTitleBar(title: 'omsetaPOS · Absensi'),
      pane: NavigationPane(
        selected: _index,
        onChanged: (i) => setState(() => _index = i),
        displayMode: PaneDisplayMode.auto,
        items: [
          PaneItem(
            icon: const Icon(FluentIcons.home),
            title: const Text('Presensi'),
            body: const AttendanceHomeScreen(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.history),
            title: const Text('Riwayat'),
            body: const HistoryScreen(),
          ),
          PaneItem(
            icon: const Icon(FluentIcons.calendar),
            title: const Text('Jadwal'),
            body: const ScheduleScreen(),
          ),
        ],
        footerItems: [
          PaneItemAction(
            icon: const Icon(FluentIcons.sign_out),
            title: Text('Keluar (${auth.employee?.name ?? ''})'),
            onTap: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
    );
  }
}

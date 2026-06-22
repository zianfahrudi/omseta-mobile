import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/bounded_content.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';

/// Lists the employee's attendance history.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Attendance> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await context.read<AttendanceService>().history();
      if (mounted) setState(() => _items = items);
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Riwayat Presensi'),
        commandBar: CommandBar(
          mainAxisAlignment: MainAxisAlignment.end,
          primaryItems: [
            CommandBarButton(
              icon: const Icon(FluentIcons.refresh),
              label: const Text('Muat ulang'),
              onPressed: _load,
            ),
          ],
        ),
      ),
      content: BoundedContent(
        child: _loading
            ? const Center(child: ProgressRing())
            : _items.isEmpty
            ? const Center(child: Text('Belum ada riwayat.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final att = _items[index];
                  return Card(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Formatters.date(att.workDate),
                                style: FluentTheme.of(
                                  context,
                                ).typography.bodyStrong,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Masuk ${Formatters.time(att.checkIn)} · Keluar ${Formatters.time(att.checkOut)}',
                                style: FluentTheme.of(
                                  context,
                                ).typography.caption,
                              ),
                              if (att.totalHours > 0)
                                Text(
                                  '${att.totalHours} jam',
                                  style: FluentTheme.of(
                                    context,
                                  ).typography.caption,
                                ),
                            ],
                          ),
                        ),
                        _StatusBadge(status: att.status),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  Color get _color {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.warningPrimaryColor;
      case 'absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, color: _color),
      ),
    );
  }
}

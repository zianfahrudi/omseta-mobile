import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/bounded_content.dart';
import '../models/schedule.dart';
import '../services/attendance_service.dart';

/// Lists upcoming shift schedule entries.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<ScheduleEntry> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await context.read<AttendanceService>().schedule();
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
        title: const Text('Jadwal Shift'),
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
            ? const Center(child: Text('Tidak ada jadwal mendatang.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = _items[index];
                  return Card(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(FluentIcons.calendar),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                Formatters.date(entry.workDate),
                                style: FluentTheme.of(
                                  context,
                                ).typography.bodyStrong,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                entry.shift == null
                                    ? 'Tanpa shift'
                                    : '${entry.shift!.name} · '
                                          '${Formatters.shiftTime(entry.shift!.startTime)} - '
                                          '${Formatters.shiftTime(entry.shift!.endTime)}',
                                style: FluentTheme.of(
                                  context,
                                ).typography.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

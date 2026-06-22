import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/bounded_content.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';
import '../services/location_service.dart';

/// Shows today's presence status and exposes the check-in / check-out actions
/// (which collect GPS + the mock flag for anti-fake-GPS validation).
class AttendanceHomeScreen extends StatefulWidget {
  const AttendanceHomeScreen({super.key});

  @override
  State<AttendanceHomeScreen> createState() => _AttendanceHomeScreenState();
}

class _AttendanceHomeScreenState extends State<AttendanceHomeScreen> {
  final _location = LocationService();
  TodayStatus? _today;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final today = await context.read<AttendanceService>().today();
      if (mounted) setState(() => _today = today);
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit({required bool checkIn}) async {
    setState(() => _busy = true);
    final service = context.read<AttendanceService>();
    try {
      final gps = await _location.current();
      final attendance = checkIn
          ? await service.checkIn(gps)
          : await service.checkOut(gps);
      if (!mounted) return;
      UiHelpers.showSuccess(
        context,
        checkIn
            ? 'Check-in berhasil (${Formatters.number(attendance.checkInDistance)} m).'
            : 'Check-out berhasil. Total ${attendance.totalHours} jam.',
      );
      await _load();
    } catch (e) {
      if (mounted) UiHelpers.showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employee = context.watch<AuthProvider>().employee;

    return ScaffoldPage(
      header: PageHeader(
        title: const Text('Presensi'),
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
      content: _loading
          ? const Center(child: ProgressRing())
          : BoundedContent(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: FluentTheme.of(context).accentColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Icon(
                            FluentIcons.contact,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                employee?.name ?? '-',
                                style: FluentTheme.of(
                                  context,
                                ).typography.bodyStrong,
                              ),
                              Text(
                                '${employee?.code ?? ''} · ${employee?.position ?? '-'}',
                                style: FluentTheme.of(
                                  context,
                                ).typography.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (employee?.location != null)
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(FluentIcons.location, size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Titik presensi',
                                style: FluentTheme.of(
                                  context,
                                ).typography.bodyStrong,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(employee!.location!.name),
                          if (employee.location!.address != null)
                            Text(
                              employee.location!.address!,
                              style: FluentTheme.of(context).typography.caption,
                            ),
                          Text(
                            'Radius ${employee.location!.radiusMeters} m',
                            style: FluentTheme.of(context).typography.caption,
                          ),
                        ],
                      ),
                    )
                  else
                    const InfoBar(
                      title: Text('Titik presensi belum ditentukan'),
                      content: Text(
                        'Sistem akan memakai titik aktif perusahaan saat check-in.',
                      ),
                      severity: InfoBarSeverity.warning,
                    ),
                  const SizedBox(height: 12),
                  _statusCard(),
                  const SizedBox(height: 16),
                  _actionButton(),
                ],
              ),
            ),
    );
  }

  Widget _statusCard() {
    final att = _today?.attendance;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Status ${Formatters.date(_today?.date)}',
            style: FluentTheme.of(context).typography.bodyStrong,
          ),
          const SizedBox(height: 8),
          if (att == null)
            const Text('Belum check-in hari ini.')
          else ...[
            _kv('Status', att.status.toUpperCase()),
            _kv('Check-in', Formatters.time(att.checkIn)),
            _kv('Check-out', Formatters.time(att.checkOut)),
            if (att.totalHours > 0) _kv('Total jam', '${att.totalHours} jam'),
          ],
        ],
      ),
    );
  }

  Widget _actionButton() {
    final canCheckIn = _today?.canCheckIn ?? false;
    final canCheckOut = _today?.canCheckOut ?? false;

    if (!canCheckIn && !canCheckOut) {
      return const Center(child: Text('Presensi hari ini selesai. 🎉'));
    }

    final isCheckIn = canCheckIn;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _busy ? null : () => _submit(checkIn: isCheckIn),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: ProgressRing(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(isCheckIn ? FluentIcons.signin : FluentIcons.sign_out),
                    const SizedBox(width: 8),
                    Text(
                      isCheckIn ? 'Check-in Sekarang' : 'Check-out Sekarang',
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(key), Text(value)],
      ),
    );
  }
}

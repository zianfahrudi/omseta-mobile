/// A shift definition.
class Shift {
  Shift({required this.id, required this.name, this.startTime, this.endTime});

  final int id;
  final String name;
  final String? startTime;
  final String? endTime;

  factory Shift.fromJson(Map<String, dynamic> json) {
    return Shift(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
    );
  }
}

/// An upcoming scheduled work day (optionally with a shift).
class ScheduleEntry {
  ScheduleEntry({required this.workDate, this.shift});

  final String workDate;
  final Shift? shift;

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    final shift = json['shift'];
    return ScheduleEntry(
      workDate: json['work_date'] as String? ?? '',
      shift: shift is Map<String, dynamic> ? Shift.fromJson(shift) : null,
    );
  }
}

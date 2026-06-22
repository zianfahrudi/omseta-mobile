/// A single attendance (presence) record.
class Attendance {
  Attendance({
    required this.id,
    required this.workDate,
    required this.status,
    this.source,
    this.checkIn,
    this.checkOut,
    this.totalHours = 0,
    this.checkInDistance,
    this.checkOutDistance,
  });

  final int id;
  final String workDate;
  final String status; // present | late | absent | leave | sick | holiday
  final String? source;
  final String? checkIn;
  final String? checkOut;
  final num totalHours;
  final num? checkInDistance;
  final num? checkOutDistance;

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] as int,
      workDate: json['work_date'] as String? ?? '',
      status: json['status'] as String? ?? 'present',
      source: json['source'] as String?,
      checkIn: json['check_in'] as String?,
      checkOut: json['check_out'] as String?,
      totalHours: (json['total_hours'] as num?) ?? 0,
      checkInDistance: json['check_in_distance'] as num?,
      checkOutDistance: json['check_out_distance'] as num?,
    );
  }
}

/// Today's attendance status, used to drive check-in/out buttons.
class TodayStatus {
  TodayStatus({
    required this.date,
    required this.canCheckIn,
    required this.canCheckOut,
    this.attendance,
  });

  final String date;
  final bool canCheckIn;
  final bool canCheckOut;
  final Attendance? attendance;

  factory TodayStatus.fromJson(Map<String, dynamic> json) {
    final att = json['attendance'];
    return TodayStatus(
      date: json['date'] as String? ?? '',
      canCheckIn: json['can_check_in'] as bool? ?? false,
      canCheckOut: json['can_check_out'] as bool? ?? false,
      attendance: att is Map<String, dynamic> ? Attendance.fromJson(att) : null,
    );
  }
}

import '../../../core/api/api_client.dart';
import '../models/attendance.dart';
import '../models/schedule.dart';
import 'location_service.dart';

/// Calls the employee attendance endpoints.
class AttendanceService {
  AttendanceService(this._api);

  final ApiClient _api;

  Future<TodayStatus> today() async {
    final data = await _api.get('/employee/attendance/today');
    return TodayStatus.fromJson((data as Map).cast<String, dynamic>());
  }

  Future<Attendance> checkIn(GpsReading gps, {String? deviceId}) async {
    final data = await _api.post(
      '/employee/attendance/check-in',
      data: _gpsBody(gps, deviceId),
    );
    return Attendance.fromJson(
      (data['attendance'] as Map).cast<String, dynamic>(),
    );
  }

  Future<Attendance> checkOut(GpsReading gps, {String? deviceId}) async {
    final data = await _api.post(
      '/employee/attendance/check-out',
      data: _gpsBody(gps, deviceId),
    );
    return Attendance.fromJson(
      (data['attendance'] as Map).cast<String, dynamic>(),
    );
  }

  Future<List<Attendance>> history({int perPage = 30}) async {
    final data = await _api.get(
      '/employee/attendance/history',
      query: {'per_page': perPage},
    );
    final list = data['data'] as List<dynamic>? ?? const [];
    return list
        .map((e) => Attendance.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<ScheduleEntry>> schedule() async {
    final data = await _api.get('/employee/schedule');
    final list = data['data'] as List<dynamic>? ?? const [];
    return list
        .map((e) => ScheduleEntry.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Map<String, dynamic> _gpsBody(GpsReading gps, String? deviceId) => {
    'latitude': gps.latitude,
    'longitude': gps.longitude,
    'accuracy': gps.accuracy,
    'is_mock': gps.isMock,
    if (deviceId != null) 'device_id': deviceId,
  };
}

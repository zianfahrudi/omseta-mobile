import '../../../core/api/api_client.dart';
import '../models/employee.dart';
import '../models/user.dart';

/// Result of a successful cashier login.
class CashierAuthResult {
  CashierAuthResult({required this.token, required this.user});
  final String token;
  final AppUser user;
}

/// Result of a successful employee login.
class EmployeeAuthResult {
  EmployeeAuthResult({required this.token, required this.employee});
  final String token;
  final Employee employee;
}

/// Talks to the auth endpoints for both cashier and employee identities.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  // --- Cashier ---

  Future<CashierAuthResult> cashierLogin({
    required String email,
    required String password,
    String deviceName = 'mobile',
  }) async {
    final data = await _api.post(
      '/auth/login',
      data: {'email': email, 'password': password, 'device_name': deviceName},
    );
    return CashierAuthResult(
      token: data['token'] as String,
      user: AppUser.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<AppUser> cashierMe() async {
    final data = await _api.get('/auth/me');
    return AppUser.fromJson(data as Map<String, dynamic>);
  }

  Future<void> cashierLogout() async {
    await _api.post('/auth/logout');
  }

  // --- Employee ---

  Future<EmployeeAuthResult> employeeLogin({
    required String phone,
    required String password,
    String deviceName = 'mobile',
    String? deviceId,
  }) async {
    final data = await _api.post(
      '/employee/auth/login',
      data: {
        'phone': phone,
        'password': password,
        'device_name': deviceName,
        if (deviceId != null) 'device_id': deviceId,
      },
    );
    return EmployeeAuthResult(
      token: data['token'] as String,
      employee: Employee.fromJson(data['employee'] as Map<String, dynamic>),
    );
  }

  Future<Employee> employeeMe() async {
    final data = await _api.get('/employee/auth/me');
    return Employee.fromJson(data as Map<String, dynamic>);
  }

  Future<void> employeeLogout() async {
    await _api.post('/employee/auth/logout');
  }
}

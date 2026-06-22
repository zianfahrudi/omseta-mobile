import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../models/employee.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Authentication state for the whole app. Drives which UI (cashier or
/// employee) is presented based on the active [AppRole].
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required ApiClient api,
    required AuthService authService,
    required TokenStorage tokenStorage,
  }) : _api = api,
       _authService = authService,
       _tokenStorage = tokenStorage {
    _api.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient _api;
  final AuthService _authService;
  final TokenStorage _tokenStorage;

  bool _bootstrapping = true;
  bool get bootstrapping => _bootstrapping;

  AppRole? _role;
  AppRole? get role => _role;

  AppUser? _user;
  AppUser? get user => _user;

  Employee? _employee;
  Employee? get employee => _employee;

  bool get isLoggedIn => _role != null;

  /// Restore a previous session on startup.
  Future<void> bootstrap() async {
    final token = await _tokenStorage.readToken();
    final role = await _tokenStorage.readRole();
    if (token == null || role == null) {
      _bootstrapping = false;
      notifyListeners();
      return;
    }

    // Make the token available to the API client before any request.
    _api.token = token;

    // Restore the cached profile immediately so the shell has data (stores,
    // etc.) even before /me responds — prevents an empty UI on restart.
    final cachedProfile = await _tokenStorage.readProfile();
    if (cachedProfile != null) {
      try {
        final map = jsonDecode(cachedProfile) as Map<String, dynamic>;
        if (role == AppRole.cashier) {
          _user = AppUser.fromJson(map);
        } else {
          _employee = Employee.fromJson(map);
        }
        _role = role;
      } catch (_) {
        // Corrupt cache: ignore and rely on /me below.
      }
    }

    try {
      if (role == AppRole.cashier) {
        _user = await _authService.cashierMe();
        await _tokenStorage.saveProfile(jsonEncode(_user!.toJson()));
      } else {
        _employee = await _authService.employeeMe();
        await _tokenStorage.saveProfile(jsonEncode(_employee!.toJson()));
      }
      _role = role;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        // Token genuinely invalid/expired: drop it and require login.
        _api.token = null;
        await _tokenStorage.clear();
        _user = null;
        _employee = null;
        _role = null;
      } else {
        // Server/validation hiccup: keep the (cached) session.
        _role = role;
      }
    } catch (_) {
      // Network/offline or unexpected error: keep the saved session so the
      // user isn't forced to log in again every restart.
      _role = role;
    } finally {
      _bootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> loginCashier({
    required String email,
    required String password,
    String deviceName = 'mobile',
  }) async {
    final result = await _authService.cashierLogin(
      email: email,
      password: password,
      deviceName: deviceName,
    );
    await _tokenStorage.save(token: result.token, role: AppRole.cashier);
    await _tokenStorage.saveProfile(jsonEncode(result.user.toJson()));
    _api.token = result.token;
    _user = result.user;
    _employee = null;
    _role = AppRole.cashier;
    notifyListeners();
  }

  Future<void> loginEmployee({
    required String phone,
    required String password,
    String deviceName = 'mobile',
    String? deviceId,
  }) async {
    final result = await _authService.employeeLogin(
      phone: phone,
      password: password,
      deviceName: deviceName,
      deviceId: deviceId,
    );
    await _tokenStorage.save(token: result.token, role: AppRole.employee);
    await _tokenStorage.saveProfile(jsonEncode(result.employee.toJson()));
    _api.token = result.token;
    _employee = result.employee;
    _user = null;
    _role = AppRole.employee;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      if (_role == AppRole.cashier) {
        await _authService.cashierLogout();
      } else if (_role == AppRole.employee) {
        await _authService.employeeLogout();
      }
    } catch (_) {
      // Ignore network errors during logout; we clear locally regardless.
    }
    await _clearSession();
  }

  void _handleUnauthorized() {
    // Token rejected by the server mid-session.
    _clearSession();
  }

  Future<void> _clearSession() async {
    _api.token = null;
    await _tokenStorage.clear();
    _user = null;
    _employee = null;
    _role = null;
    notifyListeners();
  }
}

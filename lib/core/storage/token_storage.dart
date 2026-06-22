import 'package:shared_preferences/shared_preferences.dart';

/// Roles supported by the app. Determines which UI is shown after login.
enum AppRole { cashier, employee }

/// Persists the auth token and the active role using [SharedPreferences].
class TokenStorage {
  TokenStorage([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _kToken = 'auth_token';
  static const _kRole = 'auth_role';
  static const _kProfile = 'auth_profile';

  Future<SharedPreferences> get _instance async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<void> save({required String token, required AppRole role}) async {
    final prefs = await _instance;
    await prefs.setString(_kToken, token);
    await prefs.setString(_kRole, role.name);
  }

  /// Persists the serialized profile (AppUser or Employee) as JSON.
  Future<void> saveProfile(String profileJson) async {
    final prefs = await _instance;
    await prefs.setString(_kProfile, profileJson);
  }

  Future<String?> readProfile() async {
    final prefs = await _instance;
    return prefs.getString(_kProfile);
  }

  Future<String?> readToken() async {
    final prefs = await _instance;
    return prefs.getString(_kToken);
  }

  Future<AppRole?> readRole() async {
    final prefs = await _instance;
    final value = prefs.getString(_kRole);
    if (value == null) return null;
    return AppRole.values.where((r) => r.name == value).firstOrNull;
  }

  Future<void> clear() async {
    final prefs = await _instance;
    await prefs.remove(_kToken);
    await prefs.remove(_kRole);
    await prefs.remove(_kProfile);
  }
}

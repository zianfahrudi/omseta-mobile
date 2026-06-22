import 'store.dart';

/// Authenticated cashier/admin user.
class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.stores = const [],
  });

  final int id;
  final String name;
  final String email;
  final String role;
  final List<Store> stores;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawStores = json['stores'] as List<dynamic>? ?? const [];
    return AppUser(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'cashier',
      stores: rawStores
          .map((e) => Store.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
    'stores': stores.map((s) => s.toJson()).toList(),
  };
}

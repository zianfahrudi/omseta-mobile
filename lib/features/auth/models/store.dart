/// An outlet the cashier can operate.
class Store {
  Store({
    required this.id,
    required this.name,
    required this.code,
    this.phone,
    this.address,
    this.isActive = true,
  });

  final int id;
  final String name;
  final String code;
  final String? phone;
  final String? address;
  final bool isActive;

  factory Store.fromJson(Map<String, dynamic> json) {
    return Store(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'phone': phone,
    'address': address,
    'is_active': isActive,
  };
}

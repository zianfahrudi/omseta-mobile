/// A vehicle belonging to a customer (workshop businesses).
class Vehicle {
  Vehicle({
    required this.id,
    this.name,
    required this.plateNumber,
    this.mileage,
  });

  final int id;
  final String? name;
  final String plateNumber;
  final num? mileage;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as int,
      name: json['name'] as String?,
      plateNumber: json['plate_number'] as String? ?? '',
      mileage: json['mileage'] as num?,
    );
  }
}

/// A registered customer.
class Customer {
  Customer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.outstandingDebt = 0,
    this.vehicles = const [],
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final num outstandingDebt;
  final List<Vehicle> vehicles;

  factory Customer.fromJson(Map<String, dynamic> json) {
    final rawVehicles = json['vehicles'] as List<dynamic>? ?? const [];
    return Customer(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      outstandingDebt: (json['outstanding_debt'] as num?) ?? 0,
      vehicles: rawVehicles
          .map((e) => Vehicle.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// The attendance point (geofence target) assigned to an employee.
class AttendanceLocation {
  AttendanceLocation({
    required this.id,
    required this.name,
    this.address,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
  });

  final int id;
  final String name;
  final String? address;
  final double latitude;
  final double longitude;
  final int radiusMeters;

  factory AttendanceLocation.fromJson(Map<String, dynamic> json) {
    return AttendanceLocation(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num?)?.toInt() ?? 100,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'radius_meters': radiusMeters,
  };
}

/// Authenticated employee (separate identity from [AppUser]).
class Employee {
  Employee({
    required this.id,
    required this.code,
    required this.name,
    required this.phone,
    this.position,
    this.location,
  });

  final int id;
  final String code;
  final String name;
  final String phone;
  final String? position;
  final AttendanceLocation? location;

  factory Employee.fromJson(Map<String, dynamic> json) {
    final loc = json['location'];
    return Employee(
      id: json['id'] as int,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      position: json['position'] as String?,
      location: loc is Map<String, dynamic>
          ? AttendanceLocation.fromJson(loc)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'phone': phone,
    'position': position,
    'location': location?.toJson(),
  };
}

/// An active staff member (mechanic / salesman) that can be attached to a sale
/// line. Sourced from `GET /employees`.
class StaffMember {
  StaffMember({required this.id, required this.name, this.code, this.position});

  final int id;
  final String name;
  final String? code;
  final String? position;

  /// `Budi Mekanik · Mekanik`
  String get label =>
      position == null || position!.isEmpty ? name : '$name · $position';

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String?,
      position: json['position'] as String?,
    );
  }
}

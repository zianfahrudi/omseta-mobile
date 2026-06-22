/// Result of the `/pricing` calculation endpoint.
class Pricing {
  Pricing({
    this.discountCode,
    this.discountName,
    this.discountType,
    this.discountValue = 0,
    this.discountTotal = 0,
    this.taxPercentage = 0,
    this.taxTotal = 0,
    this.serviceFeePercentage = 0,
    this.serviceFeeTotal = 0,
    required this.grandTotal,
  });

  final String? discountCode;
  final String? discountName;
  final String? discountType;
  final num discountValue;
  final num discountTotal;
  final num taxPercentage;
  final num taxTotal;
  final num serviceFeePercentage;
  final num serviceFeeTotal;
  final num grandTotal;

  factory Pricing.fromJson(Map<String, dynamic> json) {
    return Pricing(
      discountCode: json['discount_code'] as String?,
      discountName: json['discount_name'] as String?,
      discountType: json['discount_type'] as String?,
      discountValue: (json['discount_value'] as num?) ?? 0,
      discountTotal: (json['discount_total'] as num?) ?? 0,
      taxPercentage: (json['tax_percentage'] as num?) ?? 0,
      taxTotal: (json['tax_total'] as num?) ?? 0,
      serviceFeePercentage: (json['service_fee_percentage'] as num?) ?? 0,
      serviceFeeTotal: (json['service_fee_total'] as num?) ?? 0,
      grandTotal: (json['grand_total'] as num?) ?? 0,
    );
  }
}

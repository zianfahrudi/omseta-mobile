/// A sellable product/service at an outlet.
class Product {
  Product({
    required this.id,
    required this.name,
    required this.code,
    this.barcode,
    this.sku,
    this.imageUrl,
    required this.productType,
    required this.unitPrice,
    this.feeAmount = 0,
    this.taxAmount = 0,
    required this.stock,
    this.unit,
  });

  final int id;
  final String name;
  final String code;
  final String? barcode;
  final String? sku;
  final String? imageUrl;
  final String productType; // goods | service
  final num unitPrice;
  final num feeAmount;
  final num taxAmount;
  final num stock;
  final String? unit;

  bool get isService => productType == 'service';

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      imageUrl: json['image_url'] as String?,
      productType: json['product_type'] as String? ?? 'goods',
      unitPrice: (json['unit_price'] as num?) ?? (json['price'] as num?) ?? 0,
      feeAmount: (json['fee_amount'] as num?) ?? 0,
      taxAmount: (json['product_tax_amount'] as num?) ?? 0,
      stock: (json['stock'] as num?) ?? 0,
      unit: json['unit'] as String?,
    );
  }
}

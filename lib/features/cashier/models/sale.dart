/// A single line item within a sale.
class SaleItem {
  SaleItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.productType,
    this.employeeId,
    this.employeeName,
    required this.quantity,
    this.refundedQuantity = 0,
    this.refundableQuantity = 0,
    required this.unitPrice,
    this.serviceFeeAmount = 0,
    this.taxAmount = 0,
    required this.lineTotal,
  });

  final int id;
  final int productId;
  final String name;
  final String productType;
  final int? employeeId;
  final String? employeeName;
  final num quantity;
  final num refundedQuantity;
  final num refundableQuantity;
  final num unitPrice;
  final num serviceFeeAmount;
  final num taxAmount;
  final num lineTotal;

  factory SaleItem.fromJson(Map<String, dynamic> json) {
    return SaleItem(
      id: json['id'] as int,
      productId: json['product_id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      productType: json['product_type'] as String? ?? 'goods',
      employeeId: json['employee_id'] as int?,
      employeeName: json['employee_name'] as String?,
      quantity: (json['quantity'] as num?) ?? 0,
      refundedQuantity: (json['refunded_quantity'] as num?) ?? 0,
      refundableQuantity: (json['refundable_quantity'] as num?) ?? 0,
      unitPrice: (json['unit_price'] as num?) ?? 0,
      serviceFeeAmount: (json['service_fee_amount'] as num?) ?? 0,
      taxAmount: (json['tax_amount'] as num?) ?? 0,
      lineTotal: (json['line_total'] as num?) ?? 0,
    );
  }
}

/// A tender entry on a sale (for combined / split payments).
class SalePayment {
  SalePayment({
    required this.method,
    required this.amount,
    this.isSettlement = false,
    this.paidAt,
  });

  final String method;
  final num amount;
  final bool isSettlement;
  final String? paidAt;

  factory SalePayment.fromJson(Map<String, dynamic> json) {
    return SalePayment(
      method: json['method'] as String? ?? '',
      amount: (json['amount'] as num?) ?? 0,
      isSettlement: json['is_settlement'] as bool? ?? false,
      paidAt: json['paid_at'] as String?,
    );
  }
}

/// A completed (or debt) sale transaction.
class Sale {
  Sale({
    required this.id,
    required this.number,
    this.storeName,
    this.cashierName,
    this.customerName,
    this.customerPhone,
    this.vehiclePlateNumber,
    required this.status,
    required this.paymentMethod,
    this.paymentProof,
    required this.paymentStatus,
    this.paymentStatusLabel,
    this.subtotal = 0,
    this.discountTotal = 0,
    this.taxTotal = 0,
    this.serviceFeeTotal = 0,
    required this.grandTotal,
    this.paidAmount = 0,
    this.changeAmount = 0,
    this.isDebt = false,
    this.debtAmount = 0,
    this.paidAt,
    this.items = const [],
    this.payments = const [],
  });

  final int id;
  final String number;
  final String? storeName;
  final String? cashierName;
  final String? customerName;
  final String? customerPhone;
  final String? vehiclePlateNumber;
  final String status;
  final String paymentMethod;
  final String? paymentProof;
  final String paymentStatus;
  final String? paymentStatusLabel;
  final num subtotal;
  final num discountTotal;
  final num taxTotal;
  final num serviceFeeTotal;
  final num grandTotal;
  final num paidAmount;
  final num changeAmount;
  final bool isDebt;
  final num debtAmount;
  final String? paidAt;
  final List<SaleItem> items;
  final List<SalePayment> payments;

  bool get isPaid => paymentStatus == 'lunas';

  factory Sale.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    final rawPayments = json['payments'] as List<dynamic>? ?? const [];
    return Sale(
      id: json['id'] as int,
      number: json['number'] as String? ?? '',
      storeName: json['store_name'] as String?,
      cashierName: json['cashier_name'] as String?,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      vehiclePlateNumber: json['vehicle_plate_number'] as String?,
      status: json['status'] as String? ?? 'completed',
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      paymentProof: json['payment_proof'] as String?,
      paymentStatus: json['payment_status'] as String? ?? 'lunas',
      paymentStatusLabel: json['payment_status_label'] as String?,
      subtotal: (json['subtotal'] as num?) ?? 0,
      discountTotal: (json['discount_total'] as num?) ?? 0,
      taxTotal: (json['tax_total'] as num?) ?? 0,
      serviceFeeTotal: (json['service_fee_total'] as num?) ?? 0,
      grandTotal: (json['grand_total'] as num?) ?? 0,
      paidAmount: (json['paid_amount'] as num?) ?? 0,
      changeAmount: (json['change_amount'] as num?) ?? 0,
      isDebt: json['is_debt'] as bool? ?? false,
      debtAmount: (json['debt_amount'] as num?) ?? 0,
      paidAt: json['paid_at'] as String?,
      items: rawItems
          .map((e) => SaleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: rawPayments
          .map((e) => SalePayment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

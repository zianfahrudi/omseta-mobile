/// A cashier shift session (open/close cash drawer).
class CashierSession {
  CashierSession({
    required this.id,
    required this.number,
    required this.storeId,
    this.storeName,
    this.cashierName,
    required this.status,
    this.openedAt,
    this.closedAt,
    this.openingCash = 0,
    this.cashSalesTotal = 0,
    this.expectedCash = 0,
    this.closingCash = 0,
    this.cashDifference = 0,
    this.notes,
  });

  final int id;
  final String number;
  final int storeId;
  final String? storeName;
  final String? cashierName;
  final String status; // open | closed
  final String? openedAt;
  final String? closedAt;
  final num openingCash;
  final num cashSalesTotal;
  final num expectedCash;
  final num closingCash;
  final num cashDifference;
  final String? notes;

  bool get isOpen => status == 'open';

  /// Expected cash while the session is still open. The server only finalizes
  /// `expected_cash` at close (returns 0 before), so we compute it live as
  /// modal awal + penjualan tunai.
  num get expectedCashLive =>
      expectedCash > 0 ? expectedCash : openingCash + cashSalesTotal;

  factory CashierSession.fromJson(Map<String, dynamic> json) {
    return CashierSession(
      id: json['id'] as int,
      number: json['number'] as String? ?? '',
      storeId: json['store_id'] as int? ?? 0,
      storeName: json['store_name'] as String?,
      cashierName: json['cashier_name'] as String?,
      status: json['status'] as String? ?? 'open',
      openedAt: json['opened_at'] as String?,
      closedAt: json['closed_at'] as String?,
      openingCash: (json['opening_cash'] as num?) ?? 0,
      cashSalesTotal: (json['cash_sales_total'] as num?) ?? 0,
      expectedCash: (json['expected_cash'] as num?) ?? 0,
      closingCash: (json['closing_cash'] as num?) ?? 0,
      cashDifference: (json['cash_difference'] as num?) ?? 0,
      notes: json['notes'] as String?,
    );
  }
}

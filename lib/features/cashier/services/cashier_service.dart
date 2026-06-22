import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../models/cashier_session.dart';
import '../models/customer.dart';
import '../models/pricing.dart';
import '../models/product.dart';
import '../models/receipt_settings.dart';
import '../models/sale.dart';
import '../models/staff_member.dart';

/// One line in the checkout cart.
class CheckoutItem {
  CheckoutItem({
    required this.productId,
    required this.quantity,
    this.employeeId,
  });
  final int productId;
  final int quantity;
  final int? employeeId;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'quantity': quantity,
    if (employeeId != null) 'employee_id': employeeId,
  };
}

/// One tender line for combined (split) payments.
class PaymentEntry {
  PaymentEntry({required this.method, required this.amount});
  final String method; // cash | qris | transfer
  final num amount;

  Map<String, dynamic> toJson() => {'method': method, 'amount': amount};
}

/// Calls the cashier (POS) endpoints.
class CashierService {
  CashierService(this._api);

  final ApiClient _api;

  Future<List<Product>> products({
    required int storeId,
    String? query,
    int? productId,
  }) async {
    final data = await _api.get(
      '/products',
      query: {
        'store_id': storeId,
        if (query != null && query.isNotEmpty) 'q': query,
        if (productId != null) 'product_id': productId,
      },
    );
    return _list(data).map((e) => Product.fromJson(e)).toList();
  }

  Future<List<Customer>> customers({
    required int storeId,
    String? query,
  }) async {
    final data = await _api.get(
      '/customers',
      query: {
        'store_id': storeId,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return _list(data).map((e) => Customer.fromJson(e)).toList();
  }

  /// Active staff (mechanic/salesman) for the outlet's company. Used for the
  /// per-item employee dropdown at checkout.
  Future<List<StaffMember>> employees({
    required int storeId,
    String? query,
  }) async {
    final data = await _api.get(
      '/employees',
      query: {
        'store_id': storeId,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return _list(data).map((e) => StaffMember.fromJson(e)).toList();
  }

  Future<Customer> createCustomer({
    required int storeId,
    required String name,
    String? phone,
    String? vehiclePlateNumber,
    num? vehicleMileage,
  }) async {
    final data = await _api.post(
      '/customers',
      data: {
        'store_id': storeId,
        'name': name,
        if (phone != null) 'phone': phone,
        if (vehiclePlateNumber != null)
          'vehicle_plate_number': vehiclePlateNumber,
        if (vehicleMileage != null) 'vehicle_mileage': vehicleMileage,
      },
    );
    return Customer.fromJson(_single(data));
  }

  Future<Pricing> pricing({
    required int storeId,
    required num subtotal,
    String? discountCode,
  }) async {
    // Backend route is GET (PricingController::show reads query params).
    final data = await _api.get(
      '/pricing',
      query: {
        'store_id': storeId,
        'subtotal': subtotal,
        if (discountCode != null && discountCode.isNotEmpty)
          'discount_code': discountCode,
      },
    );
    return Pricing.fromJson((data['pricing'] as Map).cast<String, dynamic>());
  }

  Future<Sale> checkout({
    required int storeId,
    required String paymentMethod, // cash | qris | transfer | split
    required num paidAmount,
    required List<CheckoutItem> items,
    List<PaymentEntry> payments = const [],
    int? customerId,
    String? customerName,
    String? customerPhone,
    String? discountCode,
    bool isDebt = false,
    String? paymentProofPath,
  }) async {
    Object payload;
    if (paymentProofPath != null) {
      final form = FormData.fromMap({
        'store_id': storeId,
        'payment_method': paymentMethod,
        'paid_amount': paidAmount,
        'is_debt': isDebt ? 1 : 0,
        if (customerId != null) 'customer_id': customerId,
        if (customerName != null) 'customer_name': customerName,
        if (customerPhone != null) 'customer_phone': customerPhone,
        if (discountCode != null && discountCode.isNotEmpty)
          'discount_code': discountCode,
        'payment_proof': await MultipartFile.fromFile(paymentProofPath),
      });
      // items[] / payments[] need to be appended individually for multipart.
      for (var i = 0; i < items.length; i++) {
        form.fields
          ..add(MapEntry('items[$i][product_id]', '${items[i].productId}'))
          ..add(MapEntry('items[$i][quantity]', '${items[i].quantity}'));
        if (items[i].employeeId != null) {
          form.fields.add(
            MapEntry('items[$i][employee_id]', '${items[i].employeeId}'),
          );
        }
      }
      for (var i = 0; i < payments.length; i++) {
        form.fields
          ..add(MapEntry('payments[$i][method]', payments[i].method))
          ..add(MapEntry('payments[$i][amount]', '${payments[i].amount}'));
      }
      payload = form;
    } else {
      payload = {
        'store_id': storeId,
        'payment_method': paymentMethod,
        'paid_amount': paidAmount,
        'is_debt': isDebt,
        if (customerId != null) 'customer_id': customerId,
        if (customerName != null) 'customer_name': customerName,
        if (customerPhone != null) 'customer_phone': customerPhone,
        if (discountCode != null && discountCode.isNotEmpty)
          'discount_code': discountCode,
        if (payments.isNotEmpty)
          'payments': payments.map((e) => e.toJson()).toList(),
        'items': items.map((e) => e.toJson()).toList(),
      };
    }

    final data = await _api.post('/checkout', data: payload);
    return Sale.fromJson(_single(data));
  }

  Future<List<Sale>> transactions({required int storeId, String? query}) async {
    final data = await _api.get(
      '/transactions',
      query: {
        'store_id': storeId,
        if (query != null && query.isNotEmpty) 'q': query,
      },
    );
    return _list(data).map((e) => Sale.fromJson(e)).toList();
  }

  Future<Sale> markPaid(int saleId) async {
    final data = await _api.post('/transactions/$saleId/mark-paid');
    return Sale.fromJson(_single(data));
  }

  /// Voids (cancels) a completed sale: reverses the journal, returns stock and
  /// reverts customer debt (server-side via SaleVoidService).
  Future<Sale> voidSale(int saleId) async {
    final data = await _api.post('/transactions/$saleId/void');
    return Sale.fromJson(_single(data));
  }

  /// Company invoice/receipt settings ("Pengaturan Faktur"). Returns null when
  /// the endpoint is unavailable so callers can fall back gracefully.
  Future<ReceiptSettings?> receiptSettings({int? storeId}) async {
    try {
      final data = await _api.get(
        '/receipt-settings',
        query: {if (storeId != null) 'store_id': storeId},
      );
      final map = (data is Map && data['data'] is Map)
          ? (data['data'] as Map).cast<String, dynamic>()
          : (data as Map).cast<String, dynamic>();
      return ReceiptSettings.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // --- Cashier sessions ---

  Future<CashierSession?> currentSession(int storeId) async {
    final data = await _api.get(
      '/cashier-sessions/current',
      query: {'store_id': storeId},
    );
    final session = data['session'];
    if (session == null) return null;
    return CashierSession.fromJson((session as Map).cast<String, dynamic>());
  }

  Future<CashierSession> openSession({
    required int storeId,
    required num openingCash,
  }) async {
    final data = await _api.post(
      '/cashier-sessions/open',
      data: {'store_id': storeId, 'opening_cash': openingCash},
    );
    return CashierSession.fromJson(_single(data));
  }

  Future<CashierSession> closeSession({
    required int sessionId,
    required num countedCash,
    String? notes,
  }) async {
    final data = await _api.post(
      '/cashier-sessions/$sessionId/close',
      data: {'counted_cash': countedCash, if (notes != null) 'notes': notes},
    );
    return CashierSession.fromJson(_single(data));
  }

  // --- helpers ---

  List<Map<String, dynamic>> _list(dynamic data) {
    final raw = (data is Map && data['data'] != null) ? data['data'] : data;
    if (raw is List) {
      return raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    return const [];
  }

  Map<String, dynamic> _single(dynamic data) {
    if (data is Map && data['data'] is Map) {
      return (data['data'] as Map).cast<String, dynamic>();
    }
    return (data as Map).cast<String, dynamic>();
  }
}

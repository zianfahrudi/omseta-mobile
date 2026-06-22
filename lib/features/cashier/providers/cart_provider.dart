import 'package:flutter/foundation.dart';

import '../models/customer.dart';
import '../models/pricing.dart';
import '../models/product.dart';
import '../models/staff_member.dart';

/// A product plus the quantity currently in the cart.
class CartLine {
  CartLine({required this.product, this.quantity = 1, this.employee});
  final Product product;
  int quantity;

  /// Optional staff member (mechanic/salesman) who handled this item.
  StaffMember? employee;

  num get lineTotal => product.unitPrice * quantity;
}

/// Holds the active outlet selection and the in-progress cart. Shared across
/// the cashier screens.
class CartProvider extends ChangeNotifier {
  int? _storeId;
  int? get storeId => _storeId;

  final Map<int, CartLine> _lines = {};
  List<CartLine> get lines => _lines.values.toList();

  Customer? _customer;
  Customer? get customer => _customer;

  String? _discountCode;
  String? get discountCode => _discountCode;

  Pricing? _pricing;
  Pricing? get pricing => _pricing;

  /// Increments every time a checkout completes. Screens (e.g. the cashier
  /// session) can watch this to refresh server-computed totals.
  int _salesVersion = 0;
  int get salesVersion => _salesVersion;

  /// Signal that a sale was successfully completed.
  void markSaleCompleted() {
    _salesVersion++;
    notifyListeners();
  }

  bool get isEmpty => _lines.isEmpty;
  int get itemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);

  num get subtotal =>
      _lines.values.fold<num>(0, (sum, line) => sum + line.lineTotal);

  num get grandTotal => _pricing?.grandTotal ?? subtotal;

  void setStore(int? storeId) {
    if (_storeId == storeId) return;
    _storeId = storeId;
    clear();
  }

  void add(Product product) {
    final existing = _lines[product.id];
    if (existing != null) {
      existing.quantity += 1;
    } else {
      _lines[product.id] = CartLine(product: product);
    }
    _pricing = null; // recalc needed
    notifyListeners();
  }

  void setQuantity(int productId, int quantity) {
    final line = _lines[productId];
    if (line == null) return;
    if (quantity <= 0) {
      _lines.remove(productId);
    } else {
      line.quantity = quantity;
    }
    _pricing = null;
    notifyListeners();
  }

  void remove(int productId) {
    _lines.remove(productId);
    _pricing = null;
    notifyListeners();
  }

  /// Assign (or clear) the staff member who handled a cart line.
  void setLineEmployee(int productId, StaffMember? employee) {
    final line = _lines[productId];
    if (line == null) return;
    line.employee = employee;
    notifyListeners();
  }

  void setCustomer(Customer? customer) {
    _customer = customer;
    notifyListeners();
  }

  void setDiscountCode(String? code) {
    _discountCode = (code == null || code.isEmpty) ? null : code;
    _pricing = null;
    notifyListeners();
  }

  void setPricing(Pricing? pricing) {
    _pricing = pricing;
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    _customer = null;
    _discountCode = null;
    _pricing = null;
    notifyListeners();
  }
}

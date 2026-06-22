/// Company invoice/receipt settings ("Pengaturan Faktur") used to render the
/// printed receipt header & footer. Sourced from the backend; falls back to
/// sensible defaults when unavailable.
class ReceiptSettings {
  ReceiptSettings({
    required this.name,
    this.address,
    this.phone,
    this.email,
    this.note,
    this.bankName,
    this.bankAccount,
    this.bankHolder,
    this.paperWidth = 32,
  });

  final String name;
  final String? address;
  final String? phone;
  final String? email;
  final String? note;
  final String? bankName;
  final String? bankAccount;
  final String? bankHolder;

  /// Characters per line: 32 for 58mm, 48 for 80mm paper.
  final int paperWidth;

  bool get hasBank =>
      (bankName?.isNotEmpty ?? false) || (bankAccount?.isNotEmpty ?? false);

  factory ReceiptSettings.fromJson(Map<String, dynamic> json) {
    return ReceiptSettings(
      name: json['name'] as String? ?? '',
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      note: json['invoice_note'] as String? ?? json['note'] as String?,
      bankName: json['invoice_bank_name'] as String?,
      bankAccount: json['invoice_bank_account'] as String?,
      bankHolder: json['invoice_bank_holder'] as String?,
      paperWidth: (json['paper_width'] as num?)?.toInt() ?? 32,
    );
  }

  /// Minimal fallback built from the outlet name only.
  factory ReceiptSettings.fallback(String storeName) =>
      ReceiptSettings(name: storeName);
}

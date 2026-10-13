/// A billing invoice (mock in v1) shown in Settings → Billing.
class Invoice {
  const Invoice({
    required this.id,
    required this.amountCents,
    required this.currency,
    required this.description,
    required this.status,
    required this.issuedAt,
    this.paidAt,
  });

  final String id;
  final int amountCents;
  final String currency;
  final String description;
  final String status; // 'paid' | 'pending' | 'void'
  final DateTime issuedAt;
  final DateTime? paidAt;

  bool get isPaid => status == 'paid';

  /// e.g. "60.00 EUR".
  String get formattedAmount =>
      '${(amountCents / 100).toStringAsFixed(2)} $currency';

  factory Invoice.fromJson(Map<String, dynamic> json) => Invoice(
        id: json['id'] as String,
        amountCents: (json['amount_cents'] as num).toInt(),
        currency: (json['currency'] as String?) ?? 'EUR',
        description: (json['description'] as String?) ?? '',
        status: (json['status'] as String?) ?? 'paid',
        issuedAt: DateTime.parse(json['issued_at'] as String).toLocal(),
        paidAt: json['paid_at'] == null
            ? null
            : DateTime.parse(json['paid_at'] as String).toLocal(),
      );
}

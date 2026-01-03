class Invoice {
  final String? id;
  final String invoiceNumber;
  final DateTime createdAt;
  final double total;

  Invoice({
    this.id,
    required this.invoiceNumber,
    required this.createdAt,
    required this.total,
  });

  Map<String, dynamic> toJson() {
    return {'invoiceNumber': invoiceNumber, 'total': total};
  }

  static Invoice fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id']?.toString(),
      invoiceNumber: json['invoiceNumber'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

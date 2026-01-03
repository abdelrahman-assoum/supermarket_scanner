class InvoiceItem {
  final String? id;
  final String invoiceId;
  final String barcode;
  final String nameSnapshot;
  final double priceSnapshot;
  final int qty;
  final double lineTotal;

  InvoiceItem({
    this.id,
    required this.invoiceId,
    required this.barcode,
    required this.nameSnapshot,
    required this.priceSnapshot,
    required this.qty,
    required this.lineTotal,
  });

  Map<String, dynamic> toJson() {
    return {
      'invoice_id': invoiceId,
      'product_id': barcode,
      'nameSnapshot': nameSnapshot,
      'priceSnapshot': priceSnapshot,
      'qty': qty,
      'lineTotal': lineTotal,
    };
  }

  static InvoiceItem fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id']?.toString(),
      invoiceId:
          json['invoice_id']?.toString() ?? json['invoiceId']?.toString() ?? '',
      barcode:
          json['product_id']?.toString() ?? json['barcode']?.toString() ?? '',
      nameSnapshot: json['nameSnapshot'] ?? '',
      priceSnapshot: (json['priceSnapshot'] as num?)?.toDouble() ?? 0.0,
      qty: (json['qty'] as num?)?.toInt() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

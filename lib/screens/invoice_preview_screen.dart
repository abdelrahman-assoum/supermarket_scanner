import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/db.dart';
import '../models/invoice_item.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final String invoiceId;
  const InvoicePreviewScreen({super.key, required this.invoiceId});

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  List<InvoiceItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoiceItems();
  }

  Future<void> _loadInvoiceItems() async {
    setState(() => _loading = true);
    final db = context.read<Db>();
    try {
      final items = await db.getInvoiceItems(widget.invoiceId);
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading invoice items: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0.0, (s, it) => s + it.lineTotal);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.receipt, size: 28),
            SizedBox(width: 12),
            Text('Invoice Preview'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Color(0xFF1E88E5),
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Store POS',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E88E5),
                                  ),
                                ),
                                Text(
                                  'Point of Sale System',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF757575),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(
                              Icons.receipt_long,
                              size: 18,
                              color: Color(0xFF64B5F6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Invoice ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.invoiceId,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                        const Divider(height: 32),
                        if (_items.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'No items in this invoice',
                                style: TextStyle(color: Color(0xFF757575)),
                              ),
                            ),
                          )
                        else
                          ..._items.map(
                            (it) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'x${it.qty}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E88E5),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          it.nameSnapshot,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF424242),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '\$${it.priceSnapshot.toStringAsFixed(2)} each',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '\$${it.lineTotal.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E88E5),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const Divider(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF64B5F6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.payments,
                                color: Colors.white,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '\$${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 24),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Export as PDF',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onPressed: _items.isEmpty
                        ? null
                        : () async {
                            final pdf = pw.Document();

                            // Current date and time
                            final now = DateTime.now();
                            final dateStr =
                                '${now.day}/${now.month}/${now.year}';
                            final timeStr =
                                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

                            pdf.addPage(
                              pw.Page(
                                margin: const pw.EdgeInsets.all(32),
                                build: (ctx) => pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    // Header with store name and logo
                                    pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.spaceBetween,
                                      children: [
                                        pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.start,
                                          children: [
                                            pw.Text(
                                              'Store POS',
                                              style: pw.TextStyle(
                                                fontSize: 32,
                                                fontWeight: pw.FontWeight.bold,
                                                color: PdfColors.blue700,
                                              ),
                                            ),
                                            pw.SizedBox(height: 4),
                                            pw.Text(
                                              'Point of Sale System',
                                              style: pw.TextStyle(
                                                fontSize: 12,
                                                color: PdfColors.grey700,
                                              ),
                                            ),
                                          ],
                                        ),
                                        pw.Column(
                                          crossAxisAlignment:
                                              pw.CrossAxisAlignment.end,
                                          children: [
                                            pw.Text(
                                              'INVOICE',
                                              style: pw.TextStyle(
                                                fontSize: 24,
                                                fontWeight: pw.FontWeight.bold,
                                                color: PdfColors.grey800,
                                              ),
                                            ),
                                            pw.SizedBox(height: 4),
                                            pw.Text(
                                              '#${widget.invoiceId}',
                                              style: pw.TextStyle(
                                                fontSize: 14,
                                                color: PdfColors.grey700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    pw.SizedBox(height: 24),

                                    // Date and Time
                                    pw.Container(
                                      padding: const pw.EdgeInsets.all(12),
                                      decoration: pw.BoxDecoration(
                                        color: PdfColors.blue50,
                                        borderRadius: pw.BorderRadius.circular(
                                          8,
                                        ),
                                      ),
                                      child: pw.Row(
                                        mainAxisAlignment:
                                            pw.MainAxisAlignment.spaceBetween,
                                        children: [
                                          pw.Row(
                                            children: [
                                              pw.Text(
                                                'Date: ',
                                                style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                ),
                                              ),
                                              pw.Text(
                                                dateStr,
                                                style: const pw.TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          pw.Row(
                                            children: [
                                              pw.Text(
                                                'Time: ',
                                                style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                ),
                                              ),
                                              pw.Text(
                                                timeStr,
                                                style: const pw.TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    pw.SizedBox(height: 24),

                                    // Divider
                                    pw.Divider(
                                      thickness: 2,
                                      color: PdfColors.blue700,
                                    ),

                                    pw.SizedBox(height: 16),

                                    // Table header
                                    pw.Container(
                                      padding: const pw.EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 12,
                                      ),
                                      decoration: pw.BoxDecoration(
                                        color: PdfColors.blue100,
                                        borderRadius: pw.BorderRadius.circular(
                                          6,
                                        ),
                                      ),
                                      child: pw.Row(
                                        children: [
                                          pw.Expanded(
                                            flex: 3,
                                            child: pw.Text(
                                              'ITEM',
                                              style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          pw.SizedBox(
                                            width: 60,
                                            child: pw.Text(
                                              'QTY',
                                              textAlign: pw.TextAlign.center,
                                              style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          pw.SizedBox(
                                            width: 80,
                                            child: pw.Text(
                                              'PRICE',
                                              textAlign: pw.TextAlign.right,
                                              style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          pw.SizedBox(
                                            width: 100,
                                            child: pw.Text(
                                              'TOTAL',
                                              textAlign: pw.TextAlign.right,
                                              style: pw.TextStyle(
                                                fontSize: 11,
                                                fontWeight: pw.FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    pw.SizedBox(height: 8),

                                    // Items
                                    ..._items.map(
                                      (it) => pw.Container(
                                        padding: const pw.EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 12,
                                        ),
                                        decoration: pw.BoxDecoration(
                                          border: pw.Border(
                                            bottom: pw.BorderSide(
                                              color: PdfColors.grey300,
                                              width: 0.5,
                                            ),
                                          ),
                                        ),
                                        child: pw.Row(
                                          children: [
                                            pw.Expanded(
                                              flex: 3,
                                              child: pw.Text(
                                                it.nameSnapshot,
                                                style: const pw.TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            pw.SizedBox(
                                              width: 60,
                                              child: pw.Text(
                                                '${it.qty}',
                                                textAlign: pw.TextAlign.center,
                                                style: const pw.TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            pw.SizedBox(
                                              width: 80,
                                              child: pw.Text(
                                                '\$${it.priceSnapshot.toStringAsFixed(2)}',
                                                textAlign: pw.TextAlign.right,
                                                style: const pw.TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                            pw.SizedBox(
                                              width: 100,
                                              child: pw.Text(
                                                '\$${it.lineTotal.toStringAsFixed(2)}',
                                                textAlign: pw.TextAlign.right,
                                                style: pw.TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      pw.FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    pw.SizedBox(height: 16),

                                    // Subtotal and Total section
                                    pw.Row(
                                      mainAxisAlignment:
                                          pw.MainAxisAlignment.end,
                                      children: [
                                        pw.Container(
                                          width: 250,
                                          child: pw.Column(
                                            children: [
                                              pw.Divider(
                                                thickness: 1.5,
                                                color: PdfColors.grey400,
                                              ),
                                              pw.SizedBox(height: 12),
                                              pw.Row(
                                                mainAxisAlignment: pw
                                                    .MainAxisAlignment
                                                    .spaceBetween,
                                                children: [
                                                  pw.Text(
                                                    'Subtotal:',
                                                    style: pw.TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                    ),
                                                  ),
                                                  pw.Text(
                                                    '\$${total.toStringAsFixed(2)}',
                                                    style: const pw.TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              pw.SizedBox(height: 8),
                                              pw.Row(
                                                mainAxisAlignment: pw
                                                    .MainAxisAlignment
                                                    .spaceBetween,
                                                children: [
                                                  pw.Text(
                                                    'Tax (0%):',
                                                    style: pw.TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                    ),
                                                  ),
                                                  pw.Text(
                                                    '\$0.00',
                                                    style: const pw.TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              pw.SizedBox(height: 12),
                                              pw.Divider(
                                                thickness: 1.5,
                                                color: PdfColors.grey400,
                                              ),
                                              pw.SizedBox(height: 12),
                                              pw.Container(
                                                padding:
                                                    const pw.EdgeInsets.all(12),
                                                decoration: pw.BoxDecoration(
                                                  color: PdfColors.blue700,
                                                  borderRadius: pw
                                                      .BorderRadius.circular(8),
                                                ),
                                                child: pw.Row(
                                                  mainAxisAlignment: pw
                                                      .MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    pw.Text(
                                                      'TOTAL',
                                                      style: pw.TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color: PdfColors.white,
                                                      ),
                                                    ),
                                                    pw.Text(
                                                      '\$${total.toStringAsFixed(2)}',
                                                      style: pw.TextStyle(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        color: PdfColors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    pw.Spacer(),

                                    // Footer
                                    pw.Divider(color: PdfColors.grey300),
                                    pw.SizedBox(height: 8),
                                    pw.Center(
                                      child: pw.Text(
                                        'Thank you for your business!',
                                        style: pw.TextStyle(
                                          fontSize: 14,
                                          fontWeight: pw.FontWeight.bold,
                                          color: PdfColors.blue700,
                                        ),
                                      ),
                                    ),
                                    pw.SizedBox(height: 4),
                                    pw.Center(
                                      child: pw.Text(
                                        'Generated by Store POS System',
                                        style: pw.TextStyle(
                                          fontSize: 9,
                                          color: PdfColors.grey600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                            await Printing.sharePdf(
                              bytes: await pdf.save(),
                              filename: 'invoice_${widget.invoiceId}.pdf',
                            );
                          },
                  ),
                ),
              ],
            ),
    );
  }
}

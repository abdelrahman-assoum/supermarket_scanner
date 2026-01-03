import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../models/db.dart';
import '../models/invoice.dart';
import '../widgets/empty_state.dart';
import 'invoice_preview_screen.dart';
import 'product_details_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  List<Invoice> _invoices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _loading = true);
    final db = context.read<Db>();
    try {
      final invoices = await db.getInvoices();
      setState(() {
        _invoices = invoices;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();
    final db = context.read<Db>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.receipt_long, size: 28),
              SizedBox(width: 12),
              Text('Invoices'),
            ],
          ),
          bottom: TabBar(
            indicatorColor: const Color(0xFF64B5F6),
            labelColor: const Color(0xFF1E88E5),
            unselectedLabelColor: Colors.grey[600],
            tabs: const [
              Tab(icon: Icon(Icons.shopping_cart), text: 'Current Cart'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _loadInvoices,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: TabBarView(
          children: [
            // CURRENT CART
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (cart.isEmpty)
                    const Expanded(
                      child: EmptyState(
                        icon: Icons.shopping_cart_outlined,
                        title: 'Cart is empty',
                        subtitle: 'Add items by scanning or from inventory.',
                      ),
                    )
                  else
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.shopping_bag,
                                  color: Color(0xFF1E88E5),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${cart.items.length} ${cart.items.length == 1 ? 'item' : 'items'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: ListView.builder(
                              itemCount: cart.items.length,
                              itemBuilder: (context, i) {
                                final it = cart.items[i];
                                final lineTotal = it.priceSnapshot * it.qty;

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      children: [
                                        InkWell(
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ProductDetailsScreen(
                                                    barcode: it.barcode,
                                                  ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      it.nameSnapshot,
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Color(
                                                          0xFF424242,
                                                        ),
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Wrap(
                                                      spacing: 12,
                                                      runSpacing: 4,
                                                      children: [
                                                        Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            Icon(
                                                              Icons.qr_code,
                                                              size: 14,
                                                              color: Colors
                                                                  .grey[600],
                                                            ),
                                                            const SizedBox(
                                                              width: 4,
                                                            ),
                                                            Text(
                                                              it.barcode,
                                                              style: TextStyle(
                                                                fontSize: 13,
                                                                color: Colors
                                                                    .grey[600],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        Text(
                                                          '\$${it.priceSnapshot.toStringAsFixed(2)} each',
                                                          style: TextStyle(
                                                            fontSize: 13,
                                                            color: Colors
                                                                .grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Text(
                                                '\$${lineTotal.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1E88E5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFBBDEFB,
                                                  ),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    onPressed: it.qty > 1
                                                        ? () => cart.setQty(
                                                            it.barcode,
                                                            it.qty - 1,
                                                          )
                                                        : null,
                                                    icon: const Icon(
                                                      Icons.remove,
                                                      size: 20,
                                                    ),
                                                    color: const Color(
                                                      0xFF1E88E5,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                        ),
                                                    child: Text(
                                                      '${it.qty}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () async {
                                                      // Check stock before increasing
                                                      final product = await db
                                                          .getProduct(
                                                            it.barcode,
                                                          );
                                                      if (product == null)
                                                        return;

                                                      if (it.qty + 1 >
                                                          product.stock) {
                                                        if (!context.mounted)
                                                          return;
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            backgroundColor:
                                                                Colors.red[700],
                                                            content: Row(
                                                              children: [
                                                                const Icon(
                                                                  Icons
                                                                      .error_outline,
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                                const SizedBox(
                                                                  width: 12,
                                                                ),
                                                                Expanded(
                                                                  child: Text(
                                                                    'Cannot add more. Only ${product.stock} in stock',
                                                                    style: const TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        );
                                                        return;
                                                      }

                                                      cart.setQty(
                                                        it.barcode,
                                                        it.qty + 1,
                                                      );
                                                    },
                                                    icon: const Icon(
                                                      Icons.add,
                                                      size: 20,
                                                    ),
                                                    color: const Color(
                                                      0xFF1E88E5,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const Spacer(),
                                            IconButton(
                                              onPressed: () =>
                                                  cart.remove(it.barcode),
                                              icon: const Icon(
                                                Icons.delete_outline,
                                              ),
                                              color: Colors.red[400],
                                              tooltip: 'Remove item',
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Card(
                    color: const Color(0xFF64B5F6),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.receipt,
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
                            '\$${cart.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: cart.isEmpty
                          ? null
                          : () async {
                              try {
                                final id = await db.checkout(cart.items);
                                cart.clear();
                                if (!context.mounted) return;
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        InvoicePreviewScreen(invoiceId: id),
                                  ),
                                );
                                _loadInvoices(); // Refresh invoice list
                              } catch (e) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text('$e')));
                              }
                            },
                      icon: const Icon(Icons.payment, size: 24),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Checkout',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // HISTORY
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No invoices yet',
                    subtitle: 'Your completed invoices will appear here.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invoices.length,
                    itemBuilder: (context, i) {
                      final invoice = _invoices[i];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  InvoicePreviewScreen(invoiceId: invoice.id!),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE3F2FD),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.receipt,
                                    color: Color(0xFF1E88E5),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        invoice.invoiceNumber,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF424242),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.attach_money,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          Text(
                                            invoice.total.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey[400],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}

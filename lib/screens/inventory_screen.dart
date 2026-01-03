import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/db.dart';
import '../models/product.dart';
import '../widgets/empty_state.dart';
import 'add_product_screen.dart';
import 'product_details_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String q = '';
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    final db = context.read<Db>();
    try {
      final products = await db.getProducts();
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading products: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.inventory_2, size: 28),
            SizedBox(width: 12),
            Text('Inventory'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadProducts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF64B5F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddProductScreen()),
                );
                _loadProducts();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              tooltip: 'Add Product',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search products',
                hintText: 'Search by name or barcode',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64B5F6)),
                suffixIcon: q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => q = ''),
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => q = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Builder(
                    builder: (context) {
                      final filtered = _products
                          .where(
                            (p) =>
                                p.name.toLowerCase().contains(q) ||
                                p.barcode.toLowerCase().contains(q),
                          )
                          .toList();

                      if (filtered.isEmpty) {
                        return EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No products found',
                          subtitle: q.isEmpty
                              ? 'Add products to start scanning'
                              : 'No products match your search',
                          action: q.isEmpty
                              ? ElevatedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AddProductScreen(),
                                      ),
                                    );
                                    _loadProducts();
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Product'),
                                )
                              : null,
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          final lowStock = p.stock < 10;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailsScreen(
                                      barcode: p.barcode,
                                    ),
                                  ),
                                );
                                _loadProducts();
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: p.photoUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Image.network(
                                                p.photoUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                      Icons.inventory_2,
                                                      color: Color(0xFF64B5F6),
                                                      size: 28,
                                                    ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.inventory_2,
                                              color: Color(0xFF64B5F6),
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
                                            p.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF424242),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.qr_code,
                                                size: 14,
                                                color: Colors.grey[600],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                p.barcode,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: lowStock
                                                      ? Colors.red[50]
                                                      : const Color(0xFFE8F5E9),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      lowStock
                                                          ? Icons
                                                                .warning_amber_rounded
                                                          : Icons.check_circle,
                                                      size: 14,
                                                      color: lowStock
                                                          ? Colors.red[700]
                                                          : Colors.green[700],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Stock: ${p.stock}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: lowStock
                                                            ? Colors.red[700]
                                                            : Colors.green[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (p.category.isNotEmpty) ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFE3F2FD,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    p.category,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF1E88E5),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${p.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1E88E5),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.grey[400],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

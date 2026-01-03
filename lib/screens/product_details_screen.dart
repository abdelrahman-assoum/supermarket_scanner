import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/db.dart';
import '../models/cart.dart';
import '../models/product.dart';
import 'add_product_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String barcode;
  const ProductDetailsScreen({super.key, required this.barcode});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int qty = 1;

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Product Image'),
            actions: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 64,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<Db>();
    final cart = context.watch<Cart>();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shopping_bag, size: 28),
            SizedBox(width: 12),
            Text('Product Details'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Product',
            onPressed: () async {
              final product = await db.getProduct(widget.barcode);
              if (product == null) return;
              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductScreen(productToEdit: product),
                ),
              ).then((_) => setState(() {}));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Product',
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 12),
                      Text('Delete product?'),
                    ],
                  ),
                  content: Text(
                    'Barcode: ${widget.barcode}\n\nThis action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (ok == true) {
                await db.deleteProduct(widget.barcode);
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Product?>(
        future: db.getProduct(widget.barcode),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final p = snap.data;
          if (p == null) return const Center(child: Text('Not found'));

          final out = p.stock <= 0;
          final lowStock = p.stock < 10;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Product Image
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: p.photoUrl != null
                      ? () => _showFullScreenImage(context, p.photoUrl!)
                      : null,
                  child: Stack(
                    children: [
                      p.photoUrl != null
                          ? Image.network(
                              p.photoUrl!,
                              height: 250,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 250,
                                color: const Color(0xFFE3F2FD),
                                child: const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Color(0xFF64B5F6),
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              height: 250,
                              color: const Color(0xFFE3F2FD),
                              child: const Center(
                                child: Icon(
                                  Icons.inventory_2,
                                  size: 64,
                                  color: Color(0xFF64B5F6),
                                ),
                              ),
                            ),
                      if (p.photoUrl != null)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to zoom',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Product Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E88E5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.qr_code,
                              color: Color(0xFF1E88E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Barcode',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                p.barcode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF424242),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.attach_money,
                                      color: Color(0xFF64B5F6),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Price',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '\$${p.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E88E5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: out
                                  ? Colors.red[50]
                                  : lowStock
                                  ? Colors.orange[50]
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  out
                                      ? Icons.remove_circle
                                      : lowStock
                                      ? Icons.warning_amber_rounded
                                      : Icons.check_circle,
                                  color: out
                                      ? Colors.red[700]
                                      : lowStock
                                      ? Colors.orange[700]
                                      : Colors.green[700],
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  out
                                      ? 'Out of Stock'
                                      : lowStock
                                      ? 'Low Stock'
                                      : 'In Stock',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: out
                                        ? Colors.red[700]
                                        : lowStock
                                        ? Colors.orange[700]
                                        : Colors.green[700],
                                  ),
                                ),
                                Text(
                                  '${p.stock} units',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: out
                                        ? Colors.red[700]
                                        : lowStock
                                        ? Colors.orange[700]
                                        : Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (p.category.isNotEmpty) ...[
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(
                              Icons.category,
                              color: Color(0xFF64B5F6),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Category:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                p.category,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E88E5),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (p.description.isNotEmpty) ...[
                        const Divider(height: 32),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.description,
                              color: Color(0xFF64B5F6),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.description,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF424242),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Add to Cart Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                              Icons.shopping_cart,
                              color: Color(0xFF1E88E5),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Add to Invoice',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF424242),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                          if (lowStock || out)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text(
                                out ? '(Out of stock)' : '(Only ${p.stock} left)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: out ? Colors.red[700] : Colors.orange[700],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFBBDEFB),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: qty > 1
                                      ? () => setState(() => qty--)
                                      : null,
                                  icon: const Icon(Icons.remove, size: 20),
                                  color: const Color(0xFF1E88E5),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    '$qty',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: qty < p.stock
                                      ? () => setState(() => qty++)
                                      : null,
                                  icon: const Icon(Icons.add, size: 20),
                                  color: const Color(0xFF1E88E5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: out
                              ? null
                              : () {
                                  // Check current quantity in cart
                                  final currentInCart = cart.items
                                      .firstWhere(
                                        (item) => item.barcode == p.barcode,
                                        orElse: () => CartItem(
                                          barcode: '',
                                          nameSnapshot: '',
                                          priceSnapshot: 0,
                                          qty: 0,
                                        ),
                                      )
                                      .qty;

                                  final totalAfterAdd = currentInCart + qty;

                                  if (totalAfterAdd > p.stock) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        backgroundColor: Colors.red[700],
                                        content: Row(
                                          children: [
                                            const Icon(
                                              Icons.error_outline,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Cannot add $qty items. Only ${p.stock - currentInCart} available (${currentInCart} already in cart)',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  for (int i = 0; i < qty; i++) {
                                    cart.addOrInc(
                                      barcode: p.barcode,
                                      name: p.name,
                                      price: p.price,
                                    );
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: const Color(0xFF64B5F6),
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Added to cart ($qty ${qty == 1 ? 'item' : 'items'})',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                  setState(() => qty = 1);
                                },
                          icon: const Icon(Icons.add_shopping_cart, size: 24),
                          label: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              out ? 'Out of Stock' : 'Add to Cart',
                              style: const TextStyle(
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
              ),
            ],
          );
        },
      ),
    );
  }
}

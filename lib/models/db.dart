import 'product.dart';
import 'invoice.dart';
import 'invoice_item.dart';
import 'cart.dart';
import 'api_service.dart';

class Db {
  final _api = ApiService();

  // PRODUCTS
  Future<List<Product>> getProducts() async {
    return await _api.getProducts();
  }

  Future<Product?> getProduct(String barcode) async {
    return await _api.getProduct(barcode);
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    return await _api.getProductsByCategory(category);
  }

  Future<void> upsertProduct(Product p, {required bool create}) async {
    if (create) {
      await _api.createProduct(p);
    } else {
      await _api.updateProduct(p.barcode, p);
    }
  }

  Future<void> deleteProduct(String barcode) async {
    await _api.deleteProduct(barcode);
  }

  // INVOICES
  Future<List<Invoice>> getInvoices() async {
    return await _api.getInvoices();
  }

  Future<Invoice?> getInvoice(String id) async {
    return await _api.getInvoice(id);
  }

  Future<Invoice?> getInvoiceByNumber(String invoiceNumber) async {
    return await _api.getInvoiceByNumber(invoiceNumber);
  }

  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) async {
    return await _api.getInvoiceItemsByInvoice(invoiceId);
  }

  String makeInvoiceNumber() {
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return 'INV-${now.year}${two(now.month)}${two(now.day)}-${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  Future<String> checkout(List<CartItem> items) async {
    try {
      // Calculate total
      final total = items.fold<double>(0.0, (s, it) => s + it.lineTotal);

      // Create invoice
      final invoice = Invoice(
        invoiceNumber: makeInvoiceNumber(),
        createdAt: DateTime.now(),
        total: total,
      );

      print('Creating invoice with: ${invoice.toJson()}');
      final createdInvoice = await _api.createInvoice(invoice);
      final invoiceId = createdInvoice.id!;
      print('Created invoice with ID: $invoiceId');

      // Create invoice items
      for (final it in items) {
        final invoiceItem = InvoiceItem(
          invoiceId: invoiceId,
          barcode: it.barcode,
          nameSnapshot: it.nameSnapshot,
          priceSnapshot: it.priceSnapshot,
          qty: it.qty,
          lineTotal: it.lineTotal,
        );
        print('Creating invoice item: ${invoiceItem.toJson()}');
        await _api.createInvoiceItem(invoiceItem);

        // Update product stock
        final product = await _api.getProduct(it.barcode);
        if (product != null) {
          final updatedProduct = Product(
            barcode: product.barcode,
            name: product.name,
            price: product.price,
            stock: product.stock - it.qty,
            category: product.category,
            description: product.description,
            photoUrl: product.photoUrl,
          );
          await _api.updateProduct(product.barcode, updatedProduct);
        }
      }

      return invoiceId;
    } catch (e) {
      print('Checkout error: $e');
      rethrow;
    }
  }
}

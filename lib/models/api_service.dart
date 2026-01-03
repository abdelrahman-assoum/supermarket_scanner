import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product.dart';
import 'invoice.dart';
import 'invoice_item.dart';

class ApiService {
  final String baseUrl = "https://supermarket-backend-85ii.onrender.com";
  // final String baseUrl = "http://localhost:5000";

  // GET /products - Get all products
  Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else if (response.statusCode == 204) {
      return [];
    } else {
      throw Exception('Failed to load products');
    }
  }

  // GET /products/:id - Get product by barcode ID
  Future<Product?> getProduct(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/products/$id'));

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load product');
    }
  }

  // GET /products/category/:category - Get products by category
  Future<List<Product>> getProductsByCategory(String category) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/category/$category'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products by category');
    }
  }

  // POST /products - Create new product
  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return product;
    } else {
      final errorBody = response.body;
      throw Exception('Failed to create product: $errorBody');
    }
  }

  // PUT /products/:id - Update product
  Future<Product> updateProduct(String id, Product product) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(product.toJson()),
    );

    if (response.statusCode == 200) {
      return product;
    } else {
      final errorBody = response.body;
      throw Exception('Failed to update product: $errorBody');
    }
  }

  // DELETE /products/:id - Delete product
  // In api_service.dart, update the deleteProduct method:
  Future<void> deleteProduct(String id) async {
    print('Attempting to delete product with ID: $id');
    final response = await http.delete(Uri.parse('$baseUrl/products/$id'));

    print('Delete response status: ${response.statusCode}');
    print('Delete response body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete product: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // INVOICES

  // GET /invoices - Get all invoices (ordered by date)
  Future<List<Invoice>> getInvoices() async {
    final response = await http.get(Uri.parse('$baseUrl/invoices'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Invoice.fromJson(json)).toList();
    } else if (response.statusCode == 204) {
      return [];
    } else {
      throw Exception('Failed to load invoices');
    }
  }

  // GET /invoices/:id - Get invoice by ID
  Future<Invoice?> getInvoice(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/invoices/$id'));

    if (response.statusCode == 200) {
      return Invoice.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load invoice');
    }
  }

  // GET /invoices/number/:invoiceNumber - Get invoice by invoice number
  Future<Invoice?> getInvoiceByNumber(String invoiceNumber) async {
    final response = await http.get(
      Uri.parse('$baseUrl/invoices/number/$invoiceNumber'),
    );

    if (response.statusCode == 200) {
      return Invoice.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load invoice');
    }
  }

  // POST /invoices - Create new invoice
  Future<Invoice> createInvoice(Invoice invoice) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoices'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(invoice.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return Invoice(
        id: responseData['id'].toString(),
        invoiceNumber: invoice.invoiceNumber,
        total: invoice.total,
        createdAt: invoice.createdAt,
      );
    } else {
      throw Exception(
        'Failed to create invoice: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // PUT /invoices/:id - Update invoice
  Future<Invoice> updateInvoice(String id, Invoice invoice) async {
    final response = await http.put(
      Uri.parse('$baseUrl/invoices/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(invoice.toJson()),
    );

    if (response.statusCode == 200) {
      return Invoice(
        id: id,
        invoiceNumber: invoice.invoiceNumber,
        total: invoice.total,
        createdAt: invoice.createdAt,
      );
    } else {
      final errorBody = response.body;
      throw Exception('Failed to update invoice: $errorBody');
    }
  }

  // DELETE /invoices/:id - Delete invoice
  Future<void> deleteInvoice(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/invoices/$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete invoice');
    }
  }

  // GET /invoice-items - Get all invoice items
  Future<List<InvoiceItem>> getInvoiceItems() async {
    final response = await http.get(Uri.parse('$baseUrl/invoice-items'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => InvoiceItem.fromJson(json)).toList();
    } else if (response.statusCode == 204) {
      return [];
    } else {
      throw Exception('Failed to load invoice items');
    }
  }

  // GET /invoice-items/:id - Get invoice item by ID
  Future<InvoiceItem?> getInvoiceItem(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/invoice-items/$id'));

    if (response.statusCode == 200) {
      return InvoiceItem.fromJson(jsonDecode(response.body));
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load invoice item');
    }
  }

  // GET /invoice-items/invoice/:invoiceId - Get all items for a specific invoice
  Future<List<InvoiceItem>> getInvoiceItemsByInvoice(String invoiceId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/invoice-items/invoice/$invoiceId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => InvoiceItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load invoice items');
    }
  }

  // POST /invoice-items - Create new invoice item
  Future<InvoiceItem> createInvoiceItem(InvoiceItem item) async {
    final response = await http.post(
      Uri.parse('$baseUrl/invoice-items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return InvoiceItem(
        id: responseData['id'].toString(),
        invoiceId: item.invoiceId,
        barcode: item.barcode,
        nameSnapshot: item.nameSnapshot,
        priceSnapshot: item.priceSnapshot,
        qty: item.qty,
        lineTotal: item.lineTotal,
      );
    } else {
      throw Exception(
        'Failed to create invoice item: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // PUT /invoice-items/:id - Update invoice item
  Future<InvoiceItem> updateInvoiceItem(String id, InvoiceItem item) async {
    final response = await http.put(
      Uri.parse('$baseUrl/invoice-items/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item.toJson()),
    );

    if (response.statusCode == 200) {
      return InvoiceItem(
        id: id,
        invoiceId: item.invoiceId,
        barcode: item.barcode,
        nameSnapshot: item.nameSnapshot,
        priceSnapshot: item.priceSnapshot,
        qty: item.qty,
        lineTotal: item.lineTotal,
      );
    } else {
      final errorBody = response.body;
      throw Exception('Failed to update invoice item: $errorBody');
    }
  }

  // DELETE /invoice-items/:id - Delete invoice item
  Future<void> deleteInvoiceItem(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/invoice-items/$id'));

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete invoice item');
    }
  }
}

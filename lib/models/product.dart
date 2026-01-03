class Product {
  final String barcode;
  final String name;
  final double price;
  final int stock;
  final String category;
  final String description;
  final String? photoUrl;
  final bool isActive;

  Product({
    required this.barcode,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
    required this.description,
    this.photoUrl,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': barcode,
      'name': name,
      'price': price,
      'stock': stock,
      'category': category,
      'description': description,
      'photoUrl': photoUrl ?? '',
    };
  }

  static Product fromJson(Map<String, dynamic> json) {
    return Product(
      barcode: json['barcode']?.toString() ?? json['id']?.toString() ?? '',
      name: (json['name'] ?? '') as String,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      category: (json['category'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      photoUrl: ((json['photoUrl'] ?? '') as String).trim().isEmpty
          ? null
          : (json['photoUrl'] as String),
      isActive: json['isActive'] == 1 || json['isActive'] == true,
    );
  }
}

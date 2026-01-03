import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/db.dart';
import '../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final String? barcodePrefill;
  final Product? productToEdit;
  const AddProductScreen({super.key, this.barcodePrefill, this.productToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final formKey = GlobalKey<FormState>();

  final barcode = TextEditingController();
  final name = TextEditingController();
  final price = TextEditingController();
  final stock = TextEditingController();
  final category = TextEditingController();
  final description = TextEditingController();
  final photoUrl = TextEditingController(); 

  final picker = ImagePicker();
  File? pickedImage;
  bool uploadingImage = false;
  bool saving = false;

  static const bucketName = 'product-photos';

  @override
  void initState() {
    super.initState();
    if (widget.productToEdit != null) {
      final p = widget.productToEdit!;
      barcode.text = p.barcode;
      name.text = p.name;
      price.text = p.price.toString();
      stock.text = p.stock.toString();
      category.text = p.category;
      description.text = p.description;
      if (p.photoUrl != null) photoUrl.text = p.photoUrl!;
    } else if (widget.barcodePrefill != null) {
      barcode.text = widget.barcodePrefill!;
    }
  }

  @override
  void dispose() {
    barcode.dispose();
    name.dispose();
    price.dispose();
    stock.dispose();
    category.dispose();
    description.dispose();
    photoUrl.dispose();
    super.dispose();
  }

  Future<void> pickAndUploadImage() async {
    final b = barcode.text.trim();
    if (b.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter barcode first, then upload image.'),
        ),
      );
      return;
    }

    final xfile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (xfile == null) return;

    setState(() {
      pickedImage = File(xfile.path);
      uploadingImage = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final lower = xfile.path.toLowerCase();
      final ext = lower.endsWith('.png') ? 'png' : 'jpg';
      final path = '$b.$ext';

      try {
        final existingFiles = await supabase.storage
            .from(bucketName)
            .list(
              path: '',
              searchOptions: SearchOptions(search: b),
            );

        for (final file in existingFiles) {
          if (file.name.startsWith(b)) {
            await supabase.storage.from(bucketName).remove([file.name]);
          }
        }
      } catch (e) {
        debugPrint('No existing file to remove: $e');
      }

      await supabase.storage
          .from(bucketName)
          .upload(
            path,
            pickedImage!,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final public = supabase.storage.from(bucketName).getPublicUrl(path);

      photoUrl.text = public;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully.')),
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Upload failed: $e';
      if (e.toString().contains('row-level security')) {
        errorMsg =
            'Upload failed: Storage bucket permissions issue. Check RLS policies.';
      } else if (e.toString().contains('already exists')) {
        errorMsg =
            'Upload failed: File already exists. Try a different barcode or delete the old image.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
      debugPrint('Supabase upload error details: $e');
    } finally {
      if (mounted) setState(() => uploadingImage = false);
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);

    try {
      final db = context.read<Db>();
      final b = barcode.text.trim();
      final exists = await db.getProduct(b);

      final p = Product(
        barcode: b,
        name: name.text.trim(),
        price: double.parse(price.text),
        stock: int.parse(stock.text),
        category: category.text.trim(),
        description: description.text.trim(),
        photoUrl: photoUrl.text.trim().isEmpty ? null : photoUrl.text.trim(),
      );

      await db.upsertProduct(p, create: exists == null);

      if (!mounted) return;
      Navigator.pop(context, b); // return barcode
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.productToEdit != null;
    final readOnlyBarcode = widget.barcodePrefill != null || isEditing;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(isEditing ? Icons.edit : Icons.add_box, size: 28),
            const SizedBox(width: 12),
            Text(isEditing ? 'Edit Product' : 'Add Product'),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Image section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                          Icons.photo_camera,
                          color: Color(0xFF1E88E5),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Product Photo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF424242),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Preview (local pick) OR URL preview
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withOpacity(.04),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: pickedImage != null
                        ? Image.file(pickedImage!, fit: BoxFit.cover)
                        : (photoUrl.text.trim().isNotEmpty
                              ? Image.network(
                                  photoUrl.text.trim(),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Text('Invalid image URL'),
                                  ),
                                )
                              : const Center(child: Text('No image selected'))),
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: uploadingImage ? null : pickAndUploadImage,
                      icon: uploadingImage
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.cloud_upload_outlined),
                      label: Text(
                        uploadingImage ? 'Uploading...' : 'Pick & Upload Image',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'Bucket: $bucketName (public) • File name: <barcode>.jpg/png',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Form section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: formKey,
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
                            Icons.info,
                            color: Color(0xFF1E88E5),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Product Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF424242),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: barcode,
                      readOnly: readOnlyBarcode,
                      decoration: const InputDecoration(
                        labelText: 'Barcode',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Product Name',
                        prefixIcon: Icon(Icons.shopping_bag),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: price,
                            decoration: const InputDecoration(
                              labelText: 'Price',
                              prefixIcon: Icon(Icons.attach_money),
                              suffixText: 'USD',
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => (double.tryParse(v ?? '') == null)
                                ? 'Enter number'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: stock,
                            decoration: const InputDecoration(
                              labelText: 'Stock',
                              prefixIcon: Icon(Icons.inventory),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => (int.tryParse(v ?? '') == null)
                                ? 'Enter integer'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: category,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                        hintText: 'e.g., Electronics, Food, etc.',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (saving || uploadingImage) ? null : save,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, size: 24),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  saving
                      ? 'Saving...'
                      : (isEditing ? 'Update Product' : 'Save Product'),
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
    );
  }
}

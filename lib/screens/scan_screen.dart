import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

import '../models/db.dart';
import '../models/cart.dart';
import '../models/product.dart';
import 'product_details_screen.dart';
import 'add_product_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final AudioPlayer audioPlayer = AudioPlayer();
  Product? scannedProduct;
  String? scannedBarcode;
  bool isLoading = false;
  DateTime? lastScanTime;
  bool barcodeDetected = false;

  @override
  void dispose() {
    controller.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> handleBarcode(String barcode) async {
    final now = DateTime.now();
    if (lastScanTime != null &&
        now.difference(lastScanTime!) < const Duration(milliseconds: 500)) {
      return;
    }

    if (isLoading || scannedBarcode == barcode) return;

    lastScanTime = now;

    _playBeepSound();

    await controller.stop();
    setState(() {
      isLoading = true;
      scannedBarcode = barcode;
      scannedProduct = null;
      barcodeDetected = false;
    });

    final db = context.read<Db>();
    final p = await db.getProduct(barcode);

    if (!mounted) return;

    setState(() {
      scannedProduct = p;
      isLoading = false;
    });
  }

  void clearScan() {
    setState(() {
      scannedProduct = null;
      scannedBarcode = null;
      lastScanTime = null;
      barcodeDetected = false;
    });
    controller.start();
  }

  void _playBeepSound() async {
    try {
      HapticFeedback.mediumImpact();
      try {
        await audioPlayer.play(AssetSource('sounds/beep.mp3'));
      } catch (assetError) {
        debugPrint('Beep asset not found, using system sound: $assetError');
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> manualEntry() async {
    final c = TextEditingController();
    final barcode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF1E88E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Enter Barcode Manually',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: c,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Barcode Number',
                prefixIcon: Icon(Icons.qr_code),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, c.text.trim()),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (barcode != null && barcode.trim().isNotEmpty) {
      await handleBarcode(barcode.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.qr_code_scanner, size: 28),
            SizedBox(width: 12),
            Text('Scan Product'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            tooltip: 'Toggle Flash',
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              if (capture.barcodes.isNotEmpty && !isLoading) {
                if (!barcodeDetected) {
                  setState(() {
                    barcodeDetected = true;
                  });
                }
                final barcode = capture.barcodes.first;
                final raw = barcode.rawValue;
                if (raw != null && raw.isNotEmpty) {
                  handleBarcode(raw);
                }
              } else if (barcodeDetected && capture.barcodes.isEmpty) {
                setState(() {
                  barcodeDetected = false;
                });
              }
            },
          ),
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(
                  color: barcodeDetected ? Colors.green : Colors.white,
                  width: barcodeDetected ? 4 : 3,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: barcodeDetected
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      barcodeDetected
                          ? Icons.check_circle
                          : Icons.center_focus_strong,
                      color: barcodeDetected
                          ? Colors.green
                          : const Color(0xFF1E88E5),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      barcodeDetected
                          ? 'Barcode detected! Processing...'
                          : 'Position barcode within frame',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: barcodeDetected
                            ? Colors.green
                            : const Color(0xFF424242),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: scannedBarcode == null
                    ? _buildManualEntryButton(context)
                    : isLoading
                    ? _buildLoadingCard()
                    : scannedProduct != null
                    ? _buildProductPreviewCard(context)
                    : _buildNotFoundCard(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualEntryButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: manualEntry,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit,
                    color: Color(0xFF1E88E5),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  'Enter Barcode Manually',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Processing...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPreviewCard(BuildContext context) {
    final p = scannedProduct!;
    final cart = context.watch<Cart>();
    final lowStock = p.stock < 10;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Product info - tappable to navigate to details
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(barcode: p.barcode),
                ),
              );
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              p.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: lowStock
                                ? Colors.red[50]
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                lowStock
                                    ? Icons.warning_amber_rounded
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
                                  fontWeight: FontWeight.w600,
                                  color: lowStock
                                      ? Colors.red[700]
                                      : Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
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
          const Divider(height: 1),
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: clearScan,
                    icon: const Icon(Icons.close, size: 20),
                    label: const Text('Scan Again'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: p.stock <= 0
                        ? null
                        : () {
                            cart.addOrInc(
                              barcode: p.barcode,
                              name: p.name,
                              price: p.price,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Color(0xFF64B5F6),
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Added to cart',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            clearScan();
                          },
                    icon: const Icon(Icons.add_shopping_cart, size: 20),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off, size: 48, color: Colors.orange[700]),
          ),
          const SizedBox(height: 16),
          const Text(
            'Product Not Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code, size: 16, color: Color(0xFF1E88E5)),
                const SizedBox(width: 6),
                Text(
                  scannedBarcode!,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E88E5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This barcode is not in your inventory.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Is this a new product?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: clearScan,
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('Scan Again'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AddProductScreen(barcodePrefill: scannedBarcode),
                      ),
                    );
                    if (result != null) {
                      clearScan();
                    }
                  },
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Product'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

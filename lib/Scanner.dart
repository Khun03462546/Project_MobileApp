import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  bool _isDialogShown = false;
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );

    // ตรวจสอบโครงสร้าง Firestore เมื่อเริ่มต้น
    _checkFirestoreStructure();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ฟังก์ชันตรวจสอบโครงสร้าง Firestore
  void _checkFirestoreStructure() async {
    try {
      print('🔍 Checking Firestore structure...');
      
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .limit(5)
          .get();

      print('📦 Total products in collection: ${productsSnapshot.docs.length}');
      
      if (productsSnapshot.docs.isNotEmpty) {
        print('📋 Sample products structure:');
        for (var i = 0; i < productsSnapshot.docs.length; i++) {
          final doc = productsSnapshot.docs[i];
          final data = doc.data();
          print('   Product ${i + 1}:');
          data.forEach((key, value) {
            print('     $key: $value (${value.runtimeType})');
          });
          print('   ---');
        }
      } else {
        print('❌ No products found in collection');
        print('💡 Please add some products to the "products" collection');
      }
    } catch (e) {
      print('🚨 Error checking Firestore structure: $e');
    }
  }

  // ฟังก์ชันค้นหา Document ID จาก barcode
  Future<String?> _findProductDocumentId(String barcode) async {
    try {
      print('🔍 Searching for barcode: "$barcode"');
      
      // ลองค้นหาทั้งแบบ string และ number
      final searchMethods = [
        _searchWithString(barcode),
        _searchWithNumber(barcode),
        _searchWithTrimmedString(barcode),
      ];

      for (var method in searchMethods) {
        final result = await method;
        if (result != null) {
          return result;
        }
      }

      print('❌ No product found with barcode: $barcode');
      return null;
    } catch (e) {
      print('🚨 Error searching product document ID: $e');
      return null;
    }
  }

  Future<String?> _searchWithString(String barcode) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print('✅ Found with string search: "$barcode"');
        return querySnapshot.docs.first.id;
      }
    } catch (e) {
      print('⚠️ String search failed: $e');
    }
    return null;
  }

  Future<String?> _searchWithNumber(String barcode) async {
    try {
      final barcodeNumber = num.tryParse(barcode);
      if (barcodeNumber != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('barcode', isEqualTo: barcodeNumber)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          print('✅ Found with number search: $barcodeNumber');
          return querySnapshot.docs.first.id;
        }
      }
    } catch (e) {
      print('⚠️ Number search failed: $e');
    }
    return null;
  }

  Future<String?> _searchWithTrimmedString(String barcode) async {
    try {
      final trimmedBarcode = barcode.trim();
      if (trimmedBarcode != barcode) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('barcode', isEqualTo: trimmedBarcode)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          print('✅ Found with trimmed search: "$trimmedBarcode"');
          return querySnapshot.docs.first.id;
        }
      }
    } catch (e) {
      print('⚠️ Trimmed search failed: $e');
    }
    return null;
  }

  // ฟังก์ชันดึงข้อมูลสินค้าจาก Document ID
  Future<Map<String, dynamic>?> _getProductById(String documentId) async {
    try {
      final DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('products')
          .doc(documentId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        print('✅ Retrieved product: ${data['name']}');
        return {
          'id': doc.id,
          'barcode': data['barcode']?.toString() ?? '',
          'name': data['name'] ?? 'Unknown Product',
          'category': data['category'] ?? 'Other',
          'shelfLife': data['shelfLife'] ?? 7,
          'imageUrl': data['imageUrl'] ?? '',
          'unit': data['unit'] ?? 'ชิ้น',
          'brand': data['brand'] ?? '',
        };
      }
      return null;
    } catch (e) {
      print('🚨 Error getting product by ID: $e');
      return null;
    }
  }

  // ฟังก์ชันเพิ่มสินค้าลงในตาราง Fridge
  Future<void> _addToFridge(Map<String, dynamic> product) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      print('👤 Adding to fridge for user: ${user.uid}');

      // ตรวจสอบว่าสินค้ามีอยู่ในตู้เย็นแล้วหรือไม่
      final QuerySnapshot existingProduct = await FirebaseFirestore.instance
          .collection('Fridge')
          .where('userId', isEqualTo: user.uid)
          .where('productId', isEqualTo: product['id'])
          .limit(1)
          .get();

      if (existingProduct.docs.isNotEmpty) {
        // อัปเดตจำนวนสินค้าถ้ามีอยู่แล้ว
        await FirebaseFirestore.instance
            .collection('Fridge')
            .doc(existingProduct.docs.first.id)
            .update({
          'quantity': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('📈 Updated existing product quantity');
      } else {
        // เพิ่มสินค้าใหม่ถ้ายังไม่มี
        await FirebaseFirestore.instance.collection('Fridge').add({
          'userId': user.uid,
          'productId': product['id'],
          'productName': product['name'],
          'barcode': product['barcode'],
          'category': product['category'],
          'quantity': 2.5,
          'addedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'expiryDate': _calculateExpiryDate(product),
          'imageUrl': product['imageUrl'],
          'unit': product['unit'],
          'brand': product['brand'],
        });
        print('✅ Added new product to fridge');
      }
    } catch (e) {
      print('🚨 Error adding to fridge: $e');
      rethrow;
    }
  }

  DateTime _calculateExpiryDate(Map<String, dynamic> product) {
    final int daysToExpiry = product['shelfLife'] ?? 7;
    return DateTime.now().add(Duration(days: daysToExpiry));
  }

  Future<void> _handleBarcodeDetected(String code) async {
    if (_isDialogShown || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _isDialogShown = true;
    });

    print('🎯 Barcode detected: $code');

    try {
      final String? productDocId = await _findProductDocumentId(code);
      
      if (productDocId != null) {
        final Map<String, dynamic>? product = await _getProductById(productDocId);
        
        if (product != null) {
          await _addToFridge(product);
          
          if (!mounted) return;
          _showSuccessDialog(product);
        } else {
          if (!mounted) return;
          _showProductNotFoundDialog(code);
        }
      } else {
        if (!mounted) return;
        _showProductNotFoundDialog(code);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(e);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('สแกนสำเร็จ 🎉'),
        content: Text('เพิ่ม "${product['name']}" ลงในตู้เย็นเรียบร้อยแล้ว'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isDialogShown = false;
                _isProcessing = false;
              });
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showProductNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ไม่พบสินค้า'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ไม่พบข้อมูลสินค้าสำหรับบาร์โค้ด: $barcode'),
            const SizedBox(height: 16),
            const Text(
              '⚠️ หมายเหตุ:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('• ตรวจสอบว่าสินค้ามีในฐานข้อมูลหรือไม่'),
            const Text('• ตรวจสอบรูปแบบข้อมูลใน Firestore'),
            const Text('• ดู log ใน console สำหรับข้อมูลเพิ่มเติม'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isDialogShown = false;
                _isProcessing = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(dynamic error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เกิดข้อผิดพลาด'),
        content: Text('ไม่สามารถเพิ่มสินค้าได้: $error'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _isDialogShown = false;
                _isProcessing = false;
              });
              Navigator.of(context).pop();
            },
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const double scanAreaSize = 250;

    return Scaffold(
      appBar: AppBar(
        title: const Text('สแกน QR / Barcode'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: MobileScannerController(
              torchEnabled: false,
              facing: CameraFacing.back,
            ),
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null && !_isDialogShown) {
                  _handleBarcodeDetected(code);
                  break;
                }
              }
            },
          ),
          _buildScannerOverlay(size, scanAreaSize),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(Size size, double scanAreaSize) {
    return Stack(
      children: [
        Positioned.fill(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: scanAreaSize,
                    height: scanAreaSize,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Center(
          child: Container(
            width: scanAreaSize + 20,
            height: scanAreaSize + 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 2,
              ),
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Positioned(
              top: size.height * 0.5 -
                  scanAreaSize / 2 +
                  (scanAreaSize * _animation.value),
              left: size.width * 0.5 - scanAreaSize / 2,
              child: Container(
                width: scanAreaSize,
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: const Text(
            'วางบาร์โค้ดหรือ QR Code ภายในกรอบ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
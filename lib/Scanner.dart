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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ฟังก์ชันค้นหาสินค้าในตาราง products
  Future<Map<String, dynamic>?> _findProductInDatabase(String barcode) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        
        return {
          'id': doc.id,
          'barcode': data['barcode'] ?? barcode,
          'name': data['name'] ?? 'Unknown Product',
          'category': data['category'] ?? 'Other',
          'shelfLife': data['shelfLife'] ?? 7, // default 7 days
          'imageUrl': data['imageUrl'] ?? '',
          'unit': data['unit'] ?? 'ชิ้น',
        };
      }
      return null;
    } catch (e) {
      print('Error searching product: $e');
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
      } else {
        // เพิ่มสินค้าใหม่ถ้ายังไม่มี
        await FirebaseFirestore.instance.collection('Fridge').add({
          'userId': user.uid,
          'productId': product['id'],
          'productName': product['name'],
          'barcode': product['barcode'],
          'category': product['category'],
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'expiryDate': _calculateExpiryDate(product),
          'imageUrl': product['imageUrl'],
          'unit': product['unit'],
        });
      }
    } catch (e) {
      print('Error adding to fridge: $e');
      rethrow;
    }
  }

  // คำนวณวันหมดอายุ
  DateTime _calculateExpiryDate(Map<String, dynamic> product) {
    final int daysToExpiry = product['shelfLife'] ?? 7;
    return DateTime.now().add(Duration(days: daysToExpiry));
  }

  // ฟังก์ชันจัดการเมื่อสแกนพบบาร์โค้ด
  Future<void> _handleBarcodeDetected(String code) async {
    if (_isDialogShown || _isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _isDialogShown = true;
    });

    try {
      // ค้นหาสินค้าในฐานข้อมูล
      final Map<String, dynamic>? product = await _findProductInDatabase(code);
      
      if (product != null) {
        // เพิ่มสินค้าลงในตู้เย็น
        await _addToFridge(product);
        
        // แสดงผลลัพธ์การสแกนสำเร็จ
        if (!mounted) return;
        _showSuccessDialog(product);
      } else {
        // ไม่พบสินค้าในฐานข้อมูล
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
              Navigator.of(context).pop(true); // ส่งค่า success กลับ
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
        content: Text('ไม่พบข้อมูลสินค้าสำหรับบาร์โค้ด: $barcode'),
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
          TextButton(
            onPressed: () {
              setState(() {
                _isDialogShown = false;
                _isProcessing = false;
              });
              Navigator.of(context).pop();
              // นำทางไปหน้าเพิ่มสินค้าใหม่
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (_) => AddProductPage(barcode: barcode)
              // ));
            },
            child: const Text('เพิ่มสินค้า'),
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
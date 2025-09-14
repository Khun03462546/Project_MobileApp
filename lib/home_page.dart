import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myfridge_test/Summary_page.dart';
import 'package:myfridge_test/scanner.dart';
import 'setting_page.dart';
import 'notification_service.dart'; // <-- import

class FoodItem {
  final String id;
  final String productName;
  final String category;
  final DateTime? addedAt;
  final DateTime? expiryDate;
  final int? quantity;
  final String? imageUrl;
  final String userId;

  FoodItem({
    required this.id,
    required this.productName,
    required this.category,
    required this.userId,
    this.imageUrl,
    this.addedAt,
    this.expiryDate,
    this.quantity,
  });

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return FoodItem(
        id: doc.id,
        productName: data['productName']?.toString() ?? 'Unnamed',
        category: data['category']?.toString() ?? 'Other',
        userId: data['userId']?.toString() ?? '',
        imageUrl: data['imageUrl']?.toString(),
        addedAt: data['addedAt'] != null
            ? (data['addedAt'] is Timestamp
                ? (data['addedAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['addedAt'].toString()))
            : null,
        expiryDate: data['expiryDate'] != null
            ? (data['expiryDate'] is Timestamp
                ? (data['expiryDate'] as Timestamp).toDate()
                : DateTime.tryParse(data['expiryDate'].toString()))
            : null,
        quantity: data['quantity'] != null
            ? int.tryParse(data['quantity'].toString())
            : null,
      );
    } catch (e) {
      print("Error parsing FoodItem: $e");
      return FoodItem(
        id: '',
        productName: 'Unnamed',
        category: 'Other',
        userId: '',
      );
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedCategory = 'All';
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late CollectionReference foodCollection;

  final Map<String, String> categoryMapping = {
    'pork': 'Meat',
    'beef': 'Meat',
    'chicken': 'Meat',
    'meat': 'Meat',
    'fruit': 'Fruit',
    'vegetable': 'Vegetable',

  };

  @override
  void initState() {
    super.initState();
    foodCollection = FirebaseFirestore.instance.collection('Fridge');
  }

  Query _getUserFoodQuery() {
    if (_currentUser == null) {
      return foodCollection.where('userId', isEqualTo: 'invalid');
    }
    return foodCollection.where('userId', isEqualTo: _currentUser!.uid);
  }

  String getMainCategory(String category) {
    return categoryMapping[category.toLowerCase()] ?? 'Other';
  }

  void _checkExpiringSoon(List<FoodItem> items) async {
    final now = DateTime.now();
    final expiringSoon = items.where((item) {
      if (item.expiryDate == null) return false;
      final difference = item.expiryDate!.difference(now).inDays;
      return difference >= 0 && difference <= 2;
    }).toList();

    if (expiringSoon.isNotEmpty) {
      String names = expiringSoon.map((e) => e.productName).join(', ');
      await NotificationService.showNotification(
        id: 1,
        title: "อาหารใกล้หมดอายุ",
        body: "อาหารเหล่านี้ใกล้หมดอายุภายใน 2 วัน: $names",
      );
    }
  }

  Future<void> _showNotifications() async {
    final snapshot = await _getUserFoodQuery().get();
    List<FoodItem> items = snapshot.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();
    final now = DateTime.now();
    final expiringSoon = items.where((item) {
      if (item.expiryDate == null) return false;
      final difference = item.expiryDate!.difference(now).inDays;
      return difference >= 0 && difference <= 2;
    }).toList();

    if (expiringSoon.isNotEmpty) {
      String names = expiringSoon.map((e) => e.productName).join(', ');
      await NotificationService.showNotification(
        id: 2,
        title: "อาหารใกล้หมดอายุ",
        body: "อาหารเหล่านี้ใกล้หมดอายุภายใน 2 วัน: $names",
      );
    } else {
      await NotificationService.showNotification(
        id: 3,
        title: "ไม่มีอาหารใกล้หมดอายุ",
        body: "ทุกอย่างยังดีอยู่ในตู้เย็น",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('กรุณาล็อกอินเพื่อดูข้อมูล'),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('ไปหน้าล็อกอิน'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      drawer: _buildDrawer(),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Fridge',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF6F398E),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: _showNotifications, // <-- กดกระดิ่งแจ้งเตือน
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUserFoodQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading data"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<FoodItem> items = snapshot.data!.docs
                    .map((doc) => FoodItem.fromFirestore(doc))
                    .toList();

                if (selectedCategory != 'All') {
                  items = items
                      .where((item) =>
                          getMainCategory(item.category).toLowerCase() ==
                          selectedCategory.toLowerCase())
                      .toList();
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _checkExpiringSoon(items);
                });

                if (items.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.kitchen, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "ไม่มีอาหารในตู้เย็น",
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "กดปุ่ม + เพื่อเพิ่มอาหาร",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _buildFoodItemCard(items[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6F398E),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BarcodeScannerPage()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDrawer() {
    final user = FirebaseAuth.instance.currentUser;
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6F398E), Color(0xFFCACBE7)],
            begin: Alignment.topRight,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              accountName: Text(
                user?.displayName ?? "User",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              accountEmail: Text(
                user?.email ?? "No Email",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    tileColor: Colors.transparent,
                    leading: const Icon(Icons.article, color: Colors.white),
                    title: const Text(
                      'Summary',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SummaryPage()),
                      );
                    },
                  ),
                  ListTile(
                    tileColor: Colors.transparent,
                    leading: const Icon(Icons.settings, color: Colors.white),
                    title: const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              tileColor: Colors.transparent,
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = ['All', 'Fruit', 'Vegetable', 'Meat', 'Dairy', 'Beverage'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories
              .map(
                (category) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory.toLowerCase() ==
                        category.toLowerCase(),
                    selectedColor: const Color(0xFF6F398E),
                    backgroundColor: Colors.grey.shade200,
                    labelStyle: TextStyle(
                      color: selectedCategory.toLowerCase() ==
                              category.toLowerCase()
                          ? Colors.white
                          : Colors.black,
                    ),
                    checkmarkColor: Colors.white,
                    onSelected: (_) {
                      setState(() => selectedCategory = category);
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildFoodItemCard(FoodItem item) {
    IconData icon;
    Color iconColor;

    switch (getMainCategory(item.category).toLowerCase()) {
      case 'fruit':
        icon = Icons.apple;
        iconColor = Colors.red;
        break;
      case 'vegetable':
        icon = Icons.grass;
        iconColor = Colors.green;
        break;
      case 'meat':
        icon = Icons.set_meal;
        iconColor = Colors.brown;
        break;
      case 'dairy':
        icon = Icons.local_drink;
        iconColor = Colors.yellow;
        break;
      case 'beverage':
        icon = Icons.local_cafe;
        iconColor = Colors.blue;
        break;
      default:
        icon = Icons.fastfood;
        iconColor = Colors.grey;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Center(
                child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        height: 120,
                        width: 120,
                      )
                    : Icon(
                        icon,
                        size: 80,
                        color: iconColor,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text('Category: ${getMainCategory(item.category)}',
                      style: const TextStyle(fontSize: 16)),
                  if (item.quantity != null)
                    Text('Quantity: ${item.quantity}',
                        style: const TextStyle(fontSize: 16)),
                  if (item.addedAt != null)
                    Text(
                        'Added: ${item.addedAt!.day}/${item.addedAt!.month}/${item.addedAt!.year}',
                        style: const TextStyle(fontSize: 16)),
                  if (item.expiryDate != null)
                    Text(
                        'Expires: ${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}',
                        style: const TextStyle(
                            fontSize: 16, color: Colors.redAccent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

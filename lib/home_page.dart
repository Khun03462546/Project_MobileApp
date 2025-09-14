import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myfridge_test/Summary_page.dart';
import 'package:myfridge_test/scanner.dart';
import 'setting_page.dart';

class FoodItem {
  final String id; // เพิ่ม field id
  final String name;
  final String category;
  final DateTime? expirationDate;
  final DateTime? addedDate;
  final double? weight;
  final String? imageUrl;
  final String userId; // เพิ่ม field userId

  FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.userId,
    this.imageUrl,
    this.expirationDate,
    this.addedDate,
    this.weight,
  });

  factory FoodItem.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      return FoodItem(
        id: doc.id, // เก็บ document ID
        name: data['name']?.toString() ?? 'Unnamed',
        category: data['category']?.toString() ?? 'Other',
        userId: data['userId']?.toString() ?? '', // เก็บ userId
        imageUrl: data['imageUrl']?.toString(),
        expirationDate: data['expirationDate'] != null
            ? (data['expirationDate'] is Timestamp
                ? (data['expirationDate'] as Timestamp).toDate()
                : DateTime.tryParse(data['expirationDate'].toString()))
            : null,
        addedDate: data['addedDate'] != null
            ? (data['addedDate'] is Timestamp
                ? (data['addedDate'] as Timestamp).toDate()
                : DateTime.tryParse(data['addedDate'].toString()))
            : null,
        weight: data['weight'] != null
            ? double.tryParse(data['weight'].toString())
            : null,
      );
    } catch (e) {
      print("Error parsing FoodItem: $e");
      return FoodItem(
        id: '',
        name: 'Unnamed', 
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

  @override
  void initState() {
    super.initState();
    foodCollection = FirebaseFirestore.instance.collection('Fridge');
  }

  // สร้าง query สำหรับดึงข้อมูลเฉพาะของผู้ใช้ปัจจุบัน
  Query _getUserFoodQuery() {
    if (_currentUser == null) {
      return foodCollection.where('userId', isEqualTo: 'invalid'); // return empty query
    }
    return foodCollection.where('userId', isEqualTo: _currentUser!.uid);
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
            onPressed: _showNotifications,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUserFoodQuery().snapshots(), // ใช้ query ที่กรองแล้ว
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
                          item.category.toLowerCase() ==
                          selectedCategory.toLowerCase())
                      .toList();
                }

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
            MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
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

    // กำหนด icon ตามหมวดหมู่
    switch (item.category.toLowerCase()) {
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
                    item.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  const SizedBox(height: 6),
                  Text('Category: ${item.category}',
                      style: const TextStyle(fontSize: 16)),
                  if (item.weight != null)
                    Text('Weight: ${item.weight} g',
                        style: const TextStyle(fontSize: 16)),
                  if (item.addedDate != null)
                    Text(
                        'Added: ${item.addedDate!.day}/${item.addedDate!.month}/${item.addedDate!.year}',
                        style: const TextStyle(fontSize: 16)),
                  if (item.expirationDate != null)
                    Text(
                        'Expires: ${item.expirationDate!.day}/${item.expirationDate!.month}/${item.expirationDate!.year}',
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

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notifications"),
        content: const Text("Notification system here"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
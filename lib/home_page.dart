import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myfridge_test/food_item.dart';
import 'package:myfridge_test/scanner.dart';
import 'package:myfridge_test/Summary_page.dart';
import 'package:myfridge_test/setting_page.dart';
import 'package:myfridge_test/login_page.dart';

class HomePage extends StatefulWidget {
  final String? usersName;
  final String? usersEmail;

  const HomePage({super.key, this.usersName, this.usersEmail});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Meat', 'Vegetable', 'Fruit'];

  final List<AppNotification> _mockNotifications = [];

  Query _getUserFoodQuery() {
    return FirebaseFirestore.instance
        .collection('Fridge')
        .where('userId', isEqualTo: _currentUser?.uid);
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'meat':
        return Colors.redAccent;
      case 'vegetable':
        return Colors.green;
      case 'fruit':
        return Colors.orange;
      case 'all':
        return const Color(0xFF6F398E);
      default:
        return Colors.grey;
    }
  }

  int get unreadNotifications =>
      _mockNotifications.where((n) => !n.isRead).length;

  void _showNotifications() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Notifications"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  _mockNotifications
                      .map(
                        (n) => ListTile(
                          leading: Icon(
                            n.isRead
                                ? Icons.notifications_none
                                : Icons.notification_important,
                            color: n.isRead ? Colors.grey : Colors.red,
                          ),
                          title: Text(n.title),
                          subtitle: Text(n.message),
                        ),
                      )
                      .toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("ปิด"),
              ),
            ],
          ),
    );
  }

  Widget _buildDrawer() {
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
                _currentUser?.displayName ?? "User",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                _currentUser?.email ?? "No Email",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.article, color: Colors.white),
              title: const Text(
                'Summary',
                style: TextStyle(color: Colors.white),
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
              leading: const Icon(Icons.settings, color: Colors.white),
              title: const Text(
                'Settings',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingPage()),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildAppBar(),
          _buildFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getUserFoodQuery().snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error loading data'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                List<FoodItem> items =
                    snapshot.data!.docs
                        .map((doc) => FoodItem.fromFirestore(doc))
                        .toList();

                if (selectedCategory != 'All') {
                  items =
                      items
                          .where(
                            (item) =>
                                item.category.toLowerCase() ==
                                selectedCategory.toLowerCase(),
                          )
                          .toList();
                }

                final now = DateTime.now();
                final expiringNotifications =
                    items
                        .where((item) {
                          final exp = item.expirationDate;
                          return exp != null && exp.difference(now).inDays <= 2;
                        })
                        .map(
                          (item) => AppNotification(
                            'Expiring Soon',
                            '${item.name} expires in ${item.expirationDate!.difference(now).inDays} day(s)',
                            false,
                          ),
                        )
                        .toList();

                _mockNotifications
                  ..clear()
                  ..addAll(expiringNotifications);

                if (items.isEmpty) {
                  return const Center(child: Text('ตู้เย็นยังว่างกดปุ่ม + เพื่อเพิ่มของได้เลย!'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildFoodCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6F398E),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BarcodeScannerPage()),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      title: const Text(
        'Your Fridge',
        style: TextStyle(
          color: const Color(0xFF6F398E),
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(color: const Color(0xFF6F398E)),
      actions: [_buildNotificationIcon()],
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: const Color(0xFF6F398E)),
          onPressed: _showNotifications,
        ),
        if (unreadNotifications > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$unreadNotifications',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children:
            categories.map((category) {
              final isSelected = selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Row(
                    children: [
                      Text(category),
                      if (isSelected)
                        const Padding(padding: EdgeInsets.only(left: 4)),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: _getCategoryColor(category),
                  backgroundColor: Colors.grey.shade200,
                  labelStyle: TextStyle(
                    color:
                        isSelected ? Colors.white : _getCategoryColor(category),
                  ),
                  onSelected: (_) {
                    setState(() => selectedCategory = category);
                  },
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildFoodCard(FoodItem item) {
    final color = _getCategoryColor(item.category);
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.fastfood, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              item.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Category: ${item.category}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              item.expirationDate != null
                  ? 'Exp: ${item.expirationDate!.day}/${item.expirationDate!.month}/${item.expirationDate!.year}'
                  : 'Exp: N/A',
              style: const TextStyle(fontSize: 14, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  List<AppNotification> _generateExpiringNotifications(List<FoodItem> items) {
    final now = DateTime.now();
    final List<AppNotification> notifications = [];

    for (var item in items) {
      final exp = item.expirationDate;
      if (exp != null) {
        final daysLeft = exp.difference(now).inDays;
        if (daysLeft >= 0 && daysLeft <= 2) {
          notifications.add(
            AppNotification(
              'Expiring Soon',
              '${item.name} expires in $daysLeft day${daysLeft == 1 ? '' : 's'}',
              false,
            ),
          );
        }
      }
    }

    return notifications;
  }
}

class BottomCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 30,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class AppNotification {
  final String title;
  final String message;
  final bool isRead;

  AppNotification(this.title, this.message, this.isRead);
}

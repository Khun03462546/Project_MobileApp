import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myfridge_test/food_item.dart';
import 'package:myfridge_test/scanner.dart';
import 'package:myfridge_test/Summary_page.dart';
import 'package:myfridge_test/setting_page.dart';
import 'package:myfridge_test/login_page.dart';
import 'package:intl/intl.dart';

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

  String _getCategoryGroup(String category) {
    switch (category.toLowerCase()) {
      case 'pork':
      case 'beef':
      case 'chicken':
      case 'seafood':
        return 'Meat';
      case 'vegetable':
      case 'carrot':
      case 'broccoli':
        return 'Vegetable';
      case 'fruit':
      case 'apple':
      case 'banana':
        return 'Fruit';
      default:
        return category; // อื่น ๆ
    }
  }

  Color _getCategoryColor(String category) {
    switch (_getCategoryGroup(category).toLowerCase()) {
      case 'meat':
        return Colors.redAccent;
      case 'vegetable':
        return Colors.green;
      case 'fruit':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryEmoji(String category) {
    switch (_getCategoryGroup(category).toLowerCase()) {
      case 'meat':
        return '🥩';
      case 'vegetable':
        return '🥦';
      case 'fruit':
        return '🍎';
      default:
        return '🍽️';
    }
  }

  int get unreadNotifications =>
      _mockNotifications.where((n) => !n.isRead).length;

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notifications"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _mockNotifications
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

  void _showItemDetails(FoodItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${item.category}'),
            Text(
              item.addedDate != null
                  ? 'Added on: ${item.addedDate!.day}/${item.addedDate!.month}/${item.addedDate!.year}'
                  : 'No added date',
            ),
            Text(
              item.expirationDate != null
                  ? 'Expires on: ${item.expirationDate!.day}/${item.expirationDate!.month}/${item.expirationDate!.year}'
                  : 'No expiration date',
            ),
            if (item.weight != null) Text('Weight: ${item.weight} kg'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('Fridge')
                    .doc(item.id)
                    .delete();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item deleted successfully'),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete item: $e')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
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
                    snapshot.data!.docs.map((doc) => FoodItem.fromFirestore(doc)).toList();

                if (selectedCategory != 'All') {
                  items = items.where((item) =>
                      _getCategoryGroup(item.category).toLowerCase() ==
                      selectedCategory.toLowerCase()).toList();
                }

                final now = DateTime.now();
                final expiringNotifications = items
                    .where((item) =>
                        item.expirationDate != null &&
                        item.expirationDate!.difference(now).inDays <= 2)
                    .map((item) => AppNotification(
                          'Expiring Soon',
                          '${item.name} expires in ${item.expirationDate!.difference(now).inDays} day(s)',
                          false,
                        ))
                    .toList();

                _mockNotifications
                  ..clear()
                  ..addAll(expiringNotifications);

                if (items.isEmpty) {
                  return const Center(
                      child: Text(
                          'ตู้เย็นยังว่างกดปุ่ม + เพื่อเพิ่มของได้เลย!'));
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
        style: TextStyle(color: Color(0xFF6F398E), fontWeight: FontWeight.bold),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF6F398E)),
      actions: [_buildNotificationIcon()],
    );
  }

  Widget _buildNotificationIcon() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Color(0xFF6F398E)),
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
        children: categories.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              selectedColor: _getCategoryColor(category),
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : _getCategoryColor(category),
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
    return Hero(
      tag: item.name,
      child: GestureDetector(
        onTap: () => _showItemDetails(item),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: item.imageUrl != null
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            )
                          : Text(
                              _getCategoryEmoji(item.category),
                              style: const TextStyle(fontSize: 48),
                            ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _getCategoryColor(item.category).withOpacity(0.8),
                          _getCategoryColor(item.category).withOpacity(0.9),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        if (item.expirationDate != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Exp: ${DateFormat('dd/MM/yyyy').format(item.expirationDate!)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      color: _getCategoryColor(item.category),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<AppNotification> _generateExpiringNotifications(List<FoodItem> items) {
  final now = DateTime.now();
  final List<AppNotification> notifications = [];

  for (var item in items) {
    final exp = item.expirationDate;
    if (exp != null) {
      final daysLeft = exp.difference(now).inDays;
      if (daysLeft >= 0 && daysLeft <= 2) {
        notifications.add(AppNotification(
          'Expiring Soon',
          '${item.name} expires in $daysLeft day${daysLeft == 1 ? '' : 's'}',
          false,
        ));
      }
    }
  }

  if (notifications.isEmpty) {
    notifications.add(
      AppNotification('All Good!', 'ไม่มีอะไรใกล้หมดอายุในตอนนี้', false),
    );
  }

  return notifications;
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

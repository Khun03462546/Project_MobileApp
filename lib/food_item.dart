import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final String category;
  final DateTime? expirationDate;
  final DateTime? addedDate;
  final double? weight;
  final String? imageUrl;
  final String userId;

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
        id: doc.id,
        name: data['productName']?.toString() ?? 'Unnamed',
        category: data['category']?.toString() ?? 'Other',
        userId: data['userId']?.toString() ?? '',
        imageUrl: data['imageUrl']?.toString(),
        expirationDate:
            data['expiryDate'] != null
                ? (data['expiryDate'] is Timestamp
                    ? (data['expiryDate'] as Timestamp).toDate()
                    : DateTime.tryParse(data['expiryDate'].toString()))
                : null,

        addedDate:
            data['addedAt'] != null
                ? (data['addedAt'] is Timestamp
                    ? (data['addedAt'] as Timestamp).toDate()
                    : DateTime.tryParse(data['addedAt'].toString()))
                : null,
        weight:
            data['weight'] != null
                ? double.tryParse(data['weight'].toString())
                : null,
      );
    } catch (e) {
      print("Error parsing FoodItem: $e");
      return FoodItem(id: '', name: 'Unnamed', category: 'Other', userId: '');
    }
  }
}

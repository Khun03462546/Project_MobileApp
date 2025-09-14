import 'package:flutter/material.dart';

class FruitSummary extends StatefulWidget {
  const FruitSummary({super.key});

  @override
  State<FruitSummary> createState() => _FruitSummaryState();
}

class _FruitSummaryState extends State<FruitSummary> {
  final Map<String, double> usage = {
    'แอปเปิ้ล': 50,
    'กล้วย': 30,
    'มะม่วง': 10,
    'แตงโม': 5,
    'ส้ม': 5,
  };

  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final sortedItems = usage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3 = sortedItems.take(3).toList();
    final others = sortedItems.skip(3).toList();

    return buildCard('ผลไม้', top3, others);
  }

  Widget buildCard(String title, List<MapEntry<String, double>> top3, List<MapEntry<String, double>> others) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: top3.map((entry) {
                final index = top3.indexOf(entry);
                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.deepPurple.shade100,
                      child: Text('${index + 1}'),
                    ),
                    const SizedBox(width: 8),
                    Text(entry.key, style: const TextStyle(fontSize: 14)),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            if (isExpanded)
              ...others.map((entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_right, size: 20, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text(entry.key, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  )),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => isExpanded = !isExpanded),
                icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                label: Text(isExpanded ? 'ย่อ' : 'แสดงเพิ่มเติม'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
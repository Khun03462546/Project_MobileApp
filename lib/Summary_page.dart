import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

void main() => runApp(const MaterialApp(home: SummaryPage(), debugShowCheckedModeBanner: false));

class SummaryPage extends StatelessWidget {
  const SummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Summary'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            MeatCategoryCard(title: 'Meat', items: meatItems, backgroundColor: categoryColors['Meat']!),
            SimpleCategoryCard(title: 'Vegetable', items: vegetableItems, backgroundColor: categoryColors['Vegetable']!),
            SimpleCategoryCard(title: 'Fruit', items: fruitItems, backgroundColor: categoryColors['Fruit']!),
          ],
        ),
      ),
    );
  }
}

// 🥩 Meat item with multiple parts
class MeatItem {
  final String name;
  final double total;
  final Map<String, double> parts;

  MeatItem({required this.name, required this.total, required this.parts});
}

// 🥦🍎 Simple item with only name and total
class SimpleItem {
  final String name;
  final double total;

  SimpleItem({required this.name, required this.total});
}

// 🟣 Sample data
final List<MeatItem> meatItems = [
  MeatItem(name: 'Pork', total: 50, parts: {
    'collar': 10,
    'loin': 8,
    'tenderloin': 6,
    'rib': 5,
  }),
  MeatItem(name: 'Beef', total: 40, parts: {
    'ribeye': 12,
    'sirloin': 10,
    'brisket': 6,
  }),
  MeatItem(name: 'Chicken', total: 30, parts: {
    'breast': 10,
    'thigh': 8,
    'wing': 5,
  }),
];

final List<SimpleItem> vegetableItems = [
  SimpleItem(name: 'Carrot', total: 10),
  SimpleItem(name: 'Broccoli', total: 7),
  SimpleItem(name: 'Spinach', total: 5),
  SimpleItem(name: 'Cat', total: 3),
];

final List<SimpleItem> fruitItems = [
  SimpleItem(name: 'Apple', total: 2),
  SimpleItem(name: 'Banana', total: 3),
  SimpleItem(name: 'Orange', total: 4),
  SimpleItem(name: 'Grapes', total: 5),
];

final Map<String, Color> categoryColors = {
  'Meat': Color(0xFFB39DDB),
  'Vegetable': Color(0xFF9575CD),
  'Fruit': Color(0xFF7E57C2),
};

// 🥦🍎 Category card for Vegetable and Fruit
class SimpleCategoryCard extends StatelessWidget {
  final String title;
  final List<SimpleItem> items;
  final Color backgroundColor;

  const SimpleCategoryCard({
    super.key,
    required this.title,
    required this.items,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.total);
    final scrollController = ScrollController();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Total: $total kg', style: const TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 400,
              child: SimpleBarChartWidget(items: items),
            ),
          ),
        ],
      ),
    );
  }
}

// 🥩 Meat category with dropdown and dynamic parts
class MeatCategoryCard extends StatefulWidget {
  final String title;
  final List<MeatItem> items;
  final Color backgroundColor;

  const MeatCategoryCard({
    super.key,
    required this.title,
    required this.items,
    required this.backgroundColor,
  });

  @override
  State<MeatCategoryCard> createState() => _MeatCategoryCardState();
}

class _MeatCategoryCardState extends State<MeatCategoryCard> {
  late String selectedMeat;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selectedMeat = widget.items.first.name;
  }

  @override
  Widget build(BuildContext context) {
    final selectedItem = widget.items.firstWhere((item) => item.name == selectedMeat);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔽 หัวข้อและ dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: DropdownButton<String>(
                  value: selectedMeat,
                  dropdownColor: Colors.white,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.deepPurple),
                  items: widget.items.map((item) {
                    return DropdownMenuItem(
                      value: item.name,
                      child: Text(item.name, style: const TextStyle(color: Colors.black)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedMeat = value!;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${selectedItem.total} kg',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          // 🔽 กราฟเลื่อนแนวนอน
          SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: MeatBarChartWidget(parts: selectedItem.parts),
          ),
        ],
      ),
    );
  }
}

// 📊 Bar chart for Meat parts
class MeatBarChartWidget extends StatelessWidget {
  final Map<String, double> parts;

  const MeatBarChartWidget({super.key, required this.parts});

  @override
  Widget build(BuildContext context) {
    final labels = parts.keys.toList();
    final maxY = parts.values.reduce((a, b) => a > b ? a : b) + 5;
    final chartWidth = labels.length * 80.0; // 👈 ความกว้างต่อแท่ง

    return SizedBox(
      height: 200,
      child: SizedBox(
        width: chartWidth,
        child: Stack(
          children: [
            BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Text(labels[index], style: const TextStyle(color: Colors.white));
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(labels.length, (index) {
                  final label = labels[index];
                  final value = parts[label]!;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        color: Colors.white,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth = chartWidth / labels.length;
                  final chartHeight = constraints.maxHeight;

                  return Row(
                    children: labels.map((label) {
                      final value = parts[label]!;
                      final topOffset = (1 - value / maxY) * chartHeight - 16;

                      return SizedBox(
                        width: barWidth,
                        child: Padding(
                          padding: EdgeInsets.only(top: topOffset.clamp(0, chartHeight - 20)),
                          child: Text(
                            '${value} kg',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SimpleBarChartWidget extends StatelessWidget {
  final List<SimpleItem> items;

  const SimpleBarChartWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final maxY = items.map((e) => e.total).reduce((a, b) => a > b ? a : b) + 5;

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index >= 0 && index < items.length) {
                        return Text(items[index].name, style: const TextStyle(color: Colors.white));
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(items.length, (index) {
                final item = items[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: item.total,
                      color: Colors.white,
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartHeight = constraints.maxHeight;
                final barWidth = constraints.maxWidth / items.length;

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: items.map((item) {
                    final topOffset = (1 - item.total / maxY) * chartHeight - 16;

                    return SizedBox(
                      width: barWidth,
                      child: Padding(
                        padding: EdgeInsets.only(top: topOffset.clamp(0, chartHeight - 20)),
                        child: Text(
                          '${item.total} kg',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
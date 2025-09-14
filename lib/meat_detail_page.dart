import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';

class MeatDetailPage extends StatelessWidget {
  const MeatDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Map<String, double> meatData = {
      "เนื้อหมู": 5,
      "เนื้อวัว": 6,
      "เนื้อไก่": 4,
    };

    final colorList = <Color>[
      const Color.fromARGB(255, 250, 153, 7),
      const Color.fromARGB(255, 0, 128, 0),
      const Color.fromARGB(255, 255, 215, 0),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดเนื้อสดในตู้เย็น'),
        backgroundColor: const Color(0xFF6F398E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(height: 30),
            PieChart(
              dataMap: meatData,
              chartType: ChartType.disc,
              colorList: colorList,
              chartRadius: 200,
              chartValuesOptions: const ChartValuesOptions(
                showChartValuesInPercentage: true,
              ),
              legendOptions: const LegendOptions(
                legendPosition: LegendPosition.right,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "รายละเอียดเนื้อสดในตู้เย็น",
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}

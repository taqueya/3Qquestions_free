import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultPage extends StatelessWidget {
  final int correctCount;
  final int totalCount;

  const ResultPage({
    super.key,
    required this.correctCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate percentages
    final wrongCount = totalCount - correctCount;
    final double correctPercentage = totalCount == 0 ? 0 : (correctCount / totalCount) * 100;

    return Scaffold(
      appBar: AppBar(title: const Text('結果発表')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              '正答率: ${correctPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$correctCount / $totalCount 問正解',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            
            // Pie Chart
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: correctCount.toDouble(),
                      title: '$correctCount問',
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      color: Colors.red,
                      value: wrongCount.toDouble(),
                      title: '$wrongCount問',
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            ElevatedButton(
              onPressed: () {
                // Pop back to home
                context.go('/'); 
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('ホームに戻る'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

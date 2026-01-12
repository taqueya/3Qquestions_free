import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ResultPage extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final int skippedCount;

  const ResultPage({
    super.key,
    required this.correctCount,
    required this.totalCount,
    this.skippedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final wrongCount = totalCount - correctCount;
    final totalQuestions = totalCount + skippedCount;
    final double correctPercentage = totalQuestions == 0 ? 0 : (correctCount / totalQuestions) * 100;

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
              '$correctCount / $totalQuestions 問正解',
              style: const TextStyle(fontSize: 18),
            ),
            if (skippedCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                '(無回答: $skippedCount問)',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
            const SizedBox(height: 32),
            
            // Pie Chart
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    if (correctCount > 0)
                      PieChartSectionData(
                        color: Colors.green,
                        value: correctCount.toDouble(),
                        title: '正解\n$correctCount問',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (wrongCount > 0)
                      PieChartSectionData(
                        color: Colors.red,
                        value: wrongCount.toDouble(),
                        title: '不正解\n$wrongCount問',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (skippedCount > 0)
                      PieChartSectionData(
                        color: Colors.grey,
                        value: skippedCount.toDouble(),
                        title: '無回答\n$skippedCount問',
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            ElevatedButton(
              onPressed: () {
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

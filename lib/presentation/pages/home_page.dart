import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String? selectedExam;
  String? selectedCategory;

  @override
  Widget build(BuildContext context) {
    final examCountsAsync = ref.watch(examCountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('知財検定2級 過去問道場')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Exam Mode
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('回数別で解く', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    examCountsAsync.when(
                      data: (exams) => DropdownButton<String>(
                        isExpanded: true,
                        value: selectedExam,
                        hint: const Text('回数を選択'),
                        items: exams.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) => setState(() => selectedExam = val),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text('Error: $err'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: selectedExam == null
                          ? null
                          : () {
                              context.push('/quiz', extra: {
                                'mode': QuizMode.exam,
                                'target': selectedExam,
                              });
                            },
                      child: const Text('スタート'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Category Mode
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('分野別で解く', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    categoriesAsync.when(
                      data: (cats) => DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCategory,
                        hint: const Text('分野を選択'),
                        items: cats.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setState(() => selectedCategory = val),
                      ),
                      loading: () => const CircularProgressIndicator(),
                      error: (err, stack) => Text('Error: $err'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: selectedCategory == null
                          ? null
                          : () {
                              context.push('/quiz', extra: {
                                'mode': QuizMode.category,
                                'target': selectedCategory,
                              });
                            },
                      child: const Text('スタート'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 3. Mistake Mode
            SizedBox(
              height: 60,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('苦手（間違えた問題）を解く'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                ),
                onPressed: () {
                  context.push('/quiz', extra: {
                    'mode': QuizMode.mistake,
                    'target': 'mistake',
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

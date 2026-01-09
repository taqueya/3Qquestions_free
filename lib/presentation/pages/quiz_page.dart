import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers.dart';
import '../../data/model/question.dart';

class QuizPage extends ConsumerStatefulWidget {
  final QuizMode mode;
  final String target;

  const QuizPage({super.key, required this.mode, required this.target});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  // Local state for the current question interaction
  bool _answered = false;
  String? _selectedOption;
  bool _isCorrect = false;



  void _handleOptionTap(String option, Question question) {
    if (_answered) return;

    final isCorrect = option == question.correctOption;
    setState(() {
      _answered = true;
      _selectedOption = option;
      _isCorrect = isCorrect;
    });
    
    // Update stats
    ref.read(quizProvider.notifier).recordAnswer(isCorrect);

    if (isCorrect) {
      if (widget.mode == QuizMode.mistake) {
        ref.read(quizProvider.notifier).deleteMistake(question.id);
      }
    } else {
      ref.read(quizProvider.notifier).saveMistake(question.id);
    }
  }

  void _nextQuestion() {
    ref.read(quizProvider.notifier).nextQuestion();
    setState(() {
      _answered = false;
      _selectedOption = null;
      _isCorrect = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);

    // Trigger load if initial state (handles provider recreation on auth change)
    if (state.isInitial && !state.isLoading) {
      Future.microtask(() => 
        ref.read(quizProvider.notifier).loadQuestions(widget.mode, widget.target)
      );
    }

    if (state.isInitial || state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('エラー')),
        body: Center(child: Text('エラーが発生しました: ${state.error}')),
      );
    }

    final question = state.currentQuestion;

    if (question == null) {
      // No questions or finished
      if (state.questions.isEmpty && !state.isLoading) {
         return Scaffold(
          appBar: AppBar(title: const Text('クイズ終了')),
          body: const Center(child: Text('問題が見つかりませんでした。')),
        );
      }
      
      // Finished
      // Schedule navigation after build
      Future.microtask(() {
        if (context.mounted) {
           context.go('/result', extra: {
             'correctCount': state.correctCount,
             'totalCount': state.answeredCount, // Or state.questions.length if enforced
           });
        }
      });
      
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${question.examCount} 問${question.questionNumber} (${question.category})'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar (Optional)
            LinearProgressIndicator(
              value: (state.currentIndex + 1) / state.questions.length,
            ),
            const SizedBox(height: 16),

            // Question Text
            Text(
              question.questionText,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),

            // Options
            ...question.options.map((option) {
              Color? btnColor;
              if (_answered) {
                if (option == question.correctOption) {
                  btnColor = Colors.green.shade100; // Correct answer always highlighted
                } else if (option == _selectedOption && !_isCorrect) {
                  btnColor = Colors.red.shade100; // Wrong selection
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: btnColor,
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () => _handleOptionTap(option, question),
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                    maxLines: 5, // Requirement: long text support
                  ),
                ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Feedback & Explanation
            if (_answered) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isCorrect ? Colors.green : Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCorrect ? '正解！' : '不正解...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isCorrect ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('【解説】', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(question.explanation),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('次の問題へ', style: TextStyle(fontSize: 18)),
              ),
              const SizedBox(height: 40), // Bottom padding
            ],
          ],
        ),
      ),
    );
  }
}

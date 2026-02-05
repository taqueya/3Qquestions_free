import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/providers.dart';
import '../../data/model/question.dart';

class QuizPage extends ConsumerStatefulWidget {
  final QuizMode mode;
  final String target;
  final bool resume;
  final int? startIndex;
  final int? correctCount;
  final int? answeredCount;
  final Map<int, Map<String, dynamic>>? answerResults;

  const QuizPage({
    super.key,
    required this.mode,
    required this.target,
    this.resume = false,
    this.startIndex,
    this.correctCount,
    this.answeredCount,
    this.answerResults,
  });

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // アプリがバックグラウンドに行く時に進捗を保存
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(quizProvider.notifier).saveProgressNow();
    }
    // スリープ復帰時にUIを強制再描画
    if (state == AppLifecycleState.resumed) {
      if (mounted) setState(() {});
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() {});
      });
    }
  }

  void _handleOptionTap(String option, Question question) {
    final state = ref.read(quizProvider);
    // 既に回答済みの場合は何もしない
    if (state.answerResults.containsKey(question.id)) return;

    final isCorrect = option == question.correctOption;
    
    // 新しいメソッドで回答を記録
    ref.read(quizProvider.notifier).recordAnswerWithDetails(
      question.id, 
      isCorrect, 
      option,
    );

    if (isCorrect) {
      if (widget.mode == QuizMode.mistake) {
        ref.read(quizProvider.notifier).deleteMistake(question.id);
      }
    } else {
      ref.read(quizProvider.notifier).saveMistake(question.id);
    }
  }

  void _goToNext() {
    final state = ref.read(quizProvider);
    if (state.currentIndex >= state.questions.length - 1) {
      // 最後の問題 - 終了
      ref.read(quizProvider.notifier).finishCurrentAndNext();
    } else {
      ref.read(quizProvider.notifier).nextQuestion();
    }
  }

  void _goToPrev() {
    ref.read(quizProvider.notifier).prevQuestion();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizProvider);

    // Trigger load if initial state (handles provider recreation on auth change)
    if (state.isInitial && !state.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.resume && widget.startIndex != null) {
          // 続きから解く
          ref.read(quizProvider.notifier).loadQuestionsFromProgress(
            widget.mode,
            widget.target,
            widget.startIndex!,
            widget.correctCount ?? 0,
            widget.answeredCount ?? 0,
            widget.answerResults,
          );
        } else {
          // 最初から解く
          ref.read(quizProvider.notifier).loadQuestions(
            widget.mode,
            widget.target,
          );
        }
      });
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        // 完了時に進捗を削除
        await ref.read(quizProvider.notifier).deleteProgress();
        if (mounted && context.mounted) {
           context.go('/result', extra: {
             'correctCount': state.correctCount,
             'totalCount': state.answeredCount,
             'skippedCount': state.skippedCount,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            // 戻る前に進捗を保存
            await ref.read(quizProvider.notifier).saveProgressNow();
            // ホーム画面の進捗リストを更新するためプロバイダーを無効化
            ref.invalidate(userProgressProvider);
            if (context.mounted) {
              context.pop();
            }
          },
        ),
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
            SelectableText(
              question.questionText,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),

            // Options
            ...question.options.map((option) {
              final answerResult = state.currentAnswerResult;
              final isAnswered = answerResult != null;
              final selectedOption = answerResult?['selectedOption'] as String?;
              final isCorrect = answerResult?['isCorrect'] as bool? ?? false;
              
              Color? btnColor;
              if (isAnswered) {
                if (option == question.correctOption) {
                  btnColor = Colors.green.shade100;
                } else if (option == selectedOption && !isCorrect) {
                  btnColor = Colors.red.shade100;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: isAnswered
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: btnColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: SelectableText(
                          option,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                      )
                    : OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: btnColor,
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _handleOptionTap(option, question),
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 16, color: Colors.black87),
                          maxLines: 5,
                        ),
                      ),
              );
            }).toList(),

            const SizedBox(height: 24),

            // Feedback & Explanation (回答済みの場合)
            if (state.isCurrentAnswered) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: state.currentAnswerResult!['isCorrect'] ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: state.currentAnswerResult!['isCorrect'] ? Colors.green : Colors.red),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.currentAnswerResult!['isCorrect'] ? '正解！' : '不正解...',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: state.currentAnswerResult!['isCorrect'] ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('【解説】', style: TextStyle(fontWeight: FontWeight.bold)),
                    SelectableText(question.explanation),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 前後移動ボタン
            Row(
              children: [
                // 前の問題ボタン
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.currentIndex > 0 ? _goToPrev : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('前の問題'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 次の問題/終了ボタン
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _goToNext,
                    icon: Icon(state.currentIndex >= state.questions.length - 1 
                        ? Icons.check 
                        : Icons.arrow_forward),
                    label: Text(state.currentIndex >= state.questions.length - 1 
                        ? '終了' 
                        : (state.isCurrentAnswered ? '次の問題' : 'スキップ')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: state.isCurrentAnswered 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

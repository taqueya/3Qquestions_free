import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  void initState() {
    super.initState();
    // ホームページ表示時に進捗を再読み込み
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(userProgressProvider);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final examCountsAsync = ref.watch(examCountsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '知財管理技能検定3級(学科)\n過去問アカデミア',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        actions: [
          // ログアウトボタン
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: 'ログアウト',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 無料版バナー


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
                        items: exams.map((e) {
                          return DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => selectedExam = val);
                        },
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
                    // 続きから解くボタン（進捗がある場合 - 最新1件のみ）
                    ref.watch(userProgressProvider).when(
                      data: (progressList) {
                        final examProgress = progressList.where((p) => p['mode'] == 'exam').toList();
                        if (examProgress.isEmpty) return const SizedBox.shrink();
                        
                        final p = examProgress.first; // 最新の1件のみ
                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text('途中の問題', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.play_circle_outline),
                              label: Text('${p['target']} (${(p['current_index'] as int) + 1}問目から)'),
                              onPressed: () {
                                context.push('/quiz', extra: {
                                  'mode': QuizMode.exam,
                                  'target': p['target'],
                                  'resume': true,
                                  'currentIndex': p['current_index'],
                                  'correctCount': p['correct_count'],
                                  'answeredCount': p['answered_count'],
                                  'answerResults': p['answer_results'],
                                });
                              },
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('分野別で解く', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                      ],
                    ),
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
                    // 続きから解くボタン（進捗がある場合 - 最新1件のみ）
                    ref.watch(userProgressProvider).when(
                      data: (progressList) {
                        final categoryProgress = progressList.where((p) => p['mode'] == 'category').toList();
                        if (categoryProgress.isEmpty) return const SizedBox.shrink();
                        
                        final p = categoryProgress.first; // 最新の1件のみ
                        return Column(
                          children: [
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),
                            const Text('途中の問題', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.play_circle_outline),
                              label: Text('${p['target']} (${(p['current_index'] as int) + 1}問目から)'),
                              onPressed: () {
                                context.push('/quiz', extra: {
                                  'mode': QuizMode.category,
                                  'target': p['target'],
                                  'resume': true,
                                  'currentIndex': p['current_index'],
                                  'correctCount': p['correct_count'],
                                  'answeredCount': p['answered_count'],
                                  'answerResults': p['answer_results'],
                                });
                              },
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('苦手リストのリセット'),
                    content: const Text('苦手リストを全て削除しますか？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('キャンセル'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('削除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  try {
                    await ref.read(quizProvider.notifier).resetMistakes();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('苦手リストをリセットしました')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('リセットに失敗しました: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
              child: const Text('苦手リストをリセット', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }



  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // 課金状態をクリア (不要)
              
              // Supabaseからログアウト
              await Supabase.instance.client.auth.signOut();
              
              // ログイン画面に遷移（GoRouterのリダイレクトで自動的に行われる）
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ログアウト', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}


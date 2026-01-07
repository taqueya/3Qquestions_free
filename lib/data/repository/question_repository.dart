import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../model/question.dart';

class QuestionRepository {
  final SupabaseClient _client;

  QuestionRepository(this._client);

  // --- 1. 問題を「回数」で取得 ---
  Future<List<Question>> getQuestionsByExam(String examCount) async {
    try {
      final response = await _client
          .from('questions') // テーブル名を直接指定(定数がなければ)
          .select()
          .eq('exam_count', examCount)
          .order('question_number', ascending: true);

      // 【修正ポイント】nullなら空リストにする (?? [])
      final data = response as List<dynamic>? ?? [];
      return data.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      // エラー時は空リストを返してアプリが落ちないようにする
      print('Error fetching questions by exam: $e');
      return [];
    }
  }

  // --- 2. 問題を「カテゴリー」で取得 ---
  Future<List<Question>> getQuestionsByCategory(String category) async {
    try {
      final response = await _client
          .from('questions')
          .select()
          .eq('category', category);

      final data = response as List<dynamic>? ?? [];
      final questions = data.map((json) => Question.fromJson(json)).toList();
      
      // ランダムに出題したい場合はシャッフル
      questions.shuffle();
      return questions;
    } catch (e) {
      print('Error fetching questions by category: $e');
      return [];
    }
  }

  // --- 3. 苦手問題を取得 ---
  Future<List<Question>> getMistakenQuestions(String userId) async {
    try {
      // 3-1. 間違えたIDリストを取得
      final mistakeResponse = await _client
          .from('user_mistakes')
          .select('question_id')
          .eq('user_id', userId);

      final mistakeList = mistakeResponse as List<dynamic>? ?? [];
      if (mistakeList.isEmpty) return [];

      final questionIds = mistakeList.map((m) => m['question_id'] as int).toList();

      // 3-2. そのIDの問題文を取得
      final response = await _client
          .from('questions')
          .select()
          .inFilter('id', questionIds); // ここは inFilter でOK

      final data = response as List<dynamic>? ?? [];
      return data.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching mistaken questions: $e');
      return [];
    }
  }

  // --- 4. 間違いを保存 ---
  // --- 4. 間違いを保存 ---
  Future<void> saveMistake(String userId, int questionId) async {
    try {
      print('[Repo] Saving mistake for user: $userId, question: $questionId');
      
      // Use upsert with conflict handling if constraint exists, or just normal upsert
      // Note: On PostgreSQL, upsert needs a constraint to conflict on for 'onConflict'.
      // If no unique index on (user_id, question_id), duplicate rows might occur if not careful.
      // But 'upsert' in Supabase usually handles ID-based updates.
      // Here we want to ensure uniqueness. Ideally DB has unique index on (user_id, question_id).
      
      await _client.from(AppConstants.userMistakesTable).upsert(
        {
          'user_id': userId,
          'question_id': questionId,
          'created_at': DateTime.now().toIso8601String(),
        },
        // ignoreDuplicates: true, // Optional: if we just want to ensure it's there
      );
      print('[Repo] Mistake saved successfully.');
    } catch (e) {
      print('Error saving mistake: $e');
      rethrow; // Let UI/Provider know
    }
  }

  // --- 5. 実施回の一覧を取得 (ここがエラーの原因でした) ---
  Future<List<String>> getExamCounts() async {
    try {
      final response = await _client
          .from('questions')
          .select('exam_count');

      // 【ここが重要】responseがnullのときにクラッシュしないよう ?? [] を追加
      final data = response as List<dynamic>? ?? [];
      
      // 重複を排除してリスト化
      final all = data
          .map((e) => e['exam_count'] as String? ?? '') // 中身がnullなら空文字
          .where((e) => e.isNotEmpty) // 空文字を除外
          .toSet()
          .toList();
          
      all.sort(); // 並び替え
      return all;
    } catch (e) {
      print('Error fetching exam counts: $e');
      return [];
    }
  }

  // --- 6. カテゴリーの一覧を取得 ---
  Future<List<String>> getCategories() async {
    try {
      final response = await _client
          .from('questions')
          .select('category');

      final data = response as List<dynamic>? ?? [];
      
      final all = data
          .map((e) => e['category'] as String? ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
          
      all.sort();
      return all;
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }
}
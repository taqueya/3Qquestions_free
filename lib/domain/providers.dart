import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/repository/question_repository.dart';
import '../data/model/question.dart';
import '../core/constants.dart';

// Supabase Client Provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Repository Provider
final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return QuestionRepository(ref.watch(supabaseClientProvider));
});

// User ID Provider (Watch Auth State)
final userIdProvider = Provider<String>((ref) {
  final user = ref.watch(userProvider).value;
  // Make sure not to return default UUID if user is actually null in strict context,
  // but for "User Mistakes" in DB, we need a valid UUID.
  // If not logged in, we retain the guest UUID or handle logic elsewhere.
  return user?.id ?? '00000000-0000-0000-0000-000000000000';
});

// Auth User Stream
final userProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((event) => event.session?.user);
});

// -----------------------------------------------------------------------------
// Quiz State
// -----------------------------------------------------------------------------

enum QuizMode { exam, category, mistake }

class QuizState {
  final List<Question> questions;
  final int currentIndex;
  final bool isLoading;
  final String? error;
  final int correctCount;
  final int answeredCount;
  final bool isInitial;
  final QuizMode? mode;
  final String? target;
  // 各問題の回答状態を記録: questionId -> {answered: bool, isCorrect: bool, selectedOption: String}
  final Map<int, Map<String, dynamic>> answerResults;

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
    this.correctCount = 0,
    this.answeredCount = 0,
    this.isInitial = false,
    this.mode,
    this.target,
    this.answerResults = const {},
  });

  Question? get currentQuestion => 
      (questions.isNotEmpty && currentIndex < questions.length) 
      ? questions[currentIndex] 
      : null;

  // 現在の問題が回答済みかどうか
  bool get isCurrentAnswered {
    final q = currentQuestion;
    if (q == null) return false;
    return answerResults.containsKey(q.id);
  }

  // 現在の問題の回答結果を取得
  Map<String, dynamic>? get currentAnswerResult {
    final q = currentQuestion;
    if (q == null) return null;
    return answerResults[q.id];
  }

  // 無回答数を算出
  int get skippedCount => questions.length - answeredCount;

  QuizState copyWith({
    List<Question>? questions,
    int? currentIndex,
    bool? isLoading,
    String? error,
    int? correctCount,
    int? answeredCount,
    bool? isInitial,
    QuizMode? mode,
    String? target,
    Map<int, Map<String, dynamic>>? answerResults,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      correctCount: correctCount ?? this.correctCount,
      answeredCount: answeredCount ?? this.answeredCount,
      isInitial: isInitial ?? this.isInitial,
      mode: mode ?? this.mode,
      target: target ?? this.target,
      answerResults: answerResults ?? this.answerResults,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final QuestionRepository _repository;
  final String _userId;

  QuizNotifier(this._repository, this._userId) : super(const QuizState(isInitial: true));

  Future<void> loadQuestions(QuizMode mode, String target) async {
    print('[QuizNotifier] loadQuestions started. Mode: $mode, Target: $target');
    state = state.copyWith(
      isLoading: true, 
      isInitial: false, 
      error: null, 
      currentIndex: 0, 
      questions: [], 
      correctCount: 0, 
      answeredCount: 0,
      mode: mode,
      target: target,
    );
    try {
      List<Question> data;
      switch (mode) {
        case QuizMode.exam:
          print('[QuizNotifier] Fetching by exam...');
          data = await _repository.getQuestionsByExam(target);
          break;
        case QuizMode.category:
          print('[QuizNotifier] Fetching by category...');
          data = await _repository.getQuestionsByCategory(target);
          break;
        case QuizMode.mistake:
          print('[QuizNotifier] Fetching mistakes...');
          data = await _repository.getMistakenQuestions(_userId);
          data.shuffle();
          break;
      }
      print('[QuizNotifier] Questions loaded: ${data.length}');
      if (!mounted) {
        print('[QuizNotifier] Notifier disposed, skipping state update.');
        return;
      }
      state = state.copyWith(questions: data, isLoading: false);
    } catch (e, stack) {
      print('[QuizNotifier] Error loading questions: $e');
      print(stack);
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  // 進捗から問題を読み込む（続きから解く）
  Future<void> loadQuestionsFromProgress(
    QuizMode mode, 
    String target, 
    int startIndex, 
    int correct, 
    int answered,
    Map<int, Map<String, dynamic>>? answerResults,
  ) async {
    print('[QuizNotifier] loadQuestionsFromProgress. Mode: $mode, Target: $target, StartIndex: $startIndex');
    state = state.copyWith(
      isLoading: true, 
      isInitial: false, 
      error: null, 
      questions: [],
      mode: mode,
      target: target,
    );
    try {
      List<Question> data;
      switch (mode) {
        case QuizMode.exam:
          data = await _repository.getQuestionsByExam(target);
          break;
        case QuizMode.category:
          data = await _repository.getQuestionsByCategory(target);
          break;
        case QuizMode.mistake:
          data = await _repository.getMistakenQuestions(_userId);
          break;
      }
      print('[QuizNotifier] Questions loaded: ${data.length}, resuming from index: $startIndex, answers: ${answerResults?.length ?? 0}');
      if (!mounted) return;
      
      state = state.copyWith(
        questions: data, 
        isLoading: false,
        currentIndex: startIndex,
        correctCount: correct,
        answeredCount: answered,
        answerResults: answerResults ?? {},
      );
    } catch (e, stack) {
      print('[QuizNotifier] Error loading questions from progress: $e');
      print(stack);
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
  }

  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
      _saveProgressAsync();
    }
  }

  void prevQuestion() {
    if (state.currentIndex > 0) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
      _saveProgressAsync();
    }
  }

  // 現在の問題を完了して次へ進む（最後の問題なら終了）
  void finishCurrentAndNext() {
    if (state.currentIndex >= state.questions.length - 1) {
      // 最後の問題 - currentIndexを問題数に設定して終了を示す
      state = state.copyWith(currentIndex: state.questions.length);
    } else {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
      _saveProgressAsync();
    }
  }
  
  // 回答を記録（問題IDと回答詳細を保持）
  void recordAnswerWithDetails(int questionId, bool isCorrect, String selectedOption) {
    // 既に回答済みの場合は記録しない
    if (state.answerResults.containsKey(questionId)) return;
    
    final newResults = Map<int, Map<String, dynamic>>.from(state.answerResults);
    newResults[questionId] = {
      'isCorrect': isCorrect,
      'selectedOption': selectedOption,
    };
    
    state = state.copyWith(
      answeredCount: state.answeredCount + 1,
      correctCount: state.correctCount + (isCorrect ? 1 : 0),
      answerResults: newResults,
    );
  }

  // 進捗を自動保存（非同期）
  Future<void> _saveProgressAsync() async {
    if (state.mode == null || state.target == null) return;
    if (state.mode == QuizMode.mistake) return; // 苦手モードは進捗保存しない
    
    await _repository.saveProgress(
      userId: _userId,
      mode: state.mode == QuizMode.exam ? 'exam' : 'category',
      target: state.target!,
      currentIndex: state.currentIndex,
      correctCount: state.correctCount,
      answeredCount: state.answeredCount,
      answerResults: state.answerResults,
    );
  }

  // 進捗を即座に保存（戻るボタン用）
  Future<void> saveProgressNow() async {
    await _saveProgressAsync();
  }

  // 進捗を削除（完了時）
  Future<void> deleteProgress() async {
    if (state.mode == null || state.target == null) return;
    if (state.mode == QuizMode.mistake) return;
    
    await _repository.deleteProgress(
      userId: _userId,
      mode: state.mode == QuizMode.exam ? 'exam' : 'category',
      target: state.target!,
    );
  }

  Future<void> saveMistake(int questionId) async {
    try {
      await _repository.saveMistake(_userId, questionId);
    } catch (e) {
      print('Failed to save mistake: $e');
    }
  }
  
  Future<void> deleteMistake(int questionId) async {
    await _repository.deleteMistake(_userId, questionId);
  }

  Future<void> resetMistakes() async {
    await _repository.deleteAllMistakes(_userId);
  }
}

final quizProvider = StateNotifierProvider.autoDispose<QuizNotifier, QuizState>((ref) {
  final repo = ref.watch(questionRepositoryProvider);
  final userId = ref.watch(userIdProvider);
  return QuizNotifier(repo, userId);
});

// -----------------------------------------------------------------------------
// Metadata Providers (for Dropdowns)
// -----------------------------------------------------------------------------

final examCountsProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getExamCounts();
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final repo = ref.watch(questionRepositoryProvider);
  return repo.getCategories();
});

// ユーザーの全進捗を取得
final userProgressProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(questionRepositoryProvider);
  final userId = ref.watch(userIdProvider);
  return repo.getAllProgress(userId);
});

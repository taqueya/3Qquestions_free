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

  const QuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.error,
    this.correctCount = 0,
    this.answeredCount = 0,
    this.isInitial = false,
  });

  Question? get currentQuestion => 
      (questions.isNotEmpty && currentIndex < questions.length) 
      ? questions[currentIndex] 
      : null;

  QuizState copyWith({
    List<Question>? questions,
    int? currentIndex,
    bool? isLoading,
    String? error,
    int? correctCount,
    int? answeredCount,
    bool? isInitial,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      correctCount: correctCount ?? this.correctCount,
      answeredCount: answeredCount ?? this.answeredCount,
      isInitial: isInitial ?? this.isInitial,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final QuestionRepository _repository;
  final String _userId;

  QuizNotifier(this._repository, this._userId) : super(const QuizState(isInitial: true));

  Future<void> loadQuestions(QuizMode mode, String target) async {
    print('[QuizNotifier] loadQuestions started. Mode: $mode, Target: $target');
    state = state.copyWith(isLoading: true, isInitial: false, error: null, currentIndex: 0, questions: [], correctCount: 0, answeredCount: 0);
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
          data.shuffle();
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

  void nextQuestion() {
    // Allow going to (length) to signal completion (currentQuestion triggers null)
    if (state.currentIndex < state.questions.length) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }
  
  void recordAnswer(bool isCorrect) {
    state = state.copyWith(
      answeredCount: state.answeredCount + 1,
      correctCount: state.correctCount + (isCorrect ? 1 : 0),
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

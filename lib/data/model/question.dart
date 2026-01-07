import 'package:equatable/equatable.dart';

class Question extends Equatable {
  final int id;
  final String examCount;
  final int questionNumber;
  final String category;
  final String questionText;
  final String correctOption;
  final List<String> options;
  final String explanation;

  const Question({
    required this.id,
    required this.examCount,
    required this.questionNumber,
    required this.category,
    required this.questionText,
    required this.correctOption,
    required this.options,
    required this.explanation,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final String wrongOptionsRaw = json['wrong_options'] as String? ?? '';
    final List<String> wrongs = wrongOptionsRaw.split(';');
    final String correct = json['correct_option'] as String? ?? '';

    // Create list of options
    final List<String> allOptions = [...wrongs, correct];
    
    // Shuffle options
    // Note: Shuffling here means the order is fixed once the object is created.
    // If we want random order every time we show it (if shown multiple times), logic might change.
    // But for a quiz app, usually per-session random or per-load random is fine.
    allOptions.shuffle();

    return Question(
      id: json['id'] as int,
      examCount: json['exam_count'] as String? ?? '',
      questionNumber: json['question_number'] as int? ?? 0,
      category: json['category'] as String? ?? '',
      questionText: json['question_text'] as String? ?? '',
      correctOption: correct,
      options: allOptions,
      explanation: json['explanation'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, examCount, questionNumber, category, questionText, correctOption, options, explanation];
}

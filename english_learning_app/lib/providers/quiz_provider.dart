import 'package:flutter/material.dart';
import 'package:english_learning_app/models/word.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizProvider with ChangeNotifier {
  List<Word> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isQuizCompleted = false;
  int _totalQuestions = 0;
  int _correctAnswers = 0;
  int _wrongAnswers = 0;

  // Kalıcı istatistikler
  int _totalQuizAllTime = 0;
  int _totalCorrectAllTime = 0;
  int _totalWrongAllTime = 0;
  int _bestScore = 0;

  List<Word> get questions => _questions;
  int get currentQuestionIndex => _currentQuestionIndex;
  Word get currentQuestion => _questions[_currentQuestionIndex];
  int get score => _score;
  bool get isQuizCompleted => _isQuizCompleted;
  bool get isLastQuestion => _currentQuestionIndex == _questions.length - 1;
  int get totalQuestions => _totalQuestions;
  int get correctAnswers => _correctAnswers;
  int get wrongAnswers => _wrongAnswers;

  // Kalıcı getterlar
  int get totalQuizAllTime => _totalQuizAllTime;
  int get totalCorrectAllTime => _totalCorrectAllTime;
  int get totalWrongAllTime => _totalWrongAllTime;
  int get bestScore => _bestScore;

  QuizProvider() {
    _loadPersistentStats();
  }

  Future<void> _loadPersistentStats() async {
    final prefs = await SharedPreferences.getInstance();
    _totalQuizAllTime = prefs.getInt('totalQuizAllTime') ?? 0;
    _totalCorrectAllTime = prefs.getInt('totalCorrectAllTime') ?? 0;
    _totalWrongAllTime = prefs.getInt('totalWrongAllTime') ?? 0;
    _bestScore = prefs.getInt('bestScore') ?? 0;
    notifyListeners();
  }

  Future<void> _savePersistentStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalQuizAllTime', _totalQuizAllTime);
    await prefs.setInt('totalCorrectAllTime', _totalCorrectAllTime);
    await prefs.setInt('totalWrongAllTime', _totalWrongAllTime);
    await prefs.setInt('bestScore', _bestScore);
  }

  void setQuestions(List<Word> questions) {
    _questions = questions;
    _currentQuestionIndex = 0;
    _score = 0;
    _isQuizCompleted = false;
    _totalQuestions = questions.length;
    _correctAnswers = 0;
    _wrongAnswers = 0;
    notifyListeners();
  }

  // Quiz bittiğinde istatistikleri güncelleyen yeni fonksiyon
  Future<void> finishQuizAndSaveStats(int correct, int wrong, int score) async {
    _totalQuizAllTime++;
    _totalCorrectAllTime += correct;
    _totalWrongAllTime += wrong;
    if (score > _bestScore) {
      _bestScore = score;
    }
    await _savePersistentStats();
    notifyListeners();
  }

  // Eski nextQuestion fonksiyonu sadece quiz akışı için kullanılacak
  void nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    } else {
      _isQuizCompleted = true;
      notifyListeners();
    }
  }

  void incrementScore() {
    _score++;
    _correctAnswers++;
    notifyListeners();
  }

  void incrementWrongAnswers() {
    _wrongAnswers++;
    notifyListeners();
  }

  void resetQuiz() {
    _currentQuestionIndex = 0;
    _score = 0;
    _isQuizCompleted = false;
    _correctAnswers = 0;
    _wrongAnswers = 0;
    notifyListeners();
  }
} 
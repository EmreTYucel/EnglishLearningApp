import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/word_provider.dart';
import '../../providers/quiz_settings_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:english_learning_app/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/api_config.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _cardController;
  
  int _currentQuestionIndex = 0;
  int _correctAnswers = 0;
  int _totalQuestions = 0;
  bool _isAnswered = false;
  bool _showResult = false;
  String? _selectedAnswer;
  
  List<QuizQuestionItem> _questions = [];
  late FlutterTts _flutterTts;
  bool _isPlaying = false;
  final List<int> _askedWordIds = [];
  bool _isLoading = true;
  final List<String> _options = ['A', 'B', 'C', 'D'];

  QuizQuestionItem get _currentQuestion => _questions[_currentQuestionIndex];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeTts();
    _loadQuestions();
  }

  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isPlaying = false;
      });
    });
  }

  Future<void> _speakWord(String word) async {
    if (_isPlaying) {
      await _flutterTts.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      await _flutterTts.speak(word);
      setState(() {
        _isPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _cardController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  double get _progress => _totalQuestions == 0 ? 0.0 : (_currentQuestionIndex + 1) / _totalQuestions;

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      return _buildResultScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.home),
          tooltip: 'Ana Sayfa',
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text('Soru yüklenemedi'))
              : SafeArea(
                  child: SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height -
                            kToolbarHeight -
                            MediaQuery.of(context).padding.top,
                      ),
                      child: IntrinsicHeight(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // İlerleme çubuğu ve soru numarası
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Soru ${_currentQuestionIndex + 1} / $_totalQuestions',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Doğru: $_correctAnswers',
                                    style: const TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // İlerleme çubuğu
                              LinearProgressIndicator(
                                value: (_currentQuestionIndex + 1) / (_totalQuestions == 0 ? 1 : _totalQuestions),
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                              ),
                              const SizedBox(height: 24),
                              // Soru kartı
                              Card(
                                elevation: 6,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 20.0),
                                  child: Column(
                                    children: [
                                      Text(
                                        _currentQuestion.question,
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF223A5E),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              // Şık butonları
                              ...List.generate(
                                _currentQuestion.options.length,
                                (index) {
                                  final option = _currentQuestion.options[index];
                                  final isSelected = _selectedAnswer == option;
                                  final isCorrect = option == _currentQuestion.correctAnswer;
                                  Color bgColor = Colors.white;
                                  Color borderColor = Colors.grey[300]!;
                                  Color textColor = Colors.deepPurple;
                                  IconData? icon;
                                  if (_isAnswered) {
                                    if (isCorrect) {
                                      bgColor = Colors.green.shade100;
                                      borderColor = Colors.green;
                                      textColor = Colors.green.shade900;
                                      icon = Icons.check_circle_outline;
                                    } else if (isSelected) {
                                      bgColor = Colors.red.shade100;
                                      borderColor = Colors.red;
                                      textColor = Colors.red.shade900;
                                      icon = Icons.cancel_outlined;
                                    }
                                  } else if (isSelected) {
                                    bgColor = Colors.deepPurple.shade50;
                                    borderColor = Colors.deepPurple;
                                    textColor = Colors.deepPurple;
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: _isAnswered ? null : () => _checkAnswer(option),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 250),
                                        curve: Curves.easeInOut,
                                        decoration: BoxDecoration(
                                          color: bgColor,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: borderColor, width: 2),
                                          boxShadow: [
                                            if (isSelected || isCorrect)
                                              BoxShadow(
                                                color: borderColor.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                        child: Row(
                                          children: [
                                            Text(
                                              '${String.fromCharCode(65 + index)})',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w500,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            if (icon != null)
                                              Icon(icon, color: textColor, size: 28),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              // Motivational message
                              if (_isAnswered)
                                Column(
                                  children: [
                                    Center(
                                      child: Text(
                                        _selectedAnswer == _currentQuestion.correctAnswer
                                            ? '🎉 Harika! Doğru cevap.'
                                            : '😅 Yanlış cevap! Bir dahaki sefere daha iyi olacak.',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: _selectedAnswer == _currentQuestion.correctAnswer
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          if (_currentQuestionIndex < _questions.length - 1) {
                                            setState(() {
                                              _currentQuestionIndex++;
                                              _isAnswered = false;
                                              _selectedAnswer = null;
                                            });
                                          } else {
                                            _showResults();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(context).colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          _currentQuestionIndex < _questions.length - 1 ? 'İlerle' : 'Bitir',
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Expanded(child: Container()),
                              // Bottom summary bar
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Colors.deepPurple.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Kalan: ${_totalQuestions - _currentQuestionIndex - (_isAnswered ? 0 : 1)}',
                                      style: const TextStyle(fontSize: 16, color: Colors.deepPurple),
                                    ),
                                    Text(
                                      'Doğru: $_correctAnswers',
                                      style: const TextStyle(fontSize: 16, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  void _checkAnswer(String selectedAnswer) {
    if (_isAnswered) return;
    setState(() {
      _isAnswered = true;
      _selectedAnswer = selectedAnswer;
    });

    final isCorrect = selectedAnswer == _currentQuestion.correctAnswer;
    final word = _currentQuestion;
    final now = DateTime.now();

    if (isCorrect) {
      _correctAnswers++;
      // Üst üste doğru sayısına göre sonraki tekrar tarihini belirle
      DateTime nextReview;
      switch (word.repetitionCount + 1) { // +1 çünkü şu anki doğru cevabı da sayıyoruz
        case 1:
          nextReview = now.add(const Duration(days: 1));
          break;
        case 2:
          nextReview = now.add(const Duration(days: 3));
          break;
        case 3:
          nextReview = now.add(const Duration(days: 7));
          break;
        case 4:
          nextReview = now.add(const Duration(days: 13));
          break;
        case 5:
          nextReview = now.add(const Duration(days: 21));
          break;
        case 6:
          nextReview = now.add(const Duration(days: 30));
          break;
        default:
          nextReview = now.add(const Duration(days: 1));
      }

      // Kelimeyi güncelle
      _updateWordProgress(
        word.id,
        word.repetitionCount + 1,
        nextReview,
        word.repetitionCount + 1 >= 6,
        isCorrect: true,
        context: context,
      );
    } else {
      // Yanlış cevap verildiğinde
      _updateWordProgress(
        word.id,
        0,
        now.add(const Duration(days: 1)),
        false,
        isCorrect: false,
        context: context,
      );
    }

    // Sonucu göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isCorrect ? 'Doğru!' : 'Yanlış! Doğru cevap: ${word.correctAnswer}'),
        backgroundColor: isCorrect ? Colors.green : Colors.red,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Tamamlandı!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Doğru Cevap: $_correctAnswers/${_questions.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Başarı Oranı: %${(_correctAnswers / _questions.length * 100).toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 16,
                color: _correctAnswers / _questions.length >= 0.7 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/home');
            },
            child: const Text('Ana Sayfaya Dön'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentQuestionIndex = 0;
                _correctAnswers = 0;
                _selectedAnswer = null;
                _isAnswered = false;
              });
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _isAnswered = false;
      _selectedAnswer = null;
      _questions.clear();
      _currentQuestionIndex = 0;
      _correctAnswers = 0;
      _showResult = false;
      _askedWordIds.clear();
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final quizSettingsProvider = Provider.of<QuizSettingsProvider>(context, listen: false);
      final count = quizSettingsProvider.questionCount;
      // Exclude parametresi ile daha önce sorulan kelimeleri gönder
      final excludeParam = _askedWordIds.isNotEmpty ? '&exclude=${_askedWordIds.join(',')}' : '';
      final response = await http.get(
        Uri.parse('${ApiConfig.quizUrl}?count=$count$excludeParam'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final questionsData = data['questions'];
        if (questionsData == null || questionsData is! List || questionsData.isEmpty) {
          setState(() {
            _isLoading = false;
            _questions.clear();
          });
          return;
        }
        final questions = questionsData.map<QuizQuestionItem>((q) {
          final word = q['word'];
          final options = q['options'] as List<dynamic>;
          _askedWordIds.add(word['id']); // Sorulan kelime ID'sini kaydet
          return QuizQuestionItem(
            id: word['id'],
            word: word['english_word'],
            turkish: word['turkish_word'],
            type: QuizType.multipleChoice,
            question: '"${word['turkish_word']}" kelimesinin İngilizcesi nedir?',
            options: options.map((o) => o.toString()).toList(),
            correctAnswer: word['english_word'],
            repetitionCount: word['repetitionCount'] ?? 0,
            difficultyLevel: word['difficultyLevel'] ?? 1,
          );
        }).toList();
        setState(() {
          _questions = questions;
          _isLoading = false;
          _totalQuestions = questions.length;
        });
      } else {
        throw Exception('Failed to load questions');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _questions.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  void _updateWordProgress(int wordId, int repetitionCount, DateTime nextReview, bool isLearned, {required bool isCorrect, BuildContext? context}) {
    final wordProvider = Provider.of<WordProvider>(context!, listen: false);
    wordProvider.updateWordProgress(wordId, repetitionCount, nextReview, isLearned, isCorrect: isCorrect, context: context);
    wordProvider.reviewWord(wordId, context);
  }

  Widget _buildResultScreen() {
    final percentage = _questions.isEmpty ? 0 : (_correctAnswers / _questions.length * 100).round();
    final isGoodScore = percentage >= 70;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isGoodScore
                ? [Colors.green[400]!, Colors.green[600]!]
                : [Colors.orange[400]!, Colors.orange[600]!],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isGoodScore ? Icons.celebration : Icons.refresh,
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 30),
                Text(
                  isGoodScore ? 'Tebrikler!' : 'Tekrar Dene!',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$_correctAnswers/$_totalQuestions doğru cevap',
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Başarı Oranı: %$percentage',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isGoodScore
                            ? 'Harika! Kelimeler bir sonraki seviyeye geçti.'
                            : 'Endişelenme, pratik yapmaya devam et.',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Spaced Repetition: ${isGoodScore ? "Aralık uzatıldı" : "Aralık kısaltıldı"}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: isGoodScore ? Colors.green : Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Ana Sayfa'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _currentQuestionIndex = 0;
                            _correctAnswers = 0;
                            _isAnswered = false;
                            _showResult = false;
                            _selectedAnswer = null;
                            _questions.clear();
                            _loadQuestions();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.white),
                          ),
                        ),
                        child: const Text('Tekrar Çöz'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum QuizType {
  multipleChoice,
  typing,
  listening,
}

class QuizQuestionItem {
  final int id;
  final String word;
  final String turkish;
  final QuizType type;
  final String question;
  final List<String> options;
  final String correctAnswer;
  final int repetitionCount;
  final int difficultyLevel;

  QuizQuestionItem({
    required this.id,
    required this.word,
    required this.turkish,
    required this.type,
    required this.question,
    required this.options,
    required this.correctAnswer,
    this.repetitionCount = 0,
    this.difficultyLevel = 1,
  });
} 
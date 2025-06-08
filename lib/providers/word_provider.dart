import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../config/api_config.dart';

class Word {
  final int id;
  final String englishWord;
  final String turkishWord;
  final String? picture;
  int repetitionCount;
  DateTime? lastReviewed;
  DateTime? nextReview;
  bool isLearned;
  int difficultyLevel;
  String? category;
  String? difficulty;
  int consecutiveCorrectAnswers;
  String? wordType;

  Word({
    required this.id,
    required this.englishWord,
    required this.turkishWord,
    this.picture,
    this.repetitionCount = 0,
    this.lastReviewed,
    this.nextReview,
    this.isLearned = false,
    this.difficultyLevel = 1,
    this.category,
    this.difficulty,
    this.consecutiveCorrectAnswers = 0,
    this.wordType,
  });

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'],
      englishWord: json['englishWord'] ?? '',
      turkishWord: json['turkishWord'] ?? '',
      picture: json['picture'],
      repetitionCount: json['repetitionCount'] ?? 0,
      lastReviewed: json['lastReviewed'] != null
          ? DateTime.tryParse(json['lastReviewed'])
          : null,
      nextReview: json['nextReview'] != null
          ? DateTime.tryParse(json['nextReview'])
          : DateTime.now().add(const Duration(days: 1)),
      isLearned: json['isLearned'] ?? false,
      difficultyLevel: json['difficultyLevel'] ?? 1,
      category: json['category'],
      difficulty: json['difficulty'],
      consecutiveCorrectAnswers: json['consecutiveCorrectAnswers'] ?? 0,
      wordType: json['wordType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'englishWord': englishWord,
      'turkishWord': turkishWord,
      'category': category,
      'difficulty': difficulty,
      'repetitionCount': repetitionCount,
      'lastReviewed': lastReviewed?.toIso8601String(),
      'nextReview': nextReview?.toIso8601String(),
      'isLearned': isLearned,
      'picture': picture,
      'difficultyLevel': difficultyLevel,
      'consecutiveCorrectAnswers': consecutiveCorrectAnswers,
      'wordType': wordType,
    };
  }
}

class WordProvider extends ChangeNotifier {
  List<Word> _words = [];
  final List<Word> _todaysWords = [];
  bool _isLoading = false;
  String? _error;

  List<Word> get words => _words;
  List<Word> get todaysWords => _todaysWords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Backend'den kelime listesini çek
  Future<void> loadWords(BuildContext context) async {
    _isLoading = true;
    _error = null;
    print('loadWords fonksiyonu çağrıldı');
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('userId');
      print('SharedPreferences token: ${token ?? 'null'}');
      print('SharedPreferences userId: ${userId?.toString() ?? 'null'}');

      if (token == null || userId == null) {
        print('Oturum bilgisi bulunamadı!');
        _error = 'Oturum bilgisi bulunamadı';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConfig.wordsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      print('API isteği atıldı!');
      print('Status code: ${response.statusCode}');
      print('API yanıtı:');
      print(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _words = data.map((e) {
          final word = Word.fromJson(e);
          word.nextReview ??= DateTime.now().add(const Duration(days: 1));
          return word;
        }).toList();
        if (_words.isEmpty) {
          print('API yanıtı boş, test kelimesi ekleniyor!');
          _words.addAll([
            Word(
              id: 1,
              englishWord: 'test',
              turkishWord: 'deneme',
              repetitionCount: 0,
              lastReviewed: null,
              nextReview: DateTime.now().add(const Duration(days: 1)),
              isLearned: false,
              difficultyLevel: 1,
              picture: null,
              category: 'Test',
              difficulty: null,
            ),
          ]);
        }
        print('Yüklenen kelime sayısı: ${_words.length}');
        for (var w in _words.take(5)) {
          print('Kelime: '+w.id.toString()+" - "+w.englishWord+" / "+w.turkishWord);
        }
        _isLoading = false;
        notifyListeners();
      } else {
        print('API HATASI: ${response.body}');
        _error = 'Kelimeler yüklenemedi: ${response.body}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      print('CATCH HATASI: $e');
      _error = 'Kelimeler yüklenirken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Kelime listesini yenile
  Future<void> refreshWords(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('userId');

      if (token == null || userId == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      final response = await http.get(
        Uri.parse(ApiConfig.wordsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _words = data.map((e) {
          final word = Word.fromJson(e);
          word.nextReview ??= DateTime.now().add(const Duration(days: 1));
          return word;
        }).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Kelimeler yüklenemedi: ${response.body}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Kelimeler yüklenirken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Backend'e yeni kelime ekle
  Future<bool> addWord(BuildContext context, {
    required String englishWord,
    required String turkishWord,
    int difficultyLevel = 1,
    String? picture,
    String? wordType,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await http.post(
        Uri.parse(ApiConfig.wordsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'english_word': englishWord,
          'turkish_word': turkishWord,
          'difficulty_level': difficultyLevel,
          'picture': picture,
          'word_type': wordType,
        }),
      );
      if (response.statusCode == 201) {
        await loadWords(context); // Listeyi güncelle
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Kelime eklenemedi: ${response.body}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Kelime eklenirken hata oluştu: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Backend'e tekrar/öğrenildi güncellemesi gönder
  Future<void> markWordAsReviewed(int wordId, BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await http.post(
        Uri.parse(ApiConfig.getWordProgress(wordId.toString())),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        // Backend'den dönen güncel veriyi local state'e uygula
        final data = jsonDecode(response.body);
        final idx = _words.indexWhere((w) => w.id == wordId);
        if (idx != -1) {
          _words[idx].repetitionCount = data['repetitionCount'] ?? _words[idx].repetitionCount;
          _words[idx].isLearned = data['isLearned'] ?? _words[idx].isLearned;
          _words[idx].lastReviewed = DateTime.now();
        }
        notifyListeners();
      } else {
        _error = 'Tekrar güncellenemedi: ${response.body}';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Tekrar güncellenirken hata oluştu: $e';
      notifyListeners();
    }
  }

  List<Word> getLearnedWords() {
    return _words.where((word) => word.isLearned).toList();
  }

  List<Word> getLearningWords() {
    // Sadece quizde yanlış cevap verilen kelimeleri getir
    return _words.where((word) => 
      !word.isLearned && 
      word.consecutiveCorrectAnswers == 0  // Yanlış cevap verilen kelimeler
    ).toList();
  }

  List<Word> getReviewWords() {
    // Tekrar edilecekler: öğrenilmemiş ve en az 1 tekrar yapılmış kelimeler
    return _words.where((word) => 
      !word.isLearned && 
      word.repetitionCount > 0
    ).toList();
  }

  List<Word> getNewWords() {
    return _words.where((word) => word.repetitionCount == 0).toList();
  }

  List<Word> getTodaysWords([int count = 5]) {
    if (_words.isEmpty) return [];
    final now = DateTime.now();
    final seed = int.parse('${now.year}${now.month}${now.day}');
    final shuffled = List<Word>.from(_words);
    shuffled.shuffle(Random(seed));
    return shuffled.take(count).toList();
  }

  // Tekrar aralıklarını hesapla (gün cinsinden)
  int _calculateNextReviewInterval(int repetitionCount) {
    switch (repetitionCount) {
      case 0: return 1;    // İlk tekrar: 1 gün sonra
      case 1: return 3;    // İkinci tekrar: 3 gün sonra
      case 2: return 7;    // Üçüncü tekrar: 7 gün sonra
      case 3: return 14;   // Dördüncü tekrar: 14 gün sonra
      case 4: return 21;   // Beşinci tekrar: 21 gün sonra
      case 5: return 30;   // Altıncı tekrar: 30 gün sonra
      default: return 0;   // Öğrenildi
    }
  }

  // Sonraki tekrar zamanını hesapla
  DateTime _calculateNextReviewTime(Word word) {
    if (word.repetitionCount >= 6) {
      return DateTime.now().add(const Duration(days: 30)); // Öğrenildi, 30 gün sonra tekrar
    }
    final interval = _calculateNextReviewInterval(word.repetitionCount);
    return DateTime.now().add(Duration(days: interval));
  }

  // Tekrar zamanı gelen kelimeleri getir
  List<Word> getDueWords() {
    final now = DateTime.now();
    return _words.where((word) => 
      !word.isLearned && 
      word.nextReview != null && 
      word.nextReview!.isBefore(now)
    ).toList();
  }

  // Bugün tekrar edilecek kelimeleri getir
  List<Word> getTodaysReviewWords() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    return _words.where((word) => 
      !word.isLearned && 
      word.nextReview != null && 
      word.nextReview!.isAfter(today) && 
      word.nextReview!.isBefore(tomorrow)
    ).toList();
  }

  // Kelimeyi tekrar et ve sonraki tekrar zamanını güncelle
  Future<void> reviewWord(int wordId, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getInt('userId');

      if (token == null || userId == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      final word = words.firstWhere((w) => w.id == wordId);
      final repetitionCount = word.repetitionCount + 1;
      final isLearned = repetitionCount >= 6;
      final nextReview = _calculateNextReviewTime(word);

      final response = await http.post(
        Uri.parse(ApiConfig.getWordProgress(wordId.toString())),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'repetitionCount': repetitionCount,
          'nextReview': nextReview.toIso8601String(),
          'isLearned': isLearned,
        }),
      );

      if (response.statusCode == 200) {
        final updatedWord = Word(
          id: word.id,
          englishWord: word.englishWord,
          turkishWord: word.turkishWord,
          category: word.category,
          difficulty: word.difficulty,
          repetitionCount: repetitionCount,
          lastReviewed: DateTime.now(),
          nextReview: nextReview,
          isLearned: isLearned,
          picture: word.picture,
          difficultyLevel: word.difficultyLevel,
          consecutiveCorrectAnswers: word.consecutiveCorrectAnswers,
          wordType: word.wordType,
        );

        final index = words.indexWhere((w) => w.id == wordId);
        if (index != -1) {
          words[index] = updatedWord;
          notifyListeners();
        }
      } else {
        throw Exception('Kelime güncellenirken hata oluştu');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kelime güncellenirken hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  List<Word> getQuizWords(int count, {List<int> excludeIds = const []}) {
    final now = DateTime.now();
    final dueWords = _words.where((w) => !w.isLearned && w.nextReview != null && w.nextReview!.isBefore(now) && !excludeIds.contains(w.id)).toList();
    final newWords = _words.where((w) => !w.isLearned && w.repetitionCount == 0 && (w.nextReview == null || w.nextReview!.isBefore(now)) && !excludeIds.contains(w.id)).toList();
    final quizWords = <Word>[];
    quizWords.addAll(dueWords);
    for (var w in newWords) {
      if (!quizWords.any((q) => q.id == w.id)) quizWords.add(w);
      if (quizWords.length >= count) break;
    }
    if (quizWords.length < count) {
      final others = _words.where((w) => !w.isLearned && !quizWords.any((q) => q.id == w.id) && !excludeIds.contains(w.id)).toList();
      for (var w in others) {
        if (!quizWords.any((q) => q.id == w.id)) quizWords.add(w);
        if (quizWords.length >= count) break;
      }
    }
    // Unique ve karıştırılmış kelime listesi döndür
    final uniqueQuizWords = {for (var w in quizWords) w.id: w}.values.toList();
    uniqueQuizWords.shuffle();
    return uniqueQuizWords.take(count).toList();
  }

  Future<void> updateWordProgress(int wordId, int repetitionCount, DateTime nextReview, bool isLearned, {bool isCorrect = true, BuildContext? context}) async {
    final idx = _words.indexWhere((w) => w.id == wordId);
    if (idx != -1) {
      final today = DateTime.now();
      if (isCorrect) {
        _words[idx].consecutiveCorrectAnswers++;
        if (_words[idx].consecutiveCorrectAnswers >= 6) {
          _words[idx].isLearned = true;
          _words[idx].repetitionCount = 6;
        } else {
          _words[idx].repetitionCount = repetitionCount;
        }
      } else {
        _words[idx].consecutiveCorrectAnswers = 0;
        _words[idx].repetitionCount = 0;
        _words[idx].isLearned = false;
      }
      _words[idx].nextReview = nextReview;
      _words[idx].lastReviewed = today;
      notifyListeners();
      // Backend'e de güncelleme gönder
      if (context != null) {
        try {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          await http.post(
            Uri.parse(ApiConfig.getWordProgress(wordId.toString())),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode({
              'repetitionCount': _words[idx].repetitionCount,
              'nextReview': nextReview.toIso8601String(),
              'isLearned': _words[idx].isLearned,
            }),
          );
        } catch (e) {
          // Hata yönetimi eklenebilir
        }
      }
    }
  }
} 
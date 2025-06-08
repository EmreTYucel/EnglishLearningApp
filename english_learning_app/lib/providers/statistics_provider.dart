import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class StatisticsProvider with ChangeNotifier {
  Map<String, dynamic> _dailyStats = {};        // Günlük istatistikler
  Map<String, dynamic> _weeklyStats = {};       // Haftalık istatistikler
  Map<String, dynamic> _monthlyStats = {};      // Aylık istatistikler
  List<Map<String, dynamic>> _learningProgress = [];  // Öğrenme ilerlemesi
  bool _isLoading = false;                      // Yükleme durumu
  int _totalWords = 0;                          // Toplam kelime sayısı
  int _learnedWords = 0;                        // Öğrenilen kelime sayısı
  int _learningWords = 0;                       // Öğrenilmekte olan kelime sayısı
  int _streak = 0;                              // Seri sayısı
  DateTime _lastStudyDate = DateTime.now();     // Son çalışma tarihi
  String _token = '';

  bool get isLoading => _isLoading;
  Map<String, dynamic> get dailyStats => _dailyStats;
  Map<String, dynamic> get weeklyStats => _weeklyStats;
  Map<String, dynamic> get monthlyStats => _monthlyStats;
  List<Map<String, dynamic>> get learningProgress => _learningProgress;
  int get totalWords => _totalWords;
  int get learnedWords => _learnedWords;
  int get learningWords => _learningWords;
  int get streak => _streak;
  DateTime get lastStudyDate => _lastStudyDate;

  Future<void> loadStatistics(BuildContext context) async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token') ?? '';
      final userId = prefs.getInt('userId');

      if (userId == null) {
        throw Exception('Oturum bilgisi bulunamadı');
      }

      await loadDailyStats(userId.toString(), context);
      await loadWeeklyStats(userId.toString(), context);
      await loadMonthlyStats(userId.toString(), context);
      await loadProgressStats(userId.toString(), context);

      // Yerel depolamadan istatistikleri yükle
      _totalWords = prefs.getInt('totalWords') ?? 0;
      _learnedWords = prefs.getInt('learnedWords') ?? 0;
      _learningWords = prefs.getInt('learningWords') ?? 0;
      _streak = prefs.getInt('streak') ?? 0;
      _lastStudyDate = DateTime.parse(prefs.getString('lastStudyDate') ?? DateTime.now().toIso8601String());

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İstatistikler yüklenirken hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatistics({
    int? totalWords,
    int? learnedWords,
    int? learningWords,
    int? streak,
    DateTime? lastStudyDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (totalWords != null) {
      _totalWords = totalWords;
      await prefs.setInt('totalWords', totalWords);
    }
    
    if (learnedWords != null) {
      _learnedWords = learnedWords;
      await prefs.setInt('learnedWords', learnedWords);
    }
    
    if (learningWords != null) {
      _learningWords = learningWords;
      await prefs.setInt('learningWords', learningWords);
    }
    
    if (streak != null) {
      _streak = streak;
      await prefs.setInt('streak', streak);
    }
    
    if (lastStudyDate != null) {
      _lastStudyDate = lastStudyDate;
      await prefs.setString('lastStudyDate', lastStudyDate.toIso8601String());
    }
    
    notifyListeners();
  }

  Future<void> incrementStreak() async {
    final today = DateTime.now();
    final difference = today.difference(_lastStudyDate).inDays;
    
    if (difference == 1) {
      _streak++;
      await updateStatistics(streak: _streak, lastStudyDate: today);
    } else if (difference > 1) {
      _streak = 1;
      await updateStatistics(streak: _streak, lastStudyDate: today);
    }
  }

  // Günlük öğrenilen kelime sayısı
  int getDailyLearnedWords() {
    return _dailyStats['learnedWords'] ?? 0;
  }

  // Günlük doğru cevap oranı
  double getDailyAccuracy() {
    final total = _dailyStats['totalQuestions'] ?? 0;
    final correct = _dailyStats['correctAnswers'] ?? 0;
    return total > 0 ? (correct / total * 100) : 0;
  }

  // Haftalık öğrenilen kelime sayısı
  int getWeeklyLearnedWords() {
    return _weeklyStats['learnedWords'] ?? 0;
  }

  // Haftalık doğru cevap oranı
  double getWeeklyAccuracy() {
    final total = _weeklyStats['totalQuestions'] ?? 0;
    final correct = _weeklyStats['correctAnswers'] ?? 0;
    return total > 0 ? (correct / total * 100) : 0;
  }

  // Aylık öğrenilen kelime sayısı
  int getMonthlyLearnedWords() {
    return _monthlyStats['learnedWords'] ?? 0;
  }

  // Aylık doğru cevap oranı
  double getMonthlyAccuracy() {
    final total = _monthlyStats['totalQuestions'] ?? 0;
    final correct = _monthlyStats['correctAnswers'] ?? 0;
    return total > 0 ? (correct / total * 100) : 0;
  }

  // Toplam öğrenilen kelime sayısı
  int getTotalLearnedWords() {
    return _monthlyStats['totalLearnedWords'] ?? 0;
  }

  // Öğrenme seviyesi dağılımı
  Map<String, int> getLearningLevelDistribution() {
    return Map<String, int>.from(_monthlyStats['learningLevelDistribution'] ?? {});
  }

  // En çok hata yapılan kelimeler
  List<Map<String, dynamic>> getMostMistakenWords() {
    final List<dynamic> words = _monthlyStats['mostMistakenWords'] ?? [];
    return words.cast<Map<String, dynamic>>();
  }

  // En iyi performans gösterilen kategoriler
  List<Map<String, dynamic>> getBestPerformingCategories() {
    final List<dynamic> categories = _monthlyStats['bestPerformingCategories'] ?? [];
    return categories.cast<Map<String, dynamic>>();
  }

  Future<void> loadDailyStats(String userId, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getDailyStats(userId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        _dailyStats = json.decode(response.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Günlük istatistikleri yüklenirken hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> loadWeeklyStats(String userId, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getWeeklyStats(userId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        _weeklyStats = json.decode(response.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Haftalık istatistikleri yüklenirken hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> loadMonthlyStats(String userId, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getMonthlyStats(userId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        _monthlyStats = json.decode(response.body);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Aylık istatistikleri yüklenirken hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> loadProgressStats(String userId, BuildContext context) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.getProgressStats(userId)),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _learningProgress = List<Map<String, dynamic>>.from(data['progress'] ?? []);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İlerleme istatistikleri yüklenirken hata oluştu: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 
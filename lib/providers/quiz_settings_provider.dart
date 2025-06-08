import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Quiz ayarları yönetimi provider sınıfı
class QuizSettingsProvider with ChangeNotifier {
  // Quiz ayarları için değişkenler
  int _questionCount = 10;        // Soru sayısı
  bool _shuffleQuestions = true;  // Soruları karıştırma
  bool _showHints = true;         // İpuçlarını gösterme
  int _timePerQuestion = 30;      // Soru başına süre (saniye)

  // Getter metodları
  int get questionCount => _questionCount;
  bool get shuffleQuestions => _shuffleQuestions;
  bool get showHints => _showHints;
  int get timePerQuestion => _timePerQuestion;

  // Constructor - ayarları yükle
  QuizSettingsProvider() {
    _loadSettings();
  }

  // Ayarları yerel depolamadan yükle
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _questionCount = prefs.getInt('questionCount') ?? 10;
    _shuffleQuestions = prefs.getBool('shuffleQuestions') ?? true;
    _showHints = prefs.getBool('showHints') ?? true;
    _timePerQuestion = prefs.getInt('timePerQuestion') ?? 30;
    notifyListeners();
  }

  // Soru sayısını ayarla (5-50 arası)
  Future<void> setQuestionCount(int count) async {
    if (count < 5) count = 5;
    if (count > 50) count = 50;
    _questionCount = count;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('questionCount', count);
    notifyListeners();
  }

  // Soruları karıştırma ayarını güncelle
  Future<void> setShuffleQuestions(bool value) async {
    _shuffleQuestions = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shuffleQuestions', value);
    notifyListeners();
  }

  // İpuçlarını gösterme ayarını güncelle
  Future<void> setShowHints(bool value) async {
    _showHints = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showHints', value);
    notifyListeners();
  }

  // Soru başına süreyi ayarla (10-120 saniye arası)
  Future<void> setTimePerQuestion(int seconds) async {
    if (seconds < 10) seconds = 10;
    if (seconds > 120) seconds = 120;
    _timePerQuestion = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('timePerQuestion', seconds);
    notifyListeners();
  }
} 
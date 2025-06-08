// API yapılandırma sınıfı
class ApiConfig {
  // API base URL'i
  // static const String baseUrl = 'https://api.englishlearningapp.com'; // Prodüksiyon URL'i
  // static const String baseUrl = 'http://10.0.2.2:3000'; // Android Emülatör için
  static const String baseUrl = 'http://localhost:3000'; // Geliştirme için

  // API endpoint'leri
  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get registerUrl => '$baseUrl/api/auth/register';
  static String get changePasswordUrl => '$baseUrl/api/auth/change-password';
  static String get wordsUrl => '$baseUrl/api/words';
  static String get quizUrl => '$baseUrl/api/words/quiz';
  static String get uploadUrl => '$baseUrl/api/words/upload';
  
  // İstatistik endpoint'leri
  static String getDailyStats(String userId) => '$baseUrl/api/statistics/daily/$userId';
  static String getWeeklyStats(String userId) => '$baseUrl/api/statistics/weekly/$userId';
  static String getMonthlyStats(String userId) => '$baseUrl/api/statistics/monthly/$userId';
  static String getProgressStats(String userId) => '$baseUrl/api/statistics/progress/$userId';
  
  // Kelime ilerleme endpoint'leri
  static String getWordProgress(String wordId) => '$baseUrl/api/words/$wordId/progress';
  
  // Resim URL'i
  static String getImageUrl(String path) => '$baseUrl$path';
} 
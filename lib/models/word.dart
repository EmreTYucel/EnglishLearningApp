// Kelime modeli sınıfı
class Word {
  final int id;                    // Kelime ID'si
  final String englishWord;        // İngilizce kelime
  final String turkishWord;        // Türkçe kelime
  final String? picture;           // Kelime resmi
  int repetitionCount;            // Tekrar sayısı
  int consecutiveCorrectAnswers;  // Ardışık doğru cevap sayısı
  DateTime? lastReviewed;         // Son gözden geçirme tarihi
  DateTime? nextReview;           // Sonraki gözden geçirme tarihi
  bool isLearned;                 // Öğrenildi mi?
  final int difficultyLevel;      // Zorluk seviyesi

  // Constructor
  Word({
    required this.id,
    required this.englishWord,
    required this.turkishWord,
    this.picture,
    this.repetitionCount = 0,
    this.consecutiveCorrectAnswers = 0,
    this.lastReviewed,
    this.nextReview,
    this.isLearned = false,
    this.difficultyLevel = 1,
  });

  // JSON'dan Word nesnesi oluştur
  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: json['id'] as int,
      englishWord: json['englishWord'] as String,
      turkishWord: json['turkishWord'] as String,
      picture: json['picture'] as String?,
      repetitionCount: json['repetitionCount'] as int? ?? 0,
      consecutiveCorrectAnswers: json['consecutiveCorrectAnswers'] as int? ?? 0,
      lastReviewed: json['lastReviewed'] != null 
          ? DateTime.parse(json['lastReviewed'] as String)
          : null,
      nextReview: json['nextReview'] != null
          ? DateTime.parse(json['nextReview'] as String)
          : null,
      isLearned: json['isLearned'] as bool? ?? false,
      difficultyLevel: json['difficultyLevel'] as int? ?? 1,
    );
  }

  // Word nesnesini JSON'a dönüştür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'englishWord': englishWord,
      'turkishWord': turkishWord,
      'picture': picture,
      'repetitionCount': repetitionCount,
      'consecutiveCorrectAnswers': consecutiveCorrectAnswers,
      'lastReviewed': lastReviewed?.toIso8601String(),
      'nextReview': nextReview?.toIso8601String(),
      'isLearned': isLearned,
      'difficultyLevel': difficultyLevel,
    };
  }
} 
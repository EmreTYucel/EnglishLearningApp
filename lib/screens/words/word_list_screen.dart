import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:english_learning_app/providers/word_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/auth_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:english_learning_app/providers/theme_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../config/api_config.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});

  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  
  @override
  void initState() {
    super.initState();
    _initTts();
    Future.microtask(() {
      print('WordListScreen initState çalıştı');
      final wordProvider = Provider.of<WordProvider>(context, listen: false);
      wordProvider.loadWords(context);
    });
  }

  Future<void> _initTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      await _flutterTts.speak(text);
      setState(() => _isSpeaking = true);
    }
  }

  List<dynamic> _filteredWords(List<dynamic> words) {
    List<dynamic> filtered = words;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((word) =>
        word.englishWord.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        word.turkishWord.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    switch (_selectedFilter) {
      case 'learned':
        filtered = filtered.where((word) => word.isLearned).toList();
        break;
      case 'learning':
        filtered = Provider.of<WordProvider>(context, listen: false).getLearningWords();
        break;
      case 'review':
        filtered = Provider.of<WordProvider>(context, listen: false).getReviewWords();
        break;
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    print('WordListScreen build çalıştı');
    final wordProvider = Provider.of<WordProvider>(context);
    print('Widgetta kelime sayısı: ${wordProvider.words.length}');
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Consumer<WordProvider>(
          builder: (context, wordProvider, _) {
            final words = wordProvider.words;
            final filteredWords = _filteredWords(words);
            return Scaffold(
              appBar: AppBar(
                title: const Text('Kelime Listesi'),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _showAddWordDialog(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.home),
                    tooltip: 'Ana Ekrana Dön',
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Search and Filter Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Search Bar
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Kelime ara...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('all', 'Tümü'),
                              const SizedBox(width: 8),
                              _buildFilterChip('learned', 'Öğrenilenler'),
                              const SizedBox(width: 8),
                              _buildFilterChip('learning', 'Öğreniliyor'),
                              const SizedBox(width: 8),
                              _buildFilterChip('review', 'Tekrar Edilecek'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Words List
                  Expanded(
                    child: Column(
                      children: [
                        Text('Toplam kelime: ${words.length}'),
                        Expanded(
                          child: filteredWords.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Kelime bulunamadı',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filteredWords.length,
                                  itemBuilder: (context, index) {
                                    final word = filteredWords[index];
                                    return _buildWordCard(word);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildWordCard(Word word) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () => _showWordDetail(word),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.englishWord,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          word.turkishWord,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (word.wordType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        word.wordType!,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: word.consecutiveCorrectAnswers > 0
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      word.isLearned ? '6/6' : '${word.consecutiveCorrectAnswers}/6',
                      style: TextStyle(
                        color: word.isLearned || word.consecutiveCorrectAnswers > 0
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (word.nextReview != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: word.nextReview!.isBefore(DateTime.now())
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        word.isLearned
                            ? 'Öğrenildi'
                            : (word.nextReview != null ? _formatDate(word.nextReview!) : 'Yakında'),
                        style: TextStyle(
                          color: word.isLearned
                              ? Colors.green
                              : (word.nextReview != null && word.nextReview!.isBefore(DateTime.now())
                                  ? Colors.red
                                  : Colors.grey),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelIndicator(int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getLevelColor(level),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Seviye $level',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      case 6:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  void _showWordDetail(Word word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (word.picture != null && word.picture!.isNotEmpty)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            ApiConfig.getImageUrl(word.picture!),
                            width: 180,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                word.englishWord,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                word.turkishWord,
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isSpeaking ? Icons.stop : Icons.volume_up,
                            color: _isSpeaking ? Colors.red : Colors.blue,
                          ),
                          onPressed: () => _speak(word.englishWord),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildDetailSection('Seviye', _buildLevelIndicator(word.repetitionCount + 1)),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Durum',
                      Row(
                        children: [
                          Icon(
                            word.isLearned ? Icons.check_circle : Icons.schedule,
                            color: word.isLearned ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(word.isLearned ? 'Öğrenildi' : 'Öğreniliyor'),
                        ],
                      ),
                    ),
                    if (word.wordType != null) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Kelime Türü',
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            word.wordType!,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.go('/quiz');
                      },
                      child: const Text('Bu Kelimeyi Çalış'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, Widget? content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (content != null) content,
      ],
    );
  }

  void _showAddWordDialog(BuildContext context) {
    final englishController = TextEditingController();
    final turkishController = TextEditingController();
    int level = 1;
    String? selectedCategory;
    String? selectedWordType;
    XFile? selectedImage;
    bool isLoading = false;
    final List<String> categories = [
      'Greetings',
      'Basic Words',
      'Food & Drink',
      'Adjectives',
      'Emotions',
      'Verbs',
      'Nouns',
    ];

    final List<String> wordTypes = [
      'noun', // isim
      'verb', // fiil
      'adjective', // sıfat
      'adverb', // zarf
      'pronoun', // zamir
      'preposition', // edat
      'conjunction', // bağlaç
      'interjection', // ünlem
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickImage() async {
              final picker = ImagePicker();
              final picked = await picker.pickImage(source: ImageSource.gallery);
              if (picked != null) {
                setState(() => selectedImage = picked);
              }
            }

            Future<void> addWord() async {
              if (englishController.text.isEmpty || turkishController.text.isEmpty) return;
              setState(() => isLoading = true);
              String? imageUrl;
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final token = authProvider.token;
              if (selectedImage != null) {
                var req = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadUrl));
                if (token != null) req.headers['Authorization'] = 'Bearer $token';
                if (kIsWeb) {
                  // Web için
                  final bytes = await selectedImage!.readAsBytes();
                  req.files.add(http.MultipartFile.fromBytes(
                    'image',
                    bytes,
                    filename: selectedImage!.name,
                  ));
                } else {
                  // Mobil için
                  req.files.add(await http.MultipartFile.fromPath('image', selectedImage!.path));
                }
                var res = await req.send();
                if (res.statusCode == 200) {
                  final respStr = await res.stream.bytesToString();
                  final data = jsonDecode(respStr);
                  imageUrl = data['imageUrl'];
                }
              }
              final response = await http.post(
                Uri.parse(ApiConfig.wordsUrl),
                headers: {
                  'Content-Type': 'application/json',
                  if (token != null) 'Authorization': 'Bearer $token',
                },
                body: jsonEncode({
                  'english_word': englishController.text.trim(),
                  'turkish_word': turkishController.text.trim(),
                  'difficulty_level': level,
                  'category': selectedCategory,
                  'picture': imageUrl,
                  'word_type': selectedWordType,
                }),
              );
              setState(() => isLoading = false);
              if (response.statusCode == 201) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Kelime eklendi!'), backgroundColor: Colors.green),
                );
                setState(() {}); // Listeyi güncellemek için
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Kelime eklenemedi: ${response.body}'), backgroundColor: Colors.red),
                );
              }
            }

            return AlertDialog(
              title: const Text('Yeni Kelime Ekle'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: englishController,
                      decoration: const InputDecoration(labelText: 'İngilizce'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: turkishController,
                      decoration: const InputDecoration(labelText: 'Türkçe'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Seviye: '),
                        DropdownButton<int>(
                          value: level,
                          items: List.generate(5, (i) => DropdownMenuItem(value: i+1, child: Text('${i+1}'))),
                          onChanged: (v) => setState(() => level = v ?? 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Kategori: '),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedCategory,
                            hint: const Text('Kategori seç'),
                            isExpanded: true,
                            items: categories.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            )).toList(),
                            onChanged: (v) => setState(() => selectedCategory = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Kelime Türü: '),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: selectedWordType,
                            hint: const Text('Kelime türü seç'),
                            isExpanded: true,
                            items: wordTypes.map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            )).toList(),
                            onChanged: (v) => setState(() => selectedWordType = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Resim Seç'),
                        ),
                        const SizedBox(width: 8),
                        if (selectedImage != null)
                          const Text('Seçildi', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : addWord,
                  child: isLoading ? const CircularProgressIndicator() : const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReviewSection() {
    return Consumer<WordProvider>(
      builder: (context, wordProvider, child) {
        final reviewWords = wordProvider.getReviewWords();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Tekrar Edilecekler (${reviewWords.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (reviewWords.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Tekrar edilecek kelime yok.'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reviewWords.length,
                itemBuilder: (context, index) {
                  final word = reviewWords[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      title: Text(word.englishWord),
                      subtitle: Text(word.turkishWord),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Üst üste doğru sayısını göster
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: word.consecutiveCorrectAnswers > 0 
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${word.consecutiveCorrectAnswers}/6',
                              style: TextStyle(
                                color: word.consecutiveCorrectAnswers > 0 
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sonraki tekrar tarihini göster
                          Text(
                            word.nextReview != null
                                ? _formatDate(word.nextReview!)
                                : 'Yakında',
                            style: TextStyle(
                              color: word.nextReview != null && 
                                     word.nextReview!.isBefore(DateTime.now())
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return 'Gecikmiş';
    } else if (difference == 0) {
      return 'Bugün';
    } else if (difference == 1) {
      return 'Yarın';
    } else {
      return '$difference gün sonra';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _flutterTts.stop();
    super.dispose();
  }
} 
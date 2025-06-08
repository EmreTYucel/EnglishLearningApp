import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/word_provider.dart';
import '../words/word_list_screen.dart';
import 'package:english_learning_app/screens/quiz/quiz_screen.dart';
import 'package:english_learning_app/screens/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ana ekran başlatıldığında kelimeleri yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WordProvider>(context, listen: false).loadWords(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          WordListScreen(),
          _QuizTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Kelimeler',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst başlık
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Row(
                    children: [
                      // Kullanıcı avatarı
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          authProvider.user?['username']?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Kullanıcı bilgileri
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Merhaba, ${authProvider.user?['username'] ?? 'Kullanıcı'}!',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Bugün hangi kelimeleri öğrenelim?',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bildirim butonu
                      IconButton(
                        onPressed: () {
                          // TODO: Implement notifications
                        },
                        icon: const Icon(Icons.notifications_outlined),
                      ),
                    ],
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // İlerleme kartı
              Consumer<WordProvider>(
                builder: (context, wordProvider, child) {
                  final learnedWords = wordProvider.getLearnedWords();
                  final learningWords = wordProvider.getLearningWords();
                  final newWords = wordProvider.getNewWords();
                  final totalWords = wordProvider.words.length;
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kart başlığı
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Öğrenme İlerlemen',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // İlerleme öğeleri
                          Row(
                            children: [
                              Expanded(
                                child: _ProgressItem(
                                  title: 'Öğrenilen',
                                  count: learnedWords.length,
                                  color: Colors.green,
                                  icon: Icons.check_circle,
                                ),
                              ),
                              Expanded(
                                child: _ProgressItem(
                                  title: 'Öğreniliyor',
                                  count: learningWords.length,
                                  color: Colors.orange,
                                  icon: Icons.schedule,
                                ),
                              ),
                              Expanded(
                                child: _ProgressItem(
                                  title: 'Yeni',
                                  count: newWords.length,
                                  color: Colors.blue,
                                  icon: Icons.fiber_new,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // İlerleme çubuğu
                          LinearProgressIndicator(
                            value: totalWords > 0 ? learnedWords.length / totalWords : 0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${learnedWords.length}/$totalWords kelime tamamlandı',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              // Quick Actions
              Text(
                'Hızlı Erişim',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
                children: [
                  _ActionCard(
                    title: 'Kelime Listesi',
                    subtitle: 'Tüm kelimeleri görüntüle',
                    icon: Icons.list_alt,
                    color: Colors.blue,
                    onTap: () => context.go('/words'),
                  ),
                  _ActionCard(
                    title: 'Quiz Çöz',
                    subtitle: 'Bilgini test et',
                    icon: Icons.quiz,
                    color: Colors.green,
                    onTap: () => context.go('/quiz'),
                  ),
                  _ActionCard(
                    title: 'Wordle Oyunu',
                    subtitle: 'Kelimeleri tahmin et',
                    icon: Icons.games,
                    color: Colors.purple,
                    onTap: () => context.go('/wordle'),
                  ),
                  _ActionCard(
                    title: 'İstatistikler',
                    subtitle: 'İlerleme raporun',
                    icon: Icons.analytics,
                    color: Colors.orange,
                    onTap: () => context.go('/statistics'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Tekrar Zamanı Gelen Kelimeler
              Consumer<WordProvider>(
                builder: (context, wordProvider, child) {
                  final dueWords = wordProvider.getDueWords();
                  final todaysWords = wordProvider.getTodaysReviewWords();
                  
                  if (dueWords.isEmpty && todaysWords.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tekrar Zamanı',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (dueWords.isNotEmpty) ...[
                        Text(
                          'Gecikmiş Tekrarlar',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: dueWords.length,
                            itemBuilder: (context, index) {
                              final word = dueWords[index];
                              return _buildWordCard(context, word, true);
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      if (todaysWords.isNotEmpty) ...[
                        Text(
                          'Bugün Tekrar Edilecekler',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: todaysWords.length,
                            itemBuilder: (context, index) {
                              final word = todaysWords[index];
                              return _buildWordCard(context, word, false);
                            },
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWordCard(BuildContext context, Word word, bool isOverdue) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: isOverdue ? Colors.red[50] : Colors.orange[50],
        child: InkWell(
          onTap: () {
            context.go('/quiz?wordId=${word.id}');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.englishWord,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isOverdue ? Colors.red : Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  word.turkishWord,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${word.repetitionCount}/6',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isOverdue ? Colors.red : Colors.orange,
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

class _ProgressItem extends StatelessWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;

  const _ProgressItem({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.15),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: color,
                size: 32,
              ),
              const Spacer(),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizTab extends StatelessWidget {
  const _QuizTab();

  @override
  Widget build(BuildContext context) {
    // Quiz ekranını sekmede göster
    return const QuizScreen();
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    // Profil ekranını sekmede göster
    return const ProfileScreen();
  }
} 
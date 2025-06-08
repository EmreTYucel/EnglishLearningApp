import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:english_learning_app/providers/word_provider.dart';

class WordleScreen extends StatefulWidget {
  const WordleScreen({super.key});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _flipController;
  late Animation<double> _shakeAnimation;
  
  // Game state
  String _targetWord = '';
  List<List<String>> _guesses = [];
  List<List<LetterState>> _guessStates = [];
  int _currentRow = 0;
  String _currentGuess = '';
  GameState _gameState = GameState.playing;
  final Map<String, LetterState> _keyboardStates = {};
  final int _maxGuessCount = 6;

  final List<String> _keyboardRows = [
    'QWERTYUIOP',
    'ASDFGHJKL',
    'ZXCVBNM',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    Future.microtask(() {
      final learnedWords = Provider.of<WordProvider>(context, listen: false)
          .getLearnedWords()
          .map((w) => w.englishWord.toUpperCase())
          .toList();
      _startNewGame(learnedWords);
    });
  }

  void _initializeAnimations() {
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  void _startNewGame([List<String>? availableWords]) {
    setState(() {
      final words = availableWords ??
          Provider.of<WordProvider>(context, listen: false)
              .getLearnedWords()
              .map((w) => w.englishWord.toUpperCase())
              .toList();
      if (words.isNotEmpty) {
        words.shuffle();
        _targetWord = words.first;
      } else {
        _targetWord = '';
      }
      _guesses = List.generate(_maxGuessCount, (_) => List.filled(_targetWord.length, ''));
      _guessStates = List.generate(_maxGuessCount, (_) => List.filled(_targetWord.length, LetterState.empty));
      _currentRow = 0;
      _currentGuess = '';
      _gameState = GameState.playing;
      _keyboardStates.clear();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wordle'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            tooltip: 'Ana Ekrana Dön',
            onPressed: () => context.go('/home'),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _showNewGameDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildGameInfo(),
          Expanded(
            flex: 4,
            child: _buildGameGrid(),
          ),
          SizedBox(
            height: 160, // Fixed height for keyboard
            child: _buildKeyboard(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildInfoCard('Tahmin', '$_currentRow/$_maxGuessCount'),
          _buildInfoCard('Kalan', '${_maxGuessCount - _currentRow}'),
          _buildInfoCard('Durum', _getGameStatusText()),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameGrid() {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(_maxGuessCount, (rowIndex) {
                return Expanded(
                  child: Row(
                    children: List.generate(_targetWord.length, (colIndex) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          child: _buildLetterTile(rowIndex, colIndex),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLetterTile(int row, int col) {
    final letter = _guesses[row][col];
    final state = _guessStates[row][col];
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300 + (col * 100)),
      decoration: BoxDecoration(
        color: _getTileColor(state),
        border: Border.all(
          color: _getTileBorderColor(state, letter),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: state == LetterState.empty ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          ..._keyboardRows.asMap().entries.map((entry) {
            final rowIndex = entry.key;
            final row = entry.value;
            
            return Container(
              height: 45, // Fixed height for each row
              margin: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (rowIndex == 2) _buildSpecialKey('⌫', _deleteLetter),
                  ...row.split('').map((letter) {
                    return Container(
                      width: rowIndex == 0 ? 32 : rowIndex == 1 ? 35 : 38, // Different widths for each row
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      child: _buildKeyboardKey(letter),
                    );
                  }),
                  if (rowIndex == 2) _buildSpecialKey('ENTER', _submitGuess),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildKeyboardKey(String letter) {
    final state = _keyboardStates[letter] ?? LetterState.empty;
    
    return InkWell(
      onTap: () => _addLetter(letter),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: _getKeyColor(state),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            letter,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: state == LetterState.empty ? Colors.black : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: text == 'ENTER' ? 55 : 35,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  void _addLetter(String letter) {
    if (_gameState != GameState.playing || _currentGuess.length >= _targetWord.length) return;
    setState(() {
      _currentGuess += letter;
      _guesses[_currentRow][_currentGuess.length - 1] = letter;
    });
    HapticFeedback.lightImpact();
  }

  void _deleteLetter() {
    if (_gameState != GameState.playing || _currentGuess.isEmpty) return;
    setState(() {
      _guesses[_currentRow][_currentGuess.length - 1] = '';
      _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
    });
    HapticFeedback.lightImpact();
  }

  void _submitGuess() {
    if (_gameState != GameState.playing || _currentGuess.length != _targetWord.length) {
      _shakeController.forward().then((_) => _shakeController.reverse());
      HapticFeedback.heavyImpact();
      return;
    }
    // Artık sadece harf kontrolü yapılacak, kelime havuzunda olma şartı yok
    _evaluateGuess();
    _flipController.forward().then((_) => _flipController.reverse());
    if (_currentGuess == _targetWord) {
      setState(() {
        _gameState = GameState.won;
      });
      _showWinDialog();
    } else if (_currentRow >= _maxGuessCount - 1) {
      setState(() {
        _gameState = GameState.lost;
      });
      _showLoseDialog();
    } else {
      setState(() {
        _currentRow++;
        _currentGuess = '';
      });
    }
    HapticFeedback.mediumImpact();
  }

  void _evaluateGuess() {
    final targetLetters = _targetWord.split('');
    final guessLetters = _currentGuess.split('');
    final newStates = List<LetterState>.filled(_targetWord.length, LetterState.absent);
    // First pass: mark correct positions
    for (int i = 0; i < _targetWord.length; i++) {
      if (guessLetters[i] == targetLetters[i]) {
        newStates[i] = LetterState.correct;
        targetLetters[i] = '*'; // Mark as used
      }
    }
    // Second pass: mark present letters
    for (int i = 0; i < _targetWord.length; i++) {
      if (newStates[i] == LetterState.absent) {
        final letterIndex = targetLetters.indexOf(guessLetters[i]);
        if (letterIndex != -1) {
          newStates[i] = LetterState.present;
          targetLetters[letterIndex] = '*'; // Mark as used
        }
      }
    }
    setState(() {
      _guessStates[_currentRow] = newStates;
      // Update keyboard states
      for (int i = 0; i < _targetWord.length; i++) {
        final letter = guessLetters[i];
        final currentState = _keyboardStates[letter] ?? LetterState.empty;
        // Only update if new state is better
        if (newStates[i] == LetterState.correct ||
            (newStates[i] == LetterState.present && currentState != LetterState.correct) ||
            (newStates[i] == LetterState.absent && currentState == LetterState.empty)) {
          _keyboardStates[letter] = newStates[i];
        }
      }
    });
  }

  Color _getTileColor(LetterState state) {
    switch (state) {
      case LetterState.empty:
        return Colors.white;
      case LetterState.correct:
        return Colors.green;
      case LetterState.present:
        return Colors.orange;
      case LetterState.absent:
        return Colors.grey;
    }
  }

  Color _getTileBorderColor(LetterState state, String letter) {
    if (letter.isEmpty) return Colors.grey[300]!;
    if (state == LetterState.empty) return Colors.grey[400]!;
    return _getTileColor(state);
  }

  Color _getKeyColor(LetterState state) {
    switch (state) {
      case LetterState.empty:
        return Colors.grey[200]!;
      case LetterState.correct:
        return Colors.green;
      case LetterState.present:
        return Colors.orange;
      case LetterState.absent:
        return Colors.grey[600]!;
    }
  }

  String _getGameStatusText() {
    switch (_gameState) {
      case GameState.playing:
        return 'Oynuyor';
      case GameState.won:
        return 'Kazandı!';
      case GameState.lost:
        return 'Kaybetti';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Tebrikler!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kelimeyi ${_currentRow + 1} tahminde buldunuz!'),
            const SizedBox(height: 16),
            Text(
              'Kelime: $_targetWord',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('Yeni Oyun'),
          ),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Ana Sayfa'),
          ),
        ],
      ),
    );
  }

  void _showLoseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('😔 Oyun Bitti'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Maalesef kelimeyi bulamadınız.'),
            const SizedBox(height: 16),
            Text(
              'Kelime: $_targetWord',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('Tekrar Dene'),
          ),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Ana Sayfa'),
          ),
        ],
      ),
    );
  }

  void _showNewGameDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Oyun'),
        content: const Text('Mevcut oyunu bırakıp yeni oyun başlatmak istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNewGame();
            },
            child: const Text('Evet'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nasıl Oynanır?'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎯 Amaç: Gizli kelimeyi tahmin yaparak bulmak\n'),
              Text('🟩 Yeşil: Doğru harf, doğru konum'),
              Text('🟨 Sarı: Doğru harf, yanlış konum'),
              Text('⬜ Gri: Harf kelimede yok\n'),
              Text('• Her tahmin geçerli bir kelime olmalı'),
              Text('• Öğrendiğiniz kelimeler kullanılıyor'),
              Text('• Her gün yeni kelimeler ekleniyor'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }
}

enum LetterState {
  empty,
  correct,
  present,
  absent,
}

enum GameState {
  playing,
  won,
  lost,
} 
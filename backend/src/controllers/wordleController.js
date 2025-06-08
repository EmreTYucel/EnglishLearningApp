const { validationResult } = require('express-validator');
const { query, transaction } = require('../config/database');
const { createSHA256Hash } = require('../utils/jwtUtils');

// Kullanıcının öğrendiği kelimelerden 5 harfli Wordle kelimelerini getir
const getWordleWords = async (userId) => {
  try {
    const result = await query(`
      SELECT DISTINCT w.word_id, w.english_word
      FROM words w
      INNER JOIN user_word_progress uwp ON w.word_id = uwp.word_id
      WHERE uwp.user_id = $1 
        AND uwp.is_learned = true 
        AND LENGTH(w.english_word) = 5
        AND w.english_word ~ '^[A-Za-z]+$'
      ORDER BY RANDOM()
      LIMIT 50
    `, [userId]);

    return result.rows;
  } catch (error) {
    console.error('Error getting Wordle words:', error);
    throw error;
  }
};

// Yeni Wordle oyunu başlat
const startGame = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Kullanıcı için uygun kelimeleri getir
    const availableWords = await getWordleWords(userId);

    if (availableWords.length === 0) {
      return res.status(400).json({
        error: 'Insufficient Words',
        message: 'You need to learn at least some 5-letter words to play Wordle',
        suggestion: 'Complete more vocabulary lessons first'
      });
    }

    // Rastgele kelime seç
    const randomWord = availableWords[Math.floor(Math.random() * availableWords.length)];
    const targetWord = randomWord.english_word.toUpperCase();

    // Kullanıcının aktif oyunu var mı kontrol et
    const activeGameResult = await query(
      'SELECT game_id FROM wordle_games WHERE user_id = $1 AND is_completed = false',
      [userId]
    );

    if (activeGameResult.rows.length > 0) {
      return res.status(400).json({
        error: 'Active Game Exists',
        message: 'You already have an active Wordle game. Complete it first.',
        gameId: activeGameResult.rows[0].game_id
      });
    }

    // Yeni oyun oluştur
    const gameResult = await query(`
      INSERT INTO wordle_games (user_id, target_word, guesses, max_attempts)
      VALUES ($1, $2, $3, $4)
      RETURNING game_id, started_at, max_attempts
    `, [userId, targetWord, '{}', 6]);

    const game = gameResult.rows[0];

    res.status(201).json({
      success: true,
      message: 'New Wordle game started',
      game: {
        gameId: game.game_id,
        maxAttempts: game.max_attempts,
        attemptsUsed: 0,
        startedAt: game.started_at,
        wordLength: 5,
        status: 'active'
      }
    });

  } catch (error) {
    console.error('Start Wordle game error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to start Wordle game'
    });
  }
};

// Tahmin gönder
const submitGuess = async (req, res) => {
  try {
    // Girdi doğrulama hatalarını kontrol et
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'Please check your input',
        details: errors.array()
      });
    }

    const userId = req.user.userId;
    const { gameId, guess } = req.body;

    // Tahmin formatını doğrula
    const guessUpper = guess.toUpperCase();
    if (!/^[A-Z]{5}$/.test(guessUpper)) {
      return res.status(400).json({
        error: 'Invalid Guess',
        message: 'Guess must be exactly 5 letters'
      });
    }

    // Mevcut oyunu getir
    const gameResult = await query(`
      SELECT game_id, target_word, guesses, attempts_used, max_attempts, is_completed, is_won
      FROM wordle_games 
      WHERE game_id = $1 AND user_id = $2
    `, [gameId, userId]);

    if (gameResult.rows.length === 0) {
      return res.status(404).json({
        error: 'Game Not Found',
        message: 'Wordle game not found'
      });
    }

    const game = gameResult.rows[0];

    // Oyun durumunu kontrol et
    if (game.is_completed) {
      return res.status(400).json({
        error: 'Game Completed',
        message: 'This game is already completed',
        result: {
          won: game.is_won,
          targetWord: game.target_word
        }
      });
    }

    if (game.attempts_used >= game.max_attempts) {
      return res.status(400).json({
        error: 'Max Attempts Reached',
        message: 'You have used all your attempts'
      });
    }

    // Tahminin geçerli bir İngilizce kelime olup olmadığını kontrol et
    const wordValidation = await query(
      'SELECT word_id FROM words WHERE UPPER(english_word) = $1',
      [guessUpper]
    );

    if (wordValidation.rows.length === 0) {
      return res.status(400).json({
        error: 'Invalid Word',
        message: 'This is not a valid English word in our database'
      });
    }

    // Tahmini işle
    const targetWord = game.target_word;
    const guessResult = processGuess(guessUpper, targetWord);

    // Oyunu yeni tahminle güncelle
    const currentGuesses = game.guesses || [];
    const newGuesses = [...currentGuesses, {
      guess: guessUpper,
      result: guessResult,
      timestamp: new Date().toISOString()
    }];

    const newAttemptsUsed = game.attempts_used + 1;
    const isWon = guessUpper === targetWord;
    const isCompleted = isWon || newAttemptsUsed >= game.max_attempts;

    // Veritabanında oyunu güncelle
    const updateResult = await transaction(async (client) => {
      // Oyunu güncelle
      await client.query(`
        UPDATE wordle_games 
        SET guesses = $1, attempts_used = $2, is_completed = $3, is_won = $4,
            completed_at = CASE WHEN $3 THEN CURRENT_TIMESTAMP ELSE completed_at END
        WHERE game_id = $5
      `, [JSON.stringify(newGuesses), newAttemptsUsed, isCompleted, isWon, gameId]);

      // Oyun tamamlandıysa kullanıcı istatistiklerini güncelle
      if (isCompleted) {
        await client.query(`
          UPDATE user_statistics 
          SET total_study_time_minutes = total_study_time_minutes + 5,
              last_activity = CURRENT_TIMESTAMP
          WHERE user_id = $1
        `, [userId]);

        // Kazanıldıysa seriyi güncelle
        if (isWon) {
          await client.query(`
            UPDATE users 
            SET streak_count = streak_count + 1
            WHERE user_id = $1
          `, [userId]);
        }
      }

      return { isCompleted, isWon };
    });

    // Yanıtı hazırla
    const response = {
      success: true,
      guess: {
        word: guessUpper,
        result: guessResult,
        correct: isWon
      },
      game: {
        gameId: game.game_id,
        attemptsUsed: newAttemptsUsed,
        maxAttempts: game.max_attempts,
        isCompleted,
        isWon
      }
    };

    // Oyun tamamlandıysa hedef kelimeyi ekle
    if (isCompleted) {
      response.game.targetWord = targetWord;
      response.message = isWon 
        ? `Congratulations! You guessed the word in ${newAttemptsUsed} attempts!`
        : `Game over! The word was "${targetWord}". Better luck next time!`;
    }

    res.json(response);

  } catch (error) {
    console.error('Submit Wordle guess error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to submit guess'
    });
  }
};

// Tahmini işle ve renk kodlu sonucu döndür
const processGuess = (guess, target) => {
  const result = new Array(5).fill('gray');  // Varsayılan olarak tüm harfler gri
  const targetLetters = target.split('');    // Hedef kelimeyi harflere ayır
  const guessLetters = guess.split('');      // Tahmini harflere ayır
  const usedIndices = new Set();             // Kullanılmış indeksleri takip et

  // Önce doğru pozisyondaki harfleri işaretle (yeşil)
  for (let i = 0; i < 5; i++) {
    if (guessLetters[i] === targetLetters[i]) {
      result[i] = 'green';
      usedIndices.add(i);
    }
  }

  // Sonra yanlış pozisyondaki harfleri işaretle (sarı)
  for (let i = 0; i < 5; i++) {
    if (result[i] === 'green') continue;  // Zaten yeşil olanları atla

    for (let j = 0; j < 5; j++) {
      if (!usedIndices.has(j) && guessLetters[i] === targetLetters[j]) {
        result[i] = 'yellow';
        usedIndices.add(j);
        break;
      }
    }
  }

  return result;
};

// Oyun durumunu getir
const getGameStatus = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { gameId } = req.params;

    const result = await query(`
      SELECT game_id, target_word, guesses, attempts_used, max_attempts, 
             is_completed, is_won, started_at, completed_at
      FROM wordle_games 
      WHERE game_id = $1 AND user_id = $2
    `, [gameId, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Game Not Found',
        message: 'Wordle game not found'
      });
    }

    const game = result.rows[0];
    const response = {
      gameId: game.game_id,
      attemptsUsed: game.attempts_used,
      maxAttempts: game.max_attempts,
      isCompleted: game.is_completed,
      isWon: game.is_won,
      startedAt: game.started_at,
      completedAt: game.completed_at,
      guesses: game.guesses || []
    };

    // Oyun tamamlandıysa hedef kelimeyi ekle
    if (game.is_completed) {
      response.targetWord = game.target_word;
    }

    res.json(response);

  } catch (error) {
    console.error('Get Wordle game status error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get game status'
    });
  }
};

// Kullanıcının Wordle istatistiklerini getir
const getWordleStats = async (req, res) => {
  try {
    const userId = req.user.userId;

    const result = await query(`
      SELECT 
        COUNT(*) as total_games,
        SUM(CASE WHEN is_won THEN 1 ELSE 0 END) as games_won,
        AVG(CASE WHEN is_won THEN attempts_used ELSE NULL END) as avg_attempts_won,
        MAX(streak_count) as current_streak,
        MAX(CASE WHEN is_won THEN streak_count ELSE 0 END) as best_streak
      FROM wordle_games wg
      LEFT JOIN users u ON wg.user_id = u.user_id
      WHERE wg.user_id = $1
    `, [userId]);

    const stats = result.rows[0];

    res.json({
      totalGames: parseInt(stats.total_games) || 0,
      gamesWon: parseInt(stats.games_won) || 0,
      winRate: stats.total_games ? (stats.games_won / stats.total_games * 100).toFixed(1) : 0,
      avgAttemptsWon: parseFloat(stats.avg_attempts_won) || 0,
      currentStreak: parseInt(stats.current_streak) || 0,
      bestStreak: parseInt(stats.best_streak) || 0
    });

  } catch (error) {
    console.error('Get Wordle stats error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get Wordle statistics'
    });
  }
};

// Oyun geçmişini getir
const getGameHistory = async (req, res) => {
  try {
    const userId = req.user.userId;
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    const result = await query(`
      SELECT game_id, target_word, attempts_used, is_won, started_at, completed_at
      FROM wordle_games 
      WHERE user_id = $1
      ORDER BY started_at DESC
      LIMIT $2 OFFSET $3
    `, [userId, limit, offset]);

    const totalResult = await query(
      'SELECT COUNT(*) FROM wordle_games WHERE user_id = $1',
      [userId]
    );

    const totalGames = parseInt(totalResult.rows[0].count);
    const totalPages = Math.ceil(totalGames / limit);

    res.json({
      games: result.rows.map(game => ({
        gameId: game.game_id,
        targetWord: game.target_word,
        attemptsUsed: game.attempts_used,
        isWon: game.is_won,
        startedAt: game.started_at,
        completedAt: game.completed_at
      })),
      pagination: {
        currentPage: page,
        totalPages,
        totalGames,
        hasMore: page < totalPages
      }
    });

  } catch (error) {
    console.error('Get Wordle history error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get game history'
    });
  }
};

// Oyunu terk et
const abandonGame = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { gameId } = req.params;

    const result = await query(`
      UPDATE wordle_games 
      SET is_completed = true, is_won = false, completed_at = CURRENT_TIMESTAMP
      WHERE game_id = $1 AND user_id = $2 AND is_completed = false
      RETURNING game_id, target_word
    `, [gameId, userId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Game Not Found',
        message: 'Active Wordle game not found'
      });
    }

    res.json({
      success: true,
      message: 'Game abandoned',
      targetWord: result.rows[0].target_word
    });

  } catch (error) {
    console.error('Abandon Wordle game error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to abandon game'
    });
  }
};

module.exports = {
  startGame,
  submitGuess,
  getGameStatus,
  getWordleStats,
  getGameHistory,
  abandonGame
}; 
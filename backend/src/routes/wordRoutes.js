const express = require('express');
const { authenticateToken, optionalAuth } = require('../middleware/auth');
const multer = require('multer');
const path = require('path');
console.log('DATABASE PATH:', path.resolve(__dirname, '../config/database'));
const { query } = require('../config/database');
console.log('QUERY FUNCTION:', query);

const router = express.Router();

const storage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, 'uploads/'),
  filename: (req, file, cb) => cb(null, Date.now() + path.extname(file.originalname))
});
const upload = multer({ storage });

// Tüm kelimeleri getir (giriş yapmış kullanıcılar için ilerleme bilgisiyle birlikte)
router.get('/', optionalAuth, async (req, res) => {
  try {
    const userId = req.user ? req.user.userId : null;
    let result;
    if (userId) {
      // Giriş yapmış kullanıcı için kelimeleri ve ilerleme bilgilerini getir
      result = await query(`
        SELECT w.word_id, w.english_word, w.turkish_word, w.picture, w.category, w.difficulty_level,
               uwp.repetition_count, uwp.last_reviewed, uwp.next_review, uwp.is_learned
        FROM words w
        LEFT JOIN user_word_progress uwp ON w.word_id = uwp.word_id AND uwp.user_id = $1
        ORDER BY w.word_id DESC
      `, [userId]);
    } else {
      // Giriş yapmamış kullanıcı için sadece kelimeleri getir
      result = await query('SELECT * FROM words ORDER BY word_id DESC');
    }
    const words = result.rows.map(row => ({
      id: row.word_id,
      englishWord: row.english_word,
      turkishWord: row.turkish_word,
      picture: row.picture,
      category: row.category,
      difficultyLevel: row.difficulty_level || 1,
      repetitionCount: row.repetition_count || 0,
      lastReviewed: row.last_reviewed,
      nextReview: row.next_review,
      isLearned: row.is_learned || false,
    }));
    res.json(words);
  } catch (error) {
    console.error('Get words error:', error);
    res.status(500).json({ error: 'Internal Server Error', message: 'Failed to fetch words.' });
  }
});

// Günlük kelimeleri getir (yakında eklenecek)
router.get('/daily', authenticateToken, (req, res) => {
  res.json({
    success: true,
    message: 'Daily words endpoint - Coming soon'
  });
});

// Kelime ilerleme durumunu güncelle
router.post('/:wordId/progress', authenticateToken, async (req, res) => {
  try {
    const { wordId } = req.params;
    const userId = req.user.userId;
    const { repetitionCount, nextReview, isLearned } = req.body;

    // Mevcut ilerlemeyi kontrol et
    const progressResult = await query(
      'SELECT * FROM user_word_progress WHERE user_id = $1 AND word_id = $2',
      [userId, wordId]
    );

    if (progressResult.rows.length === 0) {
      // Yeni ilerleme kaydı oluştur
      await query(
        `INSERT INTO user_word_progress 
        (user_id, word_id, repetition_count, last_reviewed, next_review, is_learned) 
        VALUES ($1, $2, $3, CURRENT_TIMESTAMP, $4, $5)`,
        [userId, wordId, repetitionCount, nextReview, isLearned]
      );
    } else {
      // Mevcut ilerlemeyi güncelle
      await query(
        `UPDATE user_word_progress 
        SET repetition_count = $1, 
            last_reviewed = CURRENT_TIMESTAMP, 
            next_review = $2, 
            is_learned = $3,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = $4 AND word_id = $5`,
        [repetitionCount, nextReview, isLearned, userId, wordId]
      );
    }

    // Güncel veriyi döndür
    const updatedResult = await query(
      `SELECT w.*, uwp.repetition_count, uwp.last_reviewed, uwp.next_review, uwp.is_learned
       FROM words w
       LEFT JOIN user_word_progress uwp ON w.word_id = uwp.word_id AND uwp.user_id = $1
       WHERE w.word_id = $2`,
      [userId, wordId]
    );

    if (updatedResult.rows.length === 0) {
      return res.status(404).json({ error: 'Kelime bulunamadı' });
    }

    const word = updatedResult.rows[0];
    res.json({
      id: word.word_id,
      englishWord: word.english_word,
      turkishWord: word.turkish_word,
      picture: word.picture,
      repetitionCount: word.repetition_count || 0,
      lastReviewed: word.last_reviewed,
      nextReview: word.next_review,
      isLearned: word.is_learned || false,
      difficultyLevel: word.difficulty_level || 1,
    });
  } catch (error) {
    console.error('Kelime ilerleme güncelleme hatası:', error);
    res.status(500).json({ error: 'Sunucu hatası', message: 'İlerleme güncellenemedi.' });
  }
});

// Yeni kelime ekle (giriş yapmış kullanıcılar için)
router.post('/', authenticateToken, async (req, res) => {
  try {
    const { english_word, turkish_word, category, difficulty_level, picture } = req.body;
    if (!english_word || !turkish_word) {
      return res.status(400).json({
        error: 'Validation Error',
        message: 'English and Turkish word are required.'
      });
    }
    const result = await query(
      'INSERT INTO words (english_word, turkish_word, category, difficulty_level, picture) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [english_word, turkish_word, category || null, difficulty_level || 1, picture || null]
    );
    res.status(201).json({
      success: true,
      word: result.rows[0]
    });
  } catch (error) {
    if (error.code === '23505') {
      return res.status(409).json({
        error: 'Duplicate',
        message: 'This word already exists.'
      });
    }
    console.error('Add word error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to add word.'
    });
  }
});

// Kelime resmi yükleme endpointi
router.post('/upload', authenticateToken, upload.single('image'), (req, res) => {
  if (!req.file) {
    return res.status(400).json({ error: 'No file uploaded' });
  }
  res.json({ success: true, imageUrl: `/uploads/${req.file.filename}` });
});

// Quiz soruları oluştur ve getir
router.get('/quiz', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const questionCount = parseInt(req.query.count) || 10;
    const exclude = req.query.exclude ? req.query.exclude.split(',').map(Number).filter(Boolean) : [];

    // Hariç tutulacak kelimeler için SQL koşulu
    let excludeCondition = '';
    let params = [userId, questionCount];
    if (exclude.length > 0) {
      excludeCondition = `AND w.word_id NOT IN (${exclude.map((_, i) => `$${i + 3}`).join(',')})`;
      params = [userId, questionCount, ...exclude];
    }

    // Rastgele kelimeleri seç
    const queryStr =
      `SELECT w.word_id, w.english_word, w.turkish_word, uwp.repetition_count, uwp.is_learned
       FROM words w
       LEFT JOIN user_word_progress uwp ON w.word_id = uwp.word_id AND uwp.user_id = $1
       WHERE 1=1 ${excludeCondition}
       ORDER BY RANDOM()
       LIMIT $2`;

    const result = await query(queryStr, params);

    if (result.rows.length === 0) {
      return res.json({ message: 'No more words to review' });
    }

    // Her kelime için 3 yanlış seçenek oluştur
    const questions = [];
    for (const word of result.rows) {
      const optionsResult = await query(
        `SELECT english_word FROM words WHERE word_id != $1 ORDER BY RANDOM() LIMIT 3`,
        [word.word_id]
      );
      const options = [word.english_word, ...optionsResult.rows.map(r => r.english_word)];
      // Seçenekleri karıştır
      for (let i = options.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [options[i], options[j]] = [options[j], options[i]];
      }
      questions.push({
        word: {
          id: word.word_id,
          english_word: word.english_word,
          turkish_word: word.turkish_word,
          repetitionCount: word.repetition_count || 0,
          isLearned: word.is_learned || false
        },
        options
      });
    }

    res.json({ questions });
  } catch (error) {
    console.error('Quiz endpoint error:', error);
    res.status(500).json({ error: 'Internal Server Error', message: 'Failed to load quiz questions.' });
  }
});

module.exports = router; 
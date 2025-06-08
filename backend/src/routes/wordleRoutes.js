const express = require('express');
const { body, param, query } = require('express-validator');
const { authenticateToken } = require('../middleware/auth');
const {
  startGame,
  submitGuess,
  getGameStatus,
  getWordleStats,
  getGameHistory,
  abandonGame
} = require('../controllers/wordleController');

const router = express.Router();

// Tahmin gönderme için doğrulama kuralları
const submitGuessValidation = [
  body('gameId')
    .isInt({ min: 1 })
    .withMessage('Game ID must be a positive integer'),
  
  body('guess')
    .isLength({ min: 5, max: 5 })
    .withMessage('Guess must be exactly 5 characters')
    .matches(/^[A-Za-z]+$/)
    .withMessage('Guess must contain only letters')
];

// Oyun ID'si için doğrulama kuralları
const gameIdValidation = [
  param('gameId')
    .isInt({ min: 1 })
    .withMessage('Game ID must be a positive integer')
];

// Sayfalama için doğrulama kuralları
const paginationValidation = [
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  
  query('limit')
    .optional()
    .isInt({ min: 1, max: 50 })
    .withMessage('Limit must be between 1 and 50')
];

// Tüm rotalar için kimlik doğrulama gerekli
router.use(authenticateToken);

// Oyun yönetimi rotaları
router.post('/start', startGame);  // Yeni oyun başlat
router.post('/guess', submitGuessValidation, submitGuess);  // Tahmin gönder
router.get('/game/:gameId', gameIdValidation, getGameStatus);  // Oyun durumunu getir
router.delete('/game/:gameId', gameIdValidation, abandonGame);  // Oyunu terk et

// İstatistik ve geçmiş rotaları
router.get('/stats', getWordleStats);  // Kullanıcı istatistiklerini getir
router.get('/history', paginationValidation, getGameHistory);  // Oyun geçmişini getir

// Bilgi rotası
router.get('/', (req, res) => {
  res.json({
    success: true,
    message: 'Wordle Game API',
    description: '5-letter word guessing game using learned vocabulary',
    endpoints: {
      'POST /start': 'Start new Wordle game',
      'POST /guess': 'Submit a guess',
      'GET /game/:gameId': 'Get game status',
      'DELETE /game/:gameId': 'Abandon current game',
      'GET /stats': 'Get user statistics',
      'GET /history': 'Get game history'
    },
    rules: {
      wordLength: 5,
      maxAttempts: 6,
      wordSource: 'Learned vocabulary words only',
      colors: {
        green: 'Correct letter in correct position',
        yellow: 'Correct letter in wrong position',
        gray: 'Letter not in word'
      }
    }
  });
});

module.exports = router; 
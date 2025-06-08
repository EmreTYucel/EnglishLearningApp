const express = require('express');
const { body } = require('express-validator');
const { 
  register, 
  login, 
  getProfile, 
  updateProfile, 
  changePassword, 
  logout 
} = require('../controllers/authController');
const { authenticateToken, refreshToken } = require('../middleware/auth');
const bcrypt = require('bcrypt');
const { query } = require('pg');

const router = express.Router();

// Kayıt olma doğrulama kuralları
const registerValidation = [
  body('username')
    .isLength({ min: 3, max: 50 })
    .withMessage('Username must be between 3 and 50 characters')
    .matches(/^[a-zA-Z0-9_]+$/)
    .withMessage('Username can only contain letters, numbers, and underscores'),
  
  body('email')
    .isEmail()
    .withMessage('Please provide a valid email address')
    .normalizeEmail(),
  
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('Password must contain at least one lowercase letter, one uppercase letter, and one number')
];

// Giriş yapma doğrulama kuralları
const loginValidation = [
  body('username')
    .notEmpty()
    .withMessage('Username or email is required'),
  
  body('password')
    .notEmpty()
    .withMessage('Password is required')
];

// Profil güncelleme doğrulama kuralları
const updateProfileValidation = [
  body('dailyWordLimit')
    .optional()
    .isInt({ min: 1, max: 50 })
    .withMessage('Daily word limit must be between 1 and 50')
];

// Şifre değiştirme doğrulama kuralları
const changePasswordValidation = [
  body('currentPassword')
    .notEmpty()
    .withMessage('Current password is required'),
  
  body('newPassword')
    .isLength({ min: 8 })
    .withMessage('New password must be at least 8 characters long')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
    .withMessage('New password must contain at least one lowercase letter, one uppercase letter, and one number')
];

// Herkese açık rotalar
router.post('/register', registerValidation, register);  // Yeni kullanıcı kaydı
router.post('/login', loginValidation, login);          // Kullanıcı girişi

// Korumalı rotalar (kimlik doğrulama gerektiren)
router.get('/profile', authenticateToken, getProfile);                    // Profil bilgilerini getir
router.put('/profile', authenticateToken, updateProfileValidation, updateProfile);  // Profili güncelle
router.put('/change-password', authenticateToken, changePasswordValidation, changePassword);  // Şifre değiştir
router.post('/logout', authenticateToken, logout);                        // Çıkış yap
router.post('/refresh-token', refreshToken);                              // Token yenile

// Kimlik doğrulama test rotası
router.get('/test', authenticateToken, (req, res) => {
  res.json({
    success: true,
    message: 'Authentication is working',
    user: req.user
  });
});

// Şifre değiştirme rotası
router.post('/change-password', authenticateToken, async (req, res) => {
  try {
    const userId = req.user.userId;
    const { currentPassword, newPassword } = req.body;
    
    // Gerekli alanların kontrolü
    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: 'Mevcut ve yeni şifre gereklidir.' });
    }

    // Kullanıcının mevcut şifresini kontrol et
    const userResult = await query('SELECT password FROM users WHERE user_id = $1', [userId]);
    if (userResult.rows.length === 0) {
      return res.status(404).json({ message: 'Kullanıcı bulunamadı.' });
    }

    const user = userResult.rows[0];
    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      return res.status(401).json({ message: 'Mevcut şifre yanlış.' });
    }

    // Yeni şifreyi hashle ve güncelle
    const hashed = await bcrypt.hash(newPassword, 10);
    await query('UPDATE users SET password = $1 WHERE user_id = $2', [hashed, userId]);
    res.json({ message: 'Şifre başarıyla güncellendi.' });
  } catch (error) {
    console.error('Şifre güncelleme hatası:', error);
    res.status(500).json({ message: 'Şifre güncellenemedi.' });
  }
});

module.exports = router; 
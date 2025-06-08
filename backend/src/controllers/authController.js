const bcrypt = require('bcryptjs');
const { validationResult } = require('express-validator');
const { query, transaction } = require('../config/database');
const { generateToken } = require('../middleware/auth');

// Yeni kullanıcı kaydı
const register = async (req, res) => {
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

    const { username, email, password } = req.body;

    // Kullanıcının zaten var olup olmadığını kontrol et
    const existingUser = await query(
      'SELECT user_id FROM users WHERE username = $1 OR email = $2',
      [username, email]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        error: 'User Already Exists',
        message: 'Username or email is already taken'
      });
    }

    // Şifreyi hashle
    const saltRounds = 12;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Kullanıcıyı oluştur ve istatistikleri başlat
    const result = await transaction(async (client) => {
      // Kullanıcıyı veritabanına ekle
      const userResult = await client.query(
        `INSERT INTO users (username, email, password_hash) 
         VALUES ($1, $2, $3) 
         RETURNING user_id, username, email, created_at`,
        [username, email, passwordHash]
      );

      const newUser = userResult.rows[0];

      // Kullanıcı istatistiklerini başlat
      await client.query(
        `INSERT INTO user_statistics (user_id) VALUES ($1)`,
        [newUser.user_id]
      );

      return newUser;
    });

    // JWT token oluştur
    const token = generateToken(result.user_id, result.username);

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      user: {
        id: result.user_id,
        username: result.username,
        email: result.email,
        createdAt: result.created_at
      },
      token,
      expiresIn: process.env.JWT_EXPIRES_IN || '7d'
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to register user'
    });
  }
};

// Kullanıcı girişi
const login = async (req, res) => {
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

    const { username, password } = req.body;

    // Kullanıcıyı kullanıcı adı veya e-posta ile bul
    const userResult = await query(
      `SELECT user_id, username, email, password_hash, is_active, last_login 
       FROM users 
       WHERE (username = $1 OR email = $1) AND is_active = true`,
      [username]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        error: 'User Not Found',
        message: 'User not found'
      });
    }

    const user = userResult.rows[0];

    // Şifreyi doğrula
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    
    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Invalid Credentials',
        message: 'Username or password is incorrect'
      });
    }

    // Son giriş zamanını güncelle
    await query(
      'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = $1',
      [user.user_id]
    );

    // JWT token oluştur
    const token = generateToken(user.user_id, user.username);

    res.json({
      success: true,
      message: 'Login successful',
      user: {
        id: user.user_id,
        username: user.username,
        email: user.email,
        lastLogin: user.last_login
      },
      token,
      expiresIn: process.env.JWT_EXPIRES_IN || '7d'
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to login'
    });
  }
};

// Mevcut kullanıcı profilini getir
const getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;

    // Kullanıcı bilgilerini ve istatistiklerini getir
    const userResult = await query(
      `SELECT u.user_id, u.username, u.email, u.created_at, u.profile_picture, 
              u.daily_word_limit, u.streak_count, u.last_login,
              s.words_learned, s.words_in_progress, s.total_quiz_sessions,
              s.average_quiz_score, s.current_streak, s.longest_streak,
              s.total_study_time_minutes
       FROM users u
       LEFT JOIN user_statistics s ON u.user_id = s.user_id
       WHERE u.user_id = $1`,
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        error: 'User Not Found',
        message: 'User profile not found'
      });
    }

    const user = userResult.rows[0];

    res.json({
      success: true,
      user: {
        id: user.user_id,
        username: user.username,
        email: user.email,
        createdAt: user.created_at,
        profilePicture: user.profile_picture,
        dailyWordLimit: user.daily_word_limit,
        streakCount: user.streak_count,
        lastLogin: user.last_login,
        statistics: {
          wordsLearned: user.words_learned || 0,
          wordsInProgress: user.words_in_progress || 0,
          totalQuizSessions: user.total_quiz_sessions || 0,
          averageQuizScore: parseFloat(user.average_quiz_score) || 0,
          currentStreak: user.current_streak || 0,
          longestStreak: user.longest_streak || 0,
          totalStudyTimeMinutes: user.total_study_time_minutes || 0
        }
      }
    });

  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get user profile'
    });
  }
};

// Kullanıcı profilini güncelle
const updateProfile = async (req, res) => {
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
    const { dailyWordLimit } = req.body;

    // Kullanıcı ayarlarını güncelle
    const updateResult = await query(
      `UPDATE users 
       SET daily_word_limit = $1, updated_at = CURRENT_TIMESTAMP 
       WHERE user_id = $2 
       RETURNING user_id, username, email, daily_word_limit`,
      [dailyWordLimit, userId]
    );

    if (updateResult.rows.length === 0) {
      return res.status(404).json({
        error: 'User Not Found',
        message: 'User not found'
      });
    }

    const user = updateResult.rows[0];

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user: {
        id: user.user_id,
        username: user.username,
        email: user.email,
        dailyWordLimit: user.daily_word_limit
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update profile'
    });
  }
};

// Şifre değiştirme
const changePassword = async (req, res) => {
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
    const { currentPassword, newPassword } = req.body;

    // Mevcut şifreyi kontrol et
    const userResult = await query(
      'SELECT password_hash FROM users WHERE user_id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(404).json({
        error: 'User Not Found',
        message: 'User not found'
      });
    }

    const user = userResult.rows[0];
    const isPasswordValid = await bcrypt.compare(currentPassword, user.password_hash);

    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Invalid Password',
        message: 'Current password is incorrect'
      });
    }

    // Yeni şifreyi hashle ve güncelle
    const saltRounds = 12;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    await query(
      'UPDATE users SET password_hash = $1, updated_at = CURRENT_TIMESTAMP WHERE user_id = $2',
      [newPasswordHash, userId]
    );

    res.json({
      success: true,
      message: 'Password changed successfully'
    });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to change password'
    });
  }
};

// Çıkış yap
const logout = async (req, res) => {
  try {
    // Token'ı geçersiz kıl (eğer token blacklist kullanıyorsanız)
    // Bu örnekte basit bir başarı mesajı dönüyoruz
    res.json({
      success: true,
      message: 'Logged out successfully'
    });
  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to logout'
    });
  }
};

module.exports = {
  register,
  login,
  getProfile,
  updateProfile,
  changePassword,
  logout
}; 
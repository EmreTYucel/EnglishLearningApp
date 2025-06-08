const jwt = require('jsonwebtoken');
const { query } = require('../config/database');
const { 
  generateSecureToken, 
  verifySecureToken, 
  generateRefreshToken,
  createSHA256Hash 
} = require('../utils/jwtUtils');

// JWT token doğrulama middleware'i
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        error: 'Access Denied',
        message: 'No token provided'
      });
    }

    // Token'ı gelişmiş güvenlik ile doğrula
    const decoded = verifySecureToken(token);
    
    // Kullanıcının hala var olup olmadığını ve aktif olup olmadığını kontrol et
    const userResult = await query(
      'SELECT user_id, username, email, is_active FROM users WHERE user_id = $1',
      [decoded.userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({
        error: 'Invalid Token',
        message: 'User not found'
      });
    }

    const user = userResult.rows[0];
    
    if (!user.is_active) {
      return res.status(401).json({
        error: 'Account Disabled',
        message: 'Your account has been disabled'
      });
    }

    // Kullanıcı bilgilerini request nesnesine ekle
    req.user = {
      userId: user.user_id,
      username: user.username,
      email: user.email
    };

    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Invalid Token',
        message: 'Token is malformed'
      });
    }
    
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Token Expired',
        message: 'Please login again'
      });
    }

    console.error('Auth middleware error:', error);
    return res.status(500).json({
      error: 'Internal Server Error',
      message: 'Authentication failed'
    });
  }
};

// İsteğe bağlı kimlik doğrulama middleware'i (token yoksa hata vermez)
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      req.user = null;
      return next();
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    const userResult = await query(
      'SELECT user_id, username, email, is_active FROM users WHERE user_id = $1',
      [decoded.userId]
    );

    if (userResult.rows.length > 0 && userResult.rows[0].is_active) {
      const user = userResult.rows[0];
      req.user = {
        userId: user.user_id,
        username: user.username,
        email: user.email
      };
    } else {
      req.user = null;
    }

    next();
  } catch (error) {
    req.user = null;
    next();
  }
};

// Gelişmiş güvenlik ile JWT token oluştur
const generateToken = (userId, username) => {
  return generateSecureToken({ 
    userId, 
    username 
  });
};

// Token yenileme (süre uzatma)
const refreshToken = (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({
        error: 'No token provided'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Uzatılmış süre ile yeni token oluştur
    const newToken = generateToken(decoded.userId, decoded.username);
    
    res.json({
      success: true,
      token: newToken,
      expiresIn: process.env.JWT_EXPIRES_IN || '7d'
    });
  } catch (error) {
    return res.status(401).json({
      error: 'Invalid token',
      message: error.message
    });
  }
};

module.exports = {
  authenticateToken,
  optionalAuth,
  generateToken,
  refreshToken
}; 
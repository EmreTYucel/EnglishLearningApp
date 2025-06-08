const jwt = require('jsonwebtoken');
const crypto = require('crypto');

// Güvenli rastgele secret oluştur (eğer sağlanmamışsa)
const generateSecureSecret = () => {
  return crypto.randomBytes(64).toString('hex');
};

// SHA256 hash oluştur
const createSHA256Hash = (data) => {
  return crypto.createHash('sha256').update(data).digest('hex');
};

// Ek güvenlik önlemleri ile JWT token oluştur
const generateSecureToken = (payload, options = {}) => {
  const defaultOptions = {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    issuer: 'english-learning-app',
    audience: 'english-learning-users',
    algorithm: 'HS256'
  };

  const tokenOptions = { ...defaultOptions, ...options };
  
  // Ek güvenlik için zaman damgası ve rastgele nonce ekle
  const securePayload = {
    ...payload,
    iat: Math.floor(Date.now() / 1000),
    nonce: crypto.randomBytes(16).toString('hex'),
    tokenId: crypto.randomUUID()
  };

  return jwt.sign(securePayload, process.env.JWT_SECRET, tokenOptions);
};

// Ek kontroller ile JWT token doğrula
const verifySecureToken = (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET, {
      issuer: 'english-learning-app',
      audience: 'english-learning-users',
      algorithms: ['HS256']
    });

    // Token'ın çok eski olmadığını kontrol et (ek güvenlik)
    const tokenAge = Date.now() / 1000 - decoded.iat;
    const maxAge = 7 * 24 * 60 * 60; // 7 gün (saniye cinsinden)

    if (tokenAge > maxAge) {
      throw new Error('Token is too old');
    }

    return decoded;
  } catch (error) {
    throw error;
  }
};

// Yenileme token'ı oluştur
const generateRefreshToken = (userId) => {
  const payload = {
    userId,
    type: 'refresh',
    tokenId: crypto.randomUUID()
  };

  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: '30d', // Yenileme token'ları daha uzun süre geçerli
    issuer: 'english-learning-app',
    audience: 'english-learning-users'
  });
};

// Şifre sıfırlama token'ı oluştur
const generatePasswordResetToken = (userId, email) => {
  const payload = {
    userId,
    email,
    type: 'password-reset',
    timestamp: Date.now()
  };

  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: '1h', // Şifre sıfırlama token'ları hızlı sürede geçerliliğini yitirir
    issuer: 'english-learning-app',
    audience: 'english-learning-users'
  });
};

// Şifre sıfırlama token'ını doğrula
const verifyPasswordResetToken = (token) => {
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    if (decoded.type !== 'password-reset') {
      throw new Error('Invalid token type');
    }

    // Token'ın 1 saatten eski olmadığını kontrol et
    const tokenAge = Date.now() - decoded.timestamp;
    if (tokenAge > 60 * 60 * 1000) { // 1 saat (milisaniye cinsinden)
      throw new Error('Password reset token expired');
    }

    return decoded;
  } catch (error) {
    throw error;
  }
};

// Harici servisler için API anahtarı oluştur
const generateAPIKey = (userId, service) => {
  const data = `${userId}-${service}-${Date.now()}`;
  const hash = createSHA256Hash(data);
  return `elk_${hash.substring(0, 32)}`;
};

// API anahtarı formatını doğrula
const validateAPIKey = (apiKey) => {
  const pattern = /^elk_[a-f0-9]{32}$/;
  return pattern.test(apiKey);
};

// Geçici erişim için oturum token'ı oluştur
const generateSessionToken = (userId, sessionData = {}) => {
  const payload = {
    userId,
    sessionId: crypto.randomUUID(),
    sessionData,
    type: 'session'
  };

  return jwt.sign(payload, process.env.JWT_SECRET, {
    expiresIn: '2h', // Oturum token'ları kısa ömürlüdür
    issuer: 'english-learning-app',
    audience: 'english-learning-users'
  });
};

// Token'dan kullanıcı ID'sini çıkar (tam doğrulama olmadan, loglama için)
const extractUserIdFromToken = (token) => {
  try {
    const decoded = jwt.decode(token);
    return decoded?.userId || null;
  } catch (error) {
    return null;
  }
};

// Token'ın süresi dolmuş mu kontrol et (hata fırlatmadan)
const isTokenExpired = (token) => {
  try {
    const decoded = jwt.decode(token);
    if (!decoded || !decoded.exp) return true;
    
    return Date.now() >= decoded.exp * 1000;
  } catch (error) {
    return true;
  }
};

// Çeşitli amaçlar için güvenli rastgele string oluştur
const generateSecureRandomString = (length = 32) => {
  return crypto.randomBytes(length).toString('hex');
};

// Veri bütünlüğü için HMAC imzası oluştur
const createHMACSignature = (data, secret = process.env.JWT_SECRET) => {
  return crypto.createHmac('sha256', secret).update(data).digest('hex');
};

// HMAC imzasını doğrula
const verifyHMACSignature = (data, signature, secret = process.env.JWT_SECRET) => {
  const expectedSignature = createHMACSignature(data, secret);
  return crypto.timingSafeEqual(
    Buffer.from(signature, 'hex'),
    Buffer.from(expectedSignature, 'hex')
  );
};

module.exports = {
  generateSecureSecret,
  createSHA256Hash,
  generateSecureToken,
  verifySecureToken,
  generateRefreshToken,
  generatePasswordResetToken,
  verifyPasswordResetToken,
  generateAPIKey,
  validateAPIKey,
  generateSessionToken,
  extractUserIdFromToken,
  isTokenExpired,
  generateSecureRandomString,
  createHMACSignature,
  verifyHMACSignature
}; 
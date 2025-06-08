const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const { initializeDatabase } = require('./src/config/database');
const authRoutes = require('./src/routes/authRoutes');
const wordRoutes = require('./src/routes/wordRoutes');
const quizRoutes = require('./src/routes/quizRoutes');
const userRoutes = require('./src/routes/userRoutes');
const wordleRoutes = require('./src/routes/wordleRoutes');

const app = express();
const PORT = process.env.PORT || 3000;

// Güvenlik middleware'i - HTTP başlıklarını güvenli hale getirir
app.use(helmet());

// Rate limiting - IP bazlı istek sınırlaması
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS) || 15 * 60 * 1000, // 15 dakika
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS) || 100, // Her IP için 15 dakikada maksimum 100 istek
  message: {
    error: 'Too many requests from this IP, please try again later.'
  }
});
app.use(limiter);

// CORS yapılandırması - Cross-Origin Resource Sharing ayarları
app.use(cors({
  origin: '*', // Geliştirme için tüm originlere izin ver
  credentials: true,
}));

// Loglama middleware'i - HTTP isteklerini loglar
app.use(morgan('combined'));

// Body parsing middleware - JSON ve URL-encoded verileri işler
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Statik dosyalar için middleware - uploads klasörünü public yapar
app.use('/uploads', express.static('uploads'));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    message: 'English Learning API is running',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/words', wordRoutes);
app.use('/api/quiz', quizRoutes);
app.use('/api/users', userRoutes);
app.use('/api/wordle', wordleRoutes);

// Welcome endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to English Learning API',
    version: '1.0.0',
    description: '6 Sefer ile Kelime Ezberleme Sistemi',
    endpoints: {
      health: '/health',
      auth: '/api/auth',
      words: '/api/words',
      quiz: '/api/quiz',
      users: '/api/users',
      wordle: '/api/wordle'
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    message: `Cannot ${req.method} ${req.originalUrl}`
  });
});

// Global hata yakalayıcı - Tüm hataları merkezi olarak yönetir
app.use((err, req, res, next) => {
  console.error(err.stack);
  
  // Validasyon hatalarını yakala
  if (err.name === 'ValidationError') {
    return res.status(400).json({
      error: 'Validation Error',
      message: err.message
    });
  }
  
  // JWT token hatalarını yakala
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      error: 'Invalid Token',
      message: 'Please provide a valid token'
    });
  }
  
  // Süresi dolmuş token hatalarını yakala
  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      error: 'Token Expired',
      message: 'Please login again'
    });
  }

  // Diğer tüm hataları yakala
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal Server Error' : err.message,
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack })
  });
});

// Sunucuyu başlatma fonksiyonu
const startServer = async () => {
  try {
    // Veritabanı bağlantısını başlat
    await initializeDatabase();

    // Veritabanı bağlantısını uygulama genelinde kullanılabilir yap
    const db = require('./src/config/database');
    app.locals.db = db;
    
    // Sunucuyu başlat ve log mesajlarını göster
    app.listen(PORT, () => {
      console.log(`🚀 English Learning API server is running on port ${PORT}`);
      console.log(`📚 Environment: ${process.env.NODE_ENV}`);
      console.log(`🔗 Health check: http://localhost:${PORT}/health`);
      console.log(`📖 API Documentation: http://localhost:${PORT}/`);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Sunucuyu başlat
startServer();

module.exports = app; 
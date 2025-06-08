// PostgreSQL veritabanı bağlantısı için gerekli modül
const { Pool } = require('pg');
require('dotenv').config();

// Veritabanı bağlantı ayarları
const dbConfig = {
  host: process.env.DB_HOST || 'localhost',      // Veritabanı sunucusu
  port: process.env.DB_PORT || 5432,             // PostgreSQL varsayılan portu
  database: process.env.DB_NAME || 'english_learning_db', // Veritabanı adı
  user: process.env.DB_USER || 'postgres',       // Veritabanı kullanıcısı
  password: process.env.DB_PASSWORD || '',       // Veritabanı şifresi
  max: 20,                                       // Havuzdaki maksimum bağlantı sayısı
  idleTimeoutMillis: 30000,                      // Boşta kalma süresi
  connectionTimeoutMillis: 2000,                 // Bağlantı bekleme süresi
};

// Bağlantı havuzu oluşturma
const pool = new Pool(dbConfig);

// Veritabanı bağlantı başarılı olduğunda
pool.on('connect', () => {
  console.log('✅ Connected to PostgreSQL database');
});

// Veritabanı bağlantı hatası olduğunda
pool.on('error', (err) => {
  console.error('❌ Unexpected error on idle client', err);
  process.exit(-1);
});

// Veritabanı tablolarını oluşturma fonksiyonu
const initializeDatabase = async () => {
  try {
    const client = await pool.connect();
    
    // Kullanıcılar tablosu - Kullanıcı bilgilerini saklar
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        user_id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT true,
        profile_picture VARCHAR(255),
        daily_word_limit INTEGER DEFAULT 10,
        streak_count INTEGER DEFAULT 0,
        last_login TIMESTAMP
      );
    `);

    // Kelimeler tablosu - İngilizce-Türkçe kelime çevirilerini saklar
    await client.query(`
      CREATE TABLE IF NOT EXISTS words (
        word_id SERIAL PRIMARY KEY,
        english_word VARCHAR(100) NOT NULL,
        turkish_word VARCHAR(100) NOT NULL,
        picture VARCHAR(255),
        pronunciation VARCHAR(255),
        difficulty_level INTEGER DEFAULT 1,
        category VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_active BOOLEAN DEFAULT true
      );
    `);

    // Örnek cümleler tablosu - Kelimelerin örnek kullanımlarını saklar
    await client.query(`
      CREATE TABLE IF NOT EXISTS word_samples (
        sample_id SERIAL PRIMARY KEY,
        word_id INTEGER REFERENCES words(word_id) ON DELETE CASCADE,
        sample_sentence TEXT NOT NULL,
        sample_translation TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Kullanıcı kelime ilerleme tablosu - Kullanıcıların kelime öğrenme durumlarını takip eder
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_word_progress (
        progress_id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
        word_id INTEGER REFERENCES words(word_id) ON DELETE CASCADE,
        repetition_count INTEGER DEFAULT 0,
        last_reviewed TIMESTAMP,
        next_review TIMESTAMP,
        is_learned BOOLEAN DEFAULT false,
        difficulty_rating INTEGER DEFAULT 3,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, word_id)
      );
    `);

    // Quiz oturumları tablosu - Kullanıcıların quiz performanslarını kaydeder
    await client.query(`
      CREATE TABLE IF NOT EXISTS quiz_sessions (
        session_id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
        total_questions INTEGER NOT NULL,
        correct_answers INTEGER DEFAULT 0,
        score DECIMAL(5,2) DEFAULT 0,
        duration_seconds INTEGER,
        started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMP,
        quiz_type VARCHAR(50) DEFAULT 'vocabulary'
      );
    `);

    // Quiz cevapları tablosu - Quiz sorularına verilen cevapları saklar
    await client.query(`
      CREATE TABLE IF NOT EXISTS quiz_answers (
        answer_id SERIAL PRIMARY KEY,
        session_id INTEGER REFERENCES quiz_sessions(session_id) ON DELETE CASCADE,
        word_id INTEGER REFERENCES words(word_id) ON DELETE CASCADE,
        user_answer VARCHAR(255),
        correct_answer VARCHAR(255),
        is_correct BOOLEAN,
        response_time_ms INTEGER,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);

    // Wordle oyunu tablosu - Wordle oyun istatistiklerini saklar
    await client.query(`
      CREATE TABLE IF NOT EXISTS wordle_games (
        game_id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
        target_word VARCHAR(5) NOT NULL,
        guesses TEXT[], -- Tahminler dizisi
        is_completed BOOLEAN DEFAULT false,
        is_won BOOLEAN DEFAULT false,
        attempts_used INTEGER DEFAULT 0,
        max_attempts INTEGER DEFAULT 6,
        started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        completed_at TIMESTAMP
      );
    `);

    // Kullanıcı istatistikleri tablosu - Kullanıcıların genel performans verilerini saklar
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_statistics (
        stat_id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
        words_learned INTEGER DEFAULT 0,
        words_in_progress INTEGER DEFAULT 0,
        total_quiz_sessions INTEGER DEFAULT 0,
        average_quiz_score DECIMAL(5,2) DEFAULT 0,
        total_study_time_minutes INTEGER DEFAULT 0,
        current_streak INTEGER DEFAULT 0,
        longest_streak INTEGER DEFAULT 0,
        last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id)
      );
    `);

    // Performans için indeksler oluşturma
    await client.query(`
      CREATE INDEX IF NOT EXISTS idx_user_word_progress_user_id ON user_word_progress(user_id);
      CREATE INDEX IF NOT EXISTS idx_user_word_progress_word_id ON user_word_progress(word_id);
      CREATE INDEX IF NOT EXISTS idx_user_word_progress_next_review ON user_word_progress(next_review);
      CREATE INDEX IF NOT EXISTS idx_words_english ON words(english_word);
      CREATE INDEX IF NOT EXISTS idx_quiz_sessions_user_id ON quiz_sessions(user_id);
      CREATE INDEX IF NOT EXISTS idx_wordle_games_user_id ON wordle_games(user_id);
    `);

    client.release();
    console.log('✅ Database tables initialized successfully');
    
  } catch (error) {
    console.error('❌ Error initializing database:', error);
    throw error;
  }
};

// SQL sorgusu çalıştırma yardımcı fonksiyonu
const query = async (text, params) => {
  const start = Date.now();
  try {
    const res = await pool.query(text, params);
    const duration = Date.now() - start;
    console.log('Executed query', { text, duration, rows: res.rowCount });
    return res;
  } catch (error) {
    console.error('Database query error:', error);
    throw error;
  }
};

// Transaction (işlem) yardımcı fonksiyonu
const transaction = async (callback) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  pool,
  query,
  transaction,
  initializeDatabase
}; 
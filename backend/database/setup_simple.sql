-- English Learning App Database Setup Script (Simplified)
-- PostgreSQL Database Schema

-- Enable UUID extension for generating UUIDs
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop tables if they exist (for clean setup)
DROP TABLE IF EXISTS word_chain_games CASCADE;
DROP TABLE IF EXISTS user_statistics CASCADE;
DROP TABLE IF EXISTS quiz_answers CASCADE;
DROP TABLE IF EXISTS quiz_sessions CASCADE;
DROP TABLE IF EXISTS wordle_games CASCADE;
DROP TABLE IF EXISTS user_word_progress CASCADE;
DROP TABLE IF EXISTS word_samples CASCADE;
DROP TABLE IF EXISTS words CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Users table
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    profile_picture VARCHAR(255),
    daily_word_limit INTEGER DEFAULT 10 CHECK (daily_word_limit BETWEEN 1 AND 50),
    streak_count INTEGER DEFAULT 0 CHECK (streak_count >= 0),
    last_login TIMESTAMP
);

-- Words table
CREATE TABLE words (
    word_id SERIAL PRIMARY KEY,
    english_word VARCHAR(100) UNIQUE NOT NULL,
    turkish_word VARCHAR(100) NOT NULL,
    picture VARCHAR(255),
    pronunciation VARCHAR(255),
    difficulty_level INTEGER DEFAULT 1 CHECK (difficulty_level BETWEEN 1 AND 5),
    category VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT true
);

-- Word samples table (example sentences)
CREATE TABLE word_samples (
    sample_id SERIAL PRIMARY KEY,
    word_id INTEGER REFERENCES words(word_id) ON DELETE CASCADE,
    sample_sentence TEXT NOT NULL,
    sample_translation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User word progress table (spaced repetition tracking)
CREATE TABLE user_word_progress (
    progress_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    word_id INTEGER REFERENCES words(word_id) ON DELETE CASCADE,
    repetition_count INTEGER DEFAULT 0 CHECK (repetition_count >= 0),
    last_reviewed TIMESTAMP,
    next_review TIMESTAMP,
    is_learned BOOLEAN DEFAULT false,
    difficulty_rating INTEGER DEFAULT 3 CHECK (difficulty_rating BETWEEN 1 AND 5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, word_id)
);

-- Quiz sessions table
CREATE TABLE quiz_sessions (
    session_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    total_questions INTEGER NOT NULL CHECK (total_questions > 0),
    correct_answers INTEGER DEFAULT 0 CHECK (correct_answers >= 0),
    score DECIMAL(5,2) DEFAULT 0 CHECK (score >= 0 AND score <= 100),
    duration_seconds INTEGER CHECK (duration_seconds >= 0),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    quiz_type VARCHAR(50) DEFAULT 'vocabulary'
);

-- Quiz answers table
CREATE TABLE quiz_answers (
    answer_id SERIAL PRIMARY KEY,
    session_id INTEGER REFERENCES quiz_sessions(session_id) ON DELETE CASCADE,
    word_id INTEGER REFERENCES words(word_id) ON DELETE CASCADE,
    user_answer VARCHAR(255),
    correct_answer VARCHAR(255),
    is_correct BOOLEAN,
    response_time_ms INTEGER CHECK (response_time_ms >= 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Wordle games table
CREATE TABLE wordle_games (
    game_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    target_word VARCHAR(5) NOT NULL,
    guesses JSONB DEFAULT '[]',
    is_completed BOOLEAN DEFAULT false,
    is_won BOOLEAN DEFAULT false,
    attempts_used INTEGER DEFAULT 0 CHECK (attempts_used >= 0),
    max_attempts INTEGER DEFAULT 6 CHECK (max_attempts > 0),
    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- User statistics table
CREATE TABLE user_statistics (
    stat_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    words_learned INTEGER DEFAULT 0 CHECK (words_learned >= 0),
    words_in_progress INTEGER DEFAULT 0 CHECK (words_in_progress >= 0),
    total_quiz_sessions INTEGER DEFAULT 0 CHECK (total_quiz_sessions >= 0),
    average_quiz_score DECIMAL(5,2) DEFAULT 0 CHECK (average_quiz_score >= 0 AND average_quiz_score <= 100),
    total_study_time_minutes INTEGER DEFAULT 0 CHECK (total_study_time_minutes >= 0),
    current_streak INTEGER DEFAULT 0 CHECK (current_streak >= 0),
    longest_streak INTEGER DEFAULT 0 CHECK (longest_streak >= 0),
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id)
);

-- Word Chain games table (for LLM feature)
CREATE TABLE word_chain_games (
    chain_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    story_prompt TEXT NOT NULL,
    generated_story TEXT,
    generated_image_url VARCHAR(500),
    words_used JSONB DEFAULT '[]',
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- Create indexes for better performance
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_active ON users(is_active);

CREATE INDEX idx_words_english ON words(english_word);
CREATE INDEX idx_words_category ON words(category);
CREATE INDEX idx_words_active ON words(is_active);
CREATE INDEX idx_words_difficulty ON words(difficulty_level);

CREATE INDEX idx_word_samples_word_id ON word_samples(word_id);

CREATE INDEX idx_user_word_progress_user_id ON user_word_progress(user_id);
CREATE INDEX idx_user_word_progress_word_id ON user_word_progress(word_id);
CREATE INDEX idx_user_word_progress_next_review ON user_word_progress(next_review);
CREATE INDEX idx_user_word_progress_learned ON user_word_progress(is_learned);

CREATE INDEX idx_quiz_sessions_user_id ON quiz_sessions(user_id);
CREATE INDEX idx_quiz_sessions_completed ON quiz_sessions(completed_at);

CREATE INDEX idx_quiz_answers_session_id ON quiz_answers(session_id);
CREATE INDEX idx_quiz_answers_word_id ON quiz_answers(word_id);

CREATE INDEX idx_wordle_games_user_id ON wordle_games(user_id);
CREATE INDEX idx_wordle_games_completed ON wordle_games(is_completed);

CREATE INDEX idx_user_statistics_user_id ON user_statistics(user_id);

CREATE INDEX idx_word_chain_games_user_id ON word_chain_games(user_id);

-- Create admin user (password: Admin123456)
-- Password hash for 'Admin123456' using bcrypt
INSERT INTO users (username, email, password_hash, daily_word_limit) VALUES
('admin', 'admin@englishlearning.com', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/RK.PJ/..G', 50);

-- Insert sample words
INSERT INTO words (english_word, turkish_word, category, difficulty_level) VALUES
-- A1 Seviyesi (Başlangıç)
('hello', 'merhaba', 'Greetings', 1),
('goodbye', 'hoşça kal', 'Greetings', 1),
('thank you', 'teşekkür ederim', 'Greetings', 1),
('please', 'lütfen', 'Greetings', 1),
('sorry', 'özür dilerim', 'Greetings', 1),
('yes', 'evet', 'Basic Words', 1),
('no', 'hayır', 'Basic Words', 1),
('water', 'su', 'Food & Drink', 1),
('bread', 'ekmek', 'Food & Drink', 1),
('milk', 'süt', 'Food & Drink', 1),

-- A2 Seviyesi (Temel)
('beautiful', 'güzel', 'Adjectives', 2),
('ugly', 'çirkin', 'Adjectives', 2),
('big', 'büyük', 'Adjectives', 2),
('small', 'küçük', 'Adjectives', 2),
('hot', 'sıcak', 'Adjectives', 2),
('cold', 'soğuk', 'Adjectives', 2),
('happy', 'mutlu', 'Emotions', 2),
('sad', 'üzgün', 'Emotions', 2),
('angry', 'kızgın', 'Emotions', 2),
('tired', 'yorgun', 'Emotions', 2),

-- B1 Seviyesi (Orta)
('accomplish', 'başarmak', 'Verbs', 3),
('achieve', 'elde etmek', 'Verbs', 3),
('consider', 'düşünmek', 'Verbs', 3),
('develop', 'geliştirmek', 'Verbs', 3),
('establish', 'kurmak', 'Verbs', 3),
('maintain', 'sürdürmek', 'Verbs', 3),
('obtain', 'elde etmek', 'Verbs', 3),
('provide', 'sağlamak', 'Verbs', 3),
('require', 'gerektirmek', 'Verbs', 3),
('suggest', 'önermek', 'Verbs', 3),

-- B2 Seviyesi (İyi)
('ambiguous', 'belirsiz', 'Adjectives', 4),
('arbitrary', 'keyfi', 'Adjectives', 4),
('comprehensive', 'kapsamlı', 'Adjectives', 4),
('concurrent', 'eşzamanlı', 'Adjectives', 4),
('conspicuous', 'göz alıcı', 'Adjectives', 4),
('controversial', 'tartışmalı', 'Adjectives', 4),
('elaborate', 'ayrıntılı', 'Adjectives', 4),
('explicit', 'açık', 'Adjectives', 4),
('implicit', 'örtük', 'Adjectives', 4),
('inherent', 'doğal', 'Adjectives', 4),

-- C1 Seviyesi (İleri)
('aberration', 'sapma', 'Nouns', 5),
('abstraction', 'soyutlama', 'Nouns', 5),
('accommodation', 'konaklama', 'Nouns', 5),
('acquisition', 'edinme', 'Nouns', 5),
('adversity', 'zorluk', 'Nouns', 5),
('aesthetic', 'estetik', 'Nouns', 5),
('affiliation', 'bağlantı', 'Nouns', 5),
('ambiguity', 'belirsizlik', 'Nouns', 5),
('analogy', 'benzetme', 'Nouns', 5),
('anomaly', 'anormallik', 'Nouns', 5);

-- Database setup completed
SELECT 'English Learning Database setup completed successfully!' as status; 
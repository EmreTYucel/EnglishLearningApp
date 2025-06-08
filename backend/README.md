# English Learning App - Backend API

Bu proje, İngilizce kelime öğrenme uygulamasının backend API'sidir. Node.js, Express.js ve PostgreSQL kullanılarak geliştirilmiştir.

## 🚀 Özellikler

- **JWT Authentication**: Güvenli kullanıcı kimlik doğrulama
- **PostgreSQL Database**: Güçlü ilişkisel veritabanı
- **RESTful API**: Modern API tasarım prensipleri
- **Input Validation**: Express-validator ile veri doğrulama
- **Security**: Helmet, CORS, Rate limiting
- **Spaced Repetition**: Kelime tekrarı algoritması
- **File Upload**: Multer ile resim yükleme
- **Error Handling**: Kapsamlı hata yönetimi

## 🛠️ Teknoloji Stack

- **Node.js**: JavaScript runtime
- **Express.js**: Web framework
- **PostgreSQL**: Veritabanı
- **JWT**: Authentication
- **bcryptjs**: Password hashing
- **Multer**: File upload
- **Helmet**: Security headers
- **CORS**: Cross-origin resource sharing
- **Morgan**: HTTP request logger

## 📋 Gereksinimler

- Node.js (v16 veya üzeri)
- PostgreSQL (v12 veya üzeri)
- npm veya yarn

## 🚀 Kurulum

### 1. Projeyi klonlayın
```bash
git clone <repository-url>
cd backend
```

### 2. Bağımlılıkları yükleyin
```bash
npm install
```

### 3. PostgreSQL veritabanını kurun
```sql
-- PostgreSQL'de yeni veritabanı oluşturun
CREATE DATABASE english_learning_db;
CREATE USER your_username WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE english_learning_db TO your_username;
```

### 4. Environment variables'ları ayarlayın
`.env` dosyasını oluşturun ve aşağıdaki değişkenleri ekleyin:

```env
# Server Configuration
PORT=3000
NODE_ENV=development

# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=english_learning_db
DB_USER=your_username
DB_PASSWORD=your_password

# JWT Configuration
JWT_SECRET=your_super_secret_jwt_key_here_change_in_production
JWT_EXPIRES_IN=7d

# File Upload Configuration
MAX_FILE_SIZE=5242880
UPLOAD_PATH=./uploads

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100

# CORS Configuration
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

### 5. Sunucuyu başlatın
```bash
# Development mode
npm run dev

# Production mode
npm start
```

## 📚 API Endpoints

### Authentication
- `POST /api/auth/register` - Kullanıcı kaydı
- `POST /api/auth/login` - Kullanıcı girişi
- `GET /api/auth/profile` - Kullanıcı profili
- `PUT /api/auth/profile` - Profil güncelleme
- `PUT /api/auth/change-password` - Şifre değiştirme
- `POST /api/auth/logout` - Çıkış
- `POST /api/auth/refresh-token` - Token yenileme

### Words
- `GET /api/words` - Tüm kelimeleri getir
- `GET /api/words/daily` - Günlük kelimeler
- `POST /api/words/:id/progress` - Kelime ilerlemesi güncelle

### Quiz
- `GET /api/quiz` - Mevcut quizler
- `POST /api/quiz/start` - Quiz başlat
- `POST /api/quiz/answer` - Cevap gönder
- `POST /api/quiz/complete` - Quiz tamamla
- `GET /api/quiz/history` - Quiz geçmişi

### Users
- `GET /api/users/statistics` - Kullanıcı istatistikleri
- `GET /api/users/progress` - Öğrenme ilerlemesi
- `GET /api/users/achievements` - Başarımlar

## 🗄️ Veritabanı Şeması

### Users
```sql
CREATE TABLE users (
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
```

### Words
```sql
CREATE TABLE words (
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
```

### User Word Progress
```sql
CREATE TABLE user_word_progress (
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
```

## 🔐 Authentication

API, JWT (JSON Web Token) tabanlı authentication kullanır. Protected endpoint'lere erişim için:

```javascript
// Header'da token gönderme
Authorization: Bearer <your_jwt_token>
```

## 📝 API Kullanım Örnekleri

### Kullanıcı Kaydı
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "Test123456"
  }'
```

### Kullanıcı Girişi
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "Test123456"
  }'
```

### Profil Bilgisi
```bash
curl -X GET http://localhost:3000/api/auth/profile \
  -H "Authorization: Bearer <your_jwt_token>"
```

## 🔧 Spaced Repetition Algoritması

Kelime tekrarı için aşağıdaki aralıklar kullanılır:
- 1. tekrar: 1 gün sonra
- 2. tekrar: 3 gün sonra
- 3. tekrar: 7 gün sonra
- 4. tekrar: 14 gün sonra
- 5. tekrar: 30 gün sonra
- 6. tekrar: 90 gün sonra

## 🛡️ Güvenlik

- **Helmet**: HTTP security headers
- **CORS**: Cross-origin resource sharing kontrolü
- **Rate Limiting**: API abuse koruması
- **Input Validation**: Veri doğrulama
- **Password Hashing**: bcryptjs ile güvenli şifreleme
- **JWT**: Stateless authentication

## 📊 Monitoring & Logging

- **Morgan**: HTTP request logging
- **Error Handling**: Kapsamlı hata yakalama
- **Health Check**: `/health` endpoint

## 🚀 Deployment

### Production Environment Variables
```env
NODE_ENV=production
JWT_SECRET=very_secure_secret_key_for_production
DB_PASSWORD=secure_database_password
ALLOWED_ORIGINS=https://yourdomain.com
```

### PM2 ile Deployment
```bash
npm install -g pm2
pm2 start server.js --name "english-learning-api"
pm2 startup
pm2 save
```

## 🧪 Testing

```bash
# Health check
curl http://localhost:3000/health

# API documentation
curl http://localhost:3000/
```

## 📈 Performance

- **Connection Pooling**: PostgreSQL connection pool
- **Indexing**: Database indexes for better performance
- **Caching**: Ready for Redis integration
- **Compression**: Gzip compression support

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the ISC License.

## 📞 Support

Proje hakkında sorularınız için lütfen takım üyeleri ile iletişime geçin.

---

**Not**: Bu API, İngilizce kelime öğrenme uygulamasının backend servisidir ve eğitim amaçlı geliştirilmektedir. 
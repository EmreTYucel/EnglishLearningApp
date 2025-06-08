# İngilizce Kelime Öğrenme Uygulaması

Bu proje, Scrum metodolojisi kullanılarak geliştirilecek bir İngilizce kelime öğrenme uygulamasıdır. Uygulama, 6 sefer ile kelime ezberleme sistemi kullanarak etkili öğrenme sağlar.

## 🎯 Proje Özeti

- **Dönem Notma Etkisi**: %40
- **Proje Son Gönderim Tarihi**: Dönemin Son Haftası
- **Takım Üye Sayısı**: En fazla 4 kişi ile sınırlıdır

## 📱 Özellikler

### 1. Kullanıcı Yönetimi (5 puan)
- Kullanıcı kayıt ve giriş sistemi
- Şifremi unuttum ve giriş bölümü olmalı

### 2. Kelime Ekleme Modülü (5 puan)
- Kelimeler text ve resim içerebilecek
- İngilizce kelime, Türkçe karşılığı, İngilizce kelimenin birden çok etimle içerisinde geçmesi
- Kelime ile ilgili bir resim ve ops olarak sesli okunuşu

### 3. Sınav Modülü (10 puan)
- Temel 6 Sefer Quiz Sorularının Belirlenme Algoritması
- Spaced repetition algoritması kullanılarak kelime tekrarı

### 4. Kullanıcı Ayarları (5 puan)
- Kullanıcı kendi ekranında ayarlar kısmı bulunacak
- Öğrenci isterse yeni kelime çıkma sayısını yani 10 sayısını değiştirebilecek

### 5. Analiz Raporu (5 puan)
- Kullanıcı gözümlediği kelimeler üzerinden bir analiz raporu alabilsin
- Öğrencinin hangi konular ile ilgili olarak ne kadar başarılı olduğunun gösterilsin

### 6. Wordle Oyunu (15 puan)
- Öğrenilen kelimelerden oluşmalıdır
- 5 harfli kelime bulma oyunu

### 7. Word Chain Oyunu (5 puan)
- LLM hikaye ve görsel oluşturmalı ve bu görsel app içerisinde kaydedilmeli

## 🛠️ Teknoloji Stack

### Frontend (Mobil Uygulama)
- **Flutter**: Cross-platform mobil uygulama geliştirme
- **Dart**: Programlama dili
- **Provider**: State management
- **Go Router**: Navigation
- **Material 3**: Modern UI tasarım sistemi

### Backend
- **Node.js**: Server-side JavaScript runtime
- **Express.js**: Web framework
- **PostgreSQL**: Veritabanı

### Paketler
- `provider`: State management
- `go_router`: Navigation
- `http`: API istekleri
- `shared_preferences`: Local storage
- `font_awesome_flutter`: İkonlar
- `lottie`: Animasyonlar

## 🏗️ Proje Yapısı

```
lib/
├── main.dart                 # Ana uygulama dosyası
├── providers/               # State management
│   ├── auth_provider.dart
│   ├── word_provider.dart
│   └── quiz_provider.dart
├── screens/                 # Ekranlar
│   ├── splash_screen.dart
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   └── home_screen.dart
│   ├── words/
│   │   └── word_list_screen.dart
│   ├── quiz/
│   │   └── quiz_screen.dart
│   ├── wordle/
│   │   └── wordle_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── models/                  # Veri modelleri
├── services/               # API servisleri
├── widgets/                # Yeniden kullanılabilir widget'lar
└── utils/                  # Yardımcı fonksiyonlar
```

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK (3.7.2 veya üzeri)
- Dart SDK
- Android Studio / VS Code
- Git

### Adımlar

1. **Projeyi klonlayın**
   ```bash
   git clone <repository-url>
   cd english_learning_app
   ```

2. **Bağımlılıkları yükleyin**
   ```bash
   flutter pub get
   ```

3. **Uygulamayı çalıştırın**
   ```bash
   flutter run
   ```

## 📋 Geliştirme Durumu

### ✅ Tamamlanan
- [x] Proje yapısı oluşturuldu
- [x] Material 3 tema yapılandırması
- [x] Splash screen animasyonları
- [x] Login/Register ekranları
- [x] Ana sayfa dashboard tasarımı
- [x] State management (Provider) kurulumu
- [x] Navigation (Go Router) yapılandırması
- [x] Temel kelime modeli ve provider

### 🔄 Devam Eden
- [ ] Kelime listesi ekranı
- [ ] Quiz modülü
- [ ] Wordle oyunu
- [ ] Backend API entegrasyonu

### 📅 Planlanan
- [ ] Kullanıcı profil yönetimi
- [ ] Analiz raporu ekranı
- [ ] Word Chain oyunu
- [ ] Sesli okunuş özelliği
- [ ] Resim yükleme sistemi

## 🎨 Tasarım Özellikleri

- **Modern UI**: Material 3 tasarım sistemi
- **Responsive**: Farklı ekran boyutlarına uyumlu
- **Animasyonlar**: Smooth geçişler ve etkileşimler
- **Dark/Light Mode**: Sistem temasına uyumlu
- **Accessibility**: Erişilebilirlik standartlarına uygun

## 🔧 Geliştirme Notları

### Spaced Repetition Algoritması
Kelime tekrarı için aşağıdaki aralıklar kullanılır:
- 1. tekrar: 1 gün sonra
- 2. tekrar: 3 gün sonra
- 3. tekrar: 7 gün sonra
- 4. tekrar: 14 gün sonra
- 5. tekrar: 30 gün sonra
- 6. tekrar: 90 gün sonra

### Veritabanı Şeması
```sql
-- Users tablosu
Users (UserID, UserName, Password)

-- Words tablosu  
Words (WordID, EngWordName, TurWordName, Picture)

-- WordSamples tablosu
WordSamples (WordSamplesID, WordID, Samples)
```

## 👥 Takım

Bu proje Scrum metodolojisi kullanılarak geliştirilmektedir. Takım üye sayısı en fazla 4 kişi ile sınırlıdır.

## 📞 İletişim

Proje hakkında sorularınız için lütfen takım üyeleri ile iletişime geçin.

---

**Not**: Bu proje eğitim amaçlı geliştirilmektedir ve dönem notunun %40'ını oluşturmaktadır.

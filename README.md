
# 📚 6 Sefer Tekrar Prensibine Dayalı Kelime Ezberleme Uygulaması

![App Preview](screenshots/home.png)

Bu mobil uygulama, **Scrum metodolojisi** kullanılarak geliştirilen bir **İngilizce kelime ezberleme** oyunudur. Uygulama, Ebbinghaus’un unutma eğrisine dayalı olarak **6 farklı zamanda yapılan tekrarlar** ile kullanıcıların kelimeleri uzun süreli hafızalarında tutmalarını hedefler.

## 🚀 Özellikler

| Modül | Açıklama |
|-------|----------|
| 👤 Kullanıcı Sistemi | Kayıt ol, giriş yap ve şifremi unuttum özelliği |
| ➕ Kelime Ekleme | İngilizce kelime, Türkçe karşılığı, örnek cümle, görsel (isteğe bağlı ses) |
| 🧠 6 Sefer Sınav Modülü | Aynı kelimenin 6 farklı tarihte doğru cevaplanması gerekir |
| ⚙️ Ayarlar | Günlük çıkan yeni kelime sayısı ayarlanabilir |
| 📊 Analiz Raporu | Konu bazlı başarı oranları ve çıktı alınabilir rapor |
| 🧩 Bulmaca (Wordle) | Öğrenilen kelimelerden 5 harfli tahmin oyunu |
| 🔗 Word Chain | LLM destekli görsel + kelime zincirleme hikaye modülü |

## 📸 Ekran Görüntüleri

| Ana Sayfa | Kelime Ekleme | Sınav Ekranı |
|-----------|----------------|---------------|
| ![Home](screenshots/home.png) | ![Add Word](screenshots/add_word.png) | ![Quiz](screenshots/quiz.png) |

| Ayarlar | Analiz | Wordle |
|--------|--------|--------|
| ![Settings](screenshots/settings.png) | ![Analysis](screenshots/analysis.png) | ![Wordle](screenshots/wordle.png) |

## 📱 Kullanıcı Akışı

1. **Kayıt Ol / Giriş Yap**
2. **Kelimeleri Ekle** (İngilizce-Türkçe + görsel + örnek cümle)
3. **Sınava Başla**: 6 tekrar algoritması ile kişiye özel testler.
4. **İlerlemeni Takip Et**: Analiz ekranı ile başarı yüzdelerini gör.
5. **Bulmaca & Zincir Modülleri** ile öğrenilenleri oyunlaştır.

## 🧠 6 Sefer Tekrar Prensibi

Uygulama, bir kelimenin uzun süreli öğrenilmesi için aşağıdaki zamanlamaya göre tekrar edilmesini gerektirir:

- 1 gün sonra
- 1 hafta sonra
- 1 ay sonra
- 3 ay sonra
- 6 ay sonra
- 1 yıl sonra

Her tekrar aşamasında kullanıcı doğru cevap verirse, sistem otomatik olarak bir sonraki aşamaya geçer. Hatalı cevaplarda ise sayaç sıfırlanır.

## 📊 Analiz ve Raporlama

Kullanıcılar, öğrenme süreçlerini şu metriklerle takip edebilir:

- Çözülmüş toplam sınav sayısı
- Günlük hedef ilerlemesi
- Öğrenilen kelime yüzdesi
- Konu bazlı başarı durumu
- Günlük tekrar serisi (streak)
- Kağıt çıktısı alınabilir PDF analiz raporu

## 🛠 Teknolojiler

- **Frontend**: Flutter (Dart)
- **Backend**: Node.js (Express)
- **Veritabanı**: PostgreSQL
- **Kimlik Doğrulama**: JWT
- **Ekstra**: LLM & AI Tabanlı Görsel Üretim, SonarQube analizi (opsiyonel)

## 🧩 Bonus Özellikler

- Rastgele karışık şıklar
- Sınav süresi ayarlanabilir yapı
- Zorluk seviyesi
- Boş sorulara dönüş özelliği
- Admin paneli ile kelime yönetimi
- Öğrenciye özel sınav tanımlama

## 🧪 Kurulum

```bash
git clone https://github.com/kullaniciadi/kelime-ezberleme-app.git
cd kelime-ezberleme-app
flutter pub get
```

**Backend çalıştırmak için:**

```bash
cd backend
npm install
node app.js
```

**PostgreSQL yapılandırma:** `.env` dosyasına aşağıdaki bilgileri girin:

```
DB_HOST=localhost
DB_PORT=5432
DB_USER=...
DB_PASS=...
DB_NAME=kelime_app
```

## 📁 Proje Yapısı

```
/frontend      → Flutter mobil uygulama
/backend       → Node.js API
/screenshots   → README için ekran görüntüleri
/video         → Uygulama tanıtım videosu
```

## 🎥 Demo Videosu

📺 [Uygulama Tanıtım Videosu (MP4)](./video/uygulama_demo.mp4)

## 📌 Katkıda Bulunanlar

| İsim | Numara |
|------|--------|
| Emre Yılmaz | 2021123456 |
| Ayşe Koç | 2021123457 |

## 📋 Proje Durumu ve Beyan

| Modül | Var mı? |
|-------|---------|
| Kayıt/Giriş/Şifre Yenileme | ✅ |
| Kelime Ekleme | ✅ |
| Sınav Modülü | ✅ |
| Kelime Sıklığı Değiştirme | ✅ |
| Analiz Raporu | ✅ |
| Wordle | ✅ |
| Word Chain (LLM) | ✅ |

## 📅 Scrum & Versiyon Kontrol

- Trello Board Ekran Görüntüsü: [./screenshots/scrum.png](./screenshots/scrum.png)
- GitHub Commitleri: En az 2 farklı katkıcı

## 🏁 APK Linki

Android APK (mobil demo): [indir (apk)](./build/app-release.apk)

## 🧹 Kod Kalitesi

- ✅ KISS Prensibi
- ✅ SonarQube Uyumlu
- ✅ Temiz Kodlama
- ✅ Modüler Yapı

## 📄 Lisans

MIT Lisansı

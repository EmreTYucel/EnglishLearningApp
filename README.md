
# 📚 6 Sefer Tekrar Prensibine Dayalı Kelime Ezberleme Uygulaması


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
5. **Bulmaca (Wordle) Modülü** ile öğrenilenleri oyunlaştır.

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

## 🧩 Bonus Özellikler

- Rastgele karışık şıklar
- Sınav süresi ayarlanabilir yapı
- Zorluk seviyesi

## 🧪 Kurulum

```bash
git clone https://github.com/EmreTYucel/EnglishLearningApp.git
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

## 📌 Katkıda Bulunanlar

| İsim | Numara |
|------|--------|
| Emre Tuna Yücel | 232803050 |
| Berat Gültekin | 232803066 |
| Mert Evran | 232805014 |
| Nihat Karakuzu | 232805010 |

## 📄 Lisans

MIT Lisansı



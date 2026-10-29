# Pazar Yap

**Semt Pazarı Sipariş Platformu**

<p align="center">
  <a href="./README.md"><img src="https://img.shields.io/badge/Language-Türkçe-E31E24?style=for-the-badge" alt="Türkçe" /></a>
  <a href="./README_EN.md"><img src="https://img.shields.io/badge/Language-English-00247D?style=for-the-badge" alt="English" /></a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" alt="Node.js" />
  <img src="https://img.shields.io/badge/TypeScript-3178C6?style=for-the-badge&logo=typescript&logoColor=white" alt="TypeScript" />
  <img src="https://img.shields.io/badge/Prisma-2D3748?style=for-the-badge&logo=prisma&logoColor=white" alt="Prisma" />
  <img src="https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white" alt="MySQL" />
  <img src="https://img.shields.io/badge/Express.js-000000?style=for-the-badge&logo=express&logoColor=white" alt="Express" />
</p>

Pazar Yap, semt pazarlarındaki taze ve uygun fiyatlı ürünleri dijital ortama taşıyarak müşterilerin kapılarından sipariş vermesini sağlayan, uçtan uca bir sipariş ve teslimat platformudur.

---

## İçindekiler

- [Proje Hakkında](#proje-hakkında)
- [Problem ve Motivasyon](#problem-ve-motivasyon)
- [Hedef Kitle](#hedef-kitle)
- [Özellikler](#özellikler)
- [Uygulama Akışı](#uygulama-akışı)
- [Ekran Görüntüleri](#ekran-görüntüleri)
- [Teknoloji Yığını](#teknoloji-yığını)
- [Mimari Yapı](#mimari-yapı)
- [Veritabanı Yapısı](#veritabanı-yapısı)
- [API Yapısı](#api-yapısı)
- [Kurulum ve Çalıştırma](#kurulum-ve-çalıştırma)
- [Proje Yapısı](#proje-yapısı)
- [Güvenlik](#güvenlik)
- [Lisans](#lisans)

---

## Proje Hakkında

Pazar Yap, geleneksel semt pazarı alışverişini mobil bir platforma dönüştüren tam yığın (full-stack) bir uygulamadır. Sistem dört farklı kullanıcı rolünü tek bir uygulama içinde yönetir:

- **Müşteri**: Yakınındaki kurulan semt pazarlarını görüntüler, tezgah bazında ürünleri karşılaştırır, sepetini oluşturur ve sipariş verir.
- **Kurye**: Siparişleri kabul eder, pazara giderek ürünleri tezgahlardan toplar ve müşteriye teslim eder.
- **Pazar Çalışanı**: Sahada güncel fiyat, birim ve fotoğraf verisi girerek ürün bilgilerini canlı tutar.
- **Yönetici (Admin)**: Tüm operasyonu merkezi bir panel üzerinden izler ve yönetir.

Uygulama Flutter ile geliştirilmiş olup Android ve iOS platformlarını destekler. Sunucu tarafı Node.js/Express.js ve TypeScript ile yazılmış, veritabanı olarak MySQL, ORM olarak Prisma kullanılmıştır.

---

## Problem ve Motivasyon

Türkiye'de semt pazarları, ürün tazeliği ve fiyat avantajı açısından süpermarketlere kıyasla önemli bir alternatif sunmaktadır. Ancak modern yaşamın yoğun temposu, fiziksel erişim güçlükleri ve zaman kısıtlamaları nedeniyle birçok tüketici bu avantajdan yararlanamamaktadır.

Mevcut market teslimat uygulamaları ise süpermarket depolarından hizmet verdiği için pazar tazeliğini ve fiyat avantajını sunamamaktadır.

**Pazar Yap bu boşluğu kapatmak için tasarlanmıştır:**

- Ürünler süpermarket deposundan değil, doğrudan o gün kurulan semt pazarındaki tezgahlardan alınır.
- Kuryeler pazara bizzat giderek ürünleri tezgah tezgah toplar.
- Fiyatlar pazar fiyatlarıdır; depo, dağıtım ve raf maliyetleri eklenmez.
- Yerel pazar esnafının dijitalleşmesine katkı sağlar.
- Bağımsız kuryelere esnek çalışma saatleri ve adil gelir modeli sunar.

---

## Hedef Kitle

| Segment | Problem | Çözüm |
|---------|---------|-------|
| **Müşteriler** | Yoğun iş temposu, yaşlılık veya fiziksel kısıtlamalar nedeniyle pazara gidememe | Semt pazarındaki taze ürünleri pazar fiyatıyla evden sipariş etme |
| **Kuryeler** | Esnek saatlerle adil ve şeffaf kazanç arayışı | Müsaitlik kontrolü, mesafe ve ağırlık bazlı kademeli ücretlendirme |
| **Pazar Esnafı** | Müşteri kitlesinin fiziksel olarak pazara gelenlerle sınırlı kalması | Saha çalışanları aracılığıyla tezgah ürünlerini dijital platforma taşıma |

---

## Özellikler

### Müşteri Modülü

- **Konum bazlı pazar keşfi:** Kullanıcının GPS konumu ile yakınındaki aktif semt pazarlarını Haversine formülü ile mesafe hesaplayarak listeler ve sıralar.
- **Kategori sistemi:** Meyve, Sebze, Yeşillik, Peynir ve Süt Ürünleri, Unlu Mamüller, Kahvaltılık ve Reçel ve Bal, Zeytin ve Şarküteri, Kuruyemiş ve Bakliyat, Baharat olmak üzere 9 ana ürün kategorisinde gezinme.
- **Tezgah bazlı karşılaştırma:** Aynı ürün için pazardaki farklı satıcıların (vendor) fiyat, fotoğraf ve kalite puanlarını yan yana inceleme.
- **Sepet yönetimi:** Gramaj (kg) ve adet bazlı ürün ekleme, ürün bazında not bırakma (örneğin "Domatesler sert olsun"), pazar bazlı ayrı sepet tutma.
- **Ödeme öncesi önizleme (Checkout Preview):** Sipariş onayından önce ürün toplamı, kurye ücreti, hizmet komisyonu (%5) ve toplam tutarı şeffaf olarak görme. Tahmini teslimat mesafesini kilometre cinsinden görme.
- **Sipariş durumu takibi:** Siparişin yaşam döngüsünü 7 farklı durumda anlık olarak izleme.
- **Sipariş geçmişi:** Tamamlanmış ve iptal edilmiş tüm geçmiş siparişleri tarih, tutar ve durum bilgileriyle listeleme.
- **Adres yönetimi:** Birden fazla teslimat adresi kaydetme (Ev, İş vb.), varsayılan adres belirleme, enlem/boylam koordinatlarıyla konum saklama.
- **Bildirim sistemi:** Sipariş durumu değişikliklerinde, sistem duyurularında ve promosyonlarda uygulama içi bildirim alma.
- **Profil yönetimi:** Ad, soyad, e-posta, telefon bilgilerini düzenleme.

### Kurye Modülü

- **Müsaitlik kontrolü (Online/Offline toggle):** İstediği zaman müsaitliğini açıp kapatabilme. Pazar seçmeden müsaitlik açılamaz.
- **Kademeli ücret hesaplama:** Taban ücret üzerine mesafe kademeleri ve ağırlık kademeleri ile otomatik çarpan bazlı ücret hesaplama. Her kademe yüzdelik artış veya sabit TL artışı olarak tanımlanabilir.
- **Ürün toplama checklist'i:** Siparişteki her ürünü hangi tezgahtan alacağını gösteren kontrol listesi. Her ürün toplandığında işaretleme. Tüm ürünler işaretlenmeden "Yola Çıktım" butonunun aktifleşmemesi ile eksiksiz teslimat garantisi.
- **Durum geçişleri:** Alışverişe başla → Ürünleri topla → Yola çık → Teslim et adımlarını sıralı olarak ilerletme. Her geçiş sunucuda `OrderStatusHistory` tablosuna kaydedilir.
- **Kazanç paneli:** Toplam kazanç, toplam teslimat sayısı ve ortalama değerlendirme puanı bilgilerini görüntüleme.

### Pazar Çalışanı Modülü

- **Pazar atama sistemi:** Admin tarafından belirli pazarlara atanan çalışanlar, yalnızca sorumlu oldukları pazarlarda veri girişi yapabilir.
- **Tezgah bazlı veri girişi:** Her tezgah için ürün fiyatı, birimi (kg/adet/demet/paket/kasa), kalite puanı ve tezgah konumu bilgisi güncelleme.
- **Fotoğraf yükleme:** Ürün fotoğraflarını doğrudan cihaz kamerasından çekerek veya galeriden seçerek yükleme. Base64 formatında gönderilen fotoğraflar sunucu tarafında işlenir ve depolanır. Desteklenen formatlar: JPEG, PNG, WebP.

### Yönetici (Admin) Modülü

- **Pazar yönetimi:** Yeni pazar tanımlama, pazarın adı, şehir, ilçe, mahalle, tam adres, enlem/boylam koordinatları, çalışma günleri, açılış/kapanış saatleri ve pazar fotoğrafı bilgilerini yönetme.
- **Kullanıcı yönetimi:** Sistemdeki tüm kullanıcıları role göre listeleme, yeni çalışan hesabı oluşturma, hesap aktif/pasif durumunu yönetme.
- **Çalışan atama:** Pazar çalışanlarını belirli pazarlara atama ve atamaları yönetme.
- **İstatistik dashboard:** Toplam sipariş sayısı, sipariş detayları, aktif kurye sayısı, aktif pazar sayısı ve ciro verilerini görüntüleme.

### Ortak Özellikler (Tüm Roller)

- **JWT tabanlı oturum yönetimi:** Access Token (15 dakika) ve Refresh Token (7 gün) ile güvenli kimlik doğrulama. Token yenilemesi Dio interceptor katmanında otomatik olarak gerçekleştirilir.
- **Rol tabanlı yetkilendirme:** Her API endpoint'i `requireRole()` middleware ile korunur. Bir kullanıcı yalnızca kendi rolüne ait işlemleri gerçekleştirebilir.
- **E-posta ve telefon doğrulama altyapısı:** VerificationCode modeli ile SMS ve e-posta doğrulama kodu gönderim/doğrulama altyapısı.
- **Bildirim altyapısı:** Sipariş durumu değişikliklerinde, sistem duyurularında ve promosyonlarda kullanıcılara bildirim gönderme. Bildirimler okundu/okunmadı durumu ile takip edilir.
- **Konum servisleri ve mesafe koruması:** Uygulama, konum verilerini tüm kullanıcı rolleri için aktif olarak kullanır ve mesafe bazlı iş kuralları ile güvenliği sağlar. Müşteriler yalnızca konumlarına yakın olan semt pazarlarından sipariş verebilir; uzak pazarlar listelenmez. Kuryeler yalnızca hizmet verebilecekleri mesafedeki pazarlarda çalışabilir; pazar seçmeden müsaitlik durumunu açamaları sistem tarafından engellenir. Pazar çalışanları yalnızca admin tarafından atandıkları pazarlarda veri girişi yapabilir. Tüm mesafe hesaplamaları Haversine formülü ile gerçek GPS koordinatlarına dayalı olarak yapılır. Konum verileri yalnızca işlevsel amaçlarla kullanılır ve üçüncü taraflarla paylaşılmaz.

---

## Uygulama Akışı

Sipariş yaşam döngüsü aşağıdaki adımlardan oluşur:

```
Aşama 1 — Platform Hazırlığı (Yönetici)
1. Admin        → Sisteme güvenli giriş yapar (şifre + 6 haneli PIN doğrulaması)
2. Admin        → Yeni semt pazarı tanımlar (ad, konum, çalışma günleri, saatleri)
3. Admin        → Pazara tezgahlar (vendor) ekler
4. Admin        → Yeni pazar çalışanı hesabı oluşturur ve ilgili pazara atar
5. Admin        → Yeni kurye hesabı oluşturur

Aşama 2 — Saha Veri Girişi (Pazar Çalışanı)
1. Çalışan      → Atandığı pazarı seçer
2. Çalışan      → Tezgahlardaki ürünleri sisteme ekler (ürün adı, kategori, birim)
3. Çalışan      → Her ürün için güncel fiyat, kalite puanı ve tezgah konumu bilgisi girer
4. Çalışan      → Ürün fotoğraflarını cihaz kamerasından çekerek veya galeriden seçerek yükler
5. Çalışan      → Pazar günlerinde fiyat ve stok bilgilerini güncelleyerek verileri canlı tutar

Aşama 3 — Sipariş Oluşturma (Müşteri)
1. Müşteri      → Konumuna yakın aktif semt pazarlarını görüntüler
2. Müşteri      → Bir pazar seçer, kategorilere göz atar
3. Müşteri      → Ürünleri inceler, farklı tezgahların fiyatlarını karşılaştırır
4. Müşteri      → Ürünleri gramaj veya adet bazında sepete ekler, ürün bazında not bırakır
5. Müşteri      → Sepeti onaylar, teslimat adresini seçer
6. Müşteri      → Ödeme öncesi önizlemede ürün toplamı, kurye ücreti ve hizmet komisyonunu görür
7. Müşteri      → Ödemeyi tamamlar ve siparişi onaylar
                   

Aşama 4 — Sipariş Kabul ve Teslimat (Kurye)
1. Kurye        → Çalışmak istediği pazarı seçer ve müsaitliğini açar (Online)
2. Kurye        → Paneline düşen siparişin detaylarını inceler (ürünler, mesafe, tahmini ücret)
3. Kurye        → Siparişi kabul eder
4. Kurye        → Pazara gider, "Alışverişe Başla" butonuna basar
5. Kurye        → Tezgah konum kartlarını takip ederek ürünleri tezgah tezgah toplar
6. Kurye        → Checklist üzerinde topladığı her ürünü işaretler
7. Kurye        → Tüm ürünler işaretlendiğinde "Yola Çıktım" butonu aktifleşir, basar
8. Kurye        → Müşteriye teslim eder, "Teslim Ettim" butonuna basar ve Teslimat ücreti kurye bakiyesine aktarılır.
```

Her durum geçişi sunucu tarafında `OrderStatusHistory` tablosuna kayıt olarak eklenir. Bu sayede siparişin hangi aşamadan hangi aşamaya, ne zaman geçtiği tam izlenebilirlik (audit trail) ile saklanır.

**Ücretlendirme detayı:**

Sipariş toplam tutarı üç kalemden oluşur:
- **Ürün toplamı (subtotal):** Sepetteki ürünlerin birim fiyat × miktar çarpımlarının toplamı.
- **Kurye ücreti (courierFee):** Kuryenin taban ücreti × mesafe kademesi çarpanı × ağırlık kademesi çarpanı formülü ile hesaplanır.
- **Hizmet komisyonu (serviceFee):** Ürün toplamının %5'i olarak uygulanan platform komisyonu.

---

## Ekran Görüntüleri

### Giriş ve Kayıt Ekranları

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/auth/auth_1.png" width="250"/></td>
    <td align="center"><img src="docs/screenshots/auth/auth_2.png" width="250"/></td>
    <td align="center"><img src="docs/screenshots/auth/auth_3.png" width="250"/></td>
  </tr>
</table>

### Müşteri Ekranları

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/customer/customer_1.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_2.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_3.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/customer/customer_4.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_5.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_6.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/customer/customer_7.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_8.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_9.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/customer/customer_10.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_11.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/customer/customer_12.png" width="220"/></td>
  </tr>
</table>

### Kurye Ekranları

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/courier/courier_1.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_2.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_3.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/courier/courier_4.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_5.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_6.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/courier/courier_7.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_8.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/courier/courier_9.png" width="220"/></td>
  </tr>
</table>

### Pazar Çalışanı Ekranları

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/employee/employee_1.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/employee/employee_2.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/employee/employee_3.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/employee/employee_4.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/employee/employee_5.png" width="220"/></td>
  </tr>
</table>

### Yönetici (Admin) Ekranları

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/admin/admin_1.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/admin/admin_2.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/admin/admin_3.png" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/admin/admin_4.png" width="220"/></td>
    <td align="center"><img src="docs/screenshots/admin/admin_5.png" width="220"/></td>
  </tr>
</table>

---

## Teknoloji Yığını

| Katman | Teknoloji | Açıklama |
|--------|-----------|----------|
| **Mobil Uygulama** | Flutter / Dart | Tek kod tabanıyla Android ve iOS desteği |
| **State Management** | Riverpod | Uygulama genelinde reaktif durum yönetimi |
| **Navigasyon** | GoRouter | Deklaratif ve URL tabanlı sayfa yönlendirme |
| **HTTP İstemci** | Dio | Interceptor desteği, otomatik token yenileme ve hata yönetimi |
| **Backend** | Node.js / Express.js | RESTful API sunucusu |
| **Backend Dili** | TypeScript | Tip güvenli sunucu tarafı geliştirme |
| **ORM** | Prisma | Tip güvenli veritabanı sorgulama, şema yönetimi ve migration |
| **Veritabanı** | MySQL | İlişkisel veritabanı yönetim sistemi |
| **Kimlik Doğrulama** | JWT (JSON Web Token) | Access Token (15 dk) + Refresh Token (7 gün) |
| **Şifreleme** | bcryptjs | Salt round: 12 ile tek yönlü şifre hash'leme |
| **Validasyon** | Zod | İstek gövdesi ve parametre şema doğrulama |
| **Güvenlik** | Helmet | HTTP güvenlik başlıkları (XSS, clickjacking koruması) |
| **Dosya Yükleme** | Multer | Multipart form-data ile dosya yükleme işleme |
| **Dosya Depolama** | Storage Provider (soyutlanmış) | Dosya depolama servisi (yerel veya bulut depolama) |
| **Mesafe Hesaplama** | Haversine Formülü | İki GPS koordinatı arasındaki mesafeyi km cinsinden hesaplama |
| **Benzersiz Kimlik** | UUID v4 | Tüm veritabanı kayıtları için evrensel benzersiz tanımlayıcı |

---

## Mimari Yapı

```
┌────────────────────────────────────────────────────────────┐
│                   Flutter Mobil Uygulama                    │
│                                                            │
│   State: Riverpod  |  Navigasyon: GoRouter  |  HTTP: Dio   │
└──────────────────────────┬─────────────────────────────────┘
                           │
                           │  REST API (JSON over HTTP)
                           │
┌──────────────────────────▼─────────────────────────────────┐
│                 Node.js / Express.js Backend                │
│                                                            │
│   Dil: TypeScript  |  Auth: JWT  |  Validasyon: Zod        │
└──────────────────────────┬─────────────────────────────────┘
                           │
                           │  Prisma ORM
                           │
┌──────────────────────────▼─────────────────────────────────┐
│                     MySQL Veritabanı                        │
│                                                            │
│   17 tablo  |  4 enum  |  İlişkisel model                  │
└────────────────────────────────────────────────────────────┘
```

---

## Veritabanı Yapısı

Veritabanı Prisma şeması ile tanımlanmıştır ve aşağıdaki ana tablolardan oluşur:

| Tablo | Açıklama |
|-------|----------|
| `users` | Tüm kullanıcılar (müşteri, kurye, çalışan, admin). Rol, kimlik ve doğrulama bilgileri. |
| `refresh_tokens` | JWT refresh token kayıtları. |
| `verification_codes` | SMS ve e-posta doğrulama kodları. |
| `addresses` | Kullanıcı teslimat adresleri (başlık, tam adres, koordinatlar). |
| `markets` | Semt pazarları (konum, çalışma günleri, saatleri). |
| `vendors` | Pazardaki tezgahlar/satıcılar. |
| `product_categories` | Ürün kategorileri (9 kategori). |
| `products` | Ürün tanımları (ad, birim, kategori). |
| `vendor_products` | Tezgah-ürün ilişkisi (fiyat, fotoğraf, kalite puanı, tezgah konumu). |
| `courier_profiles` | Kurye profilleri (müsaitlik, bakiye, istatistikler). |
| `courier_distance_tiers` | Kurye mesafe kademeleri. |
| `courier_weight_tiers` | Kurye ağırlık kademeleri. |
| `carts` / `cart_items` | Aktif sepetler ve sepet kalemleri. |
| `orders` / `order_items` | Siparişler ve sipariş kalemleri (toplama checklist durumu dahil). |
| `order_status_history` | Sipariş durum geçiş kayıtları (audit trail). |
| `payments` | Ödeme kayıtları (tutar, durum, sağlayıcı referansı). |
| `notifications` | Uygulama içi bildirimler. |
| `ratings` | Sipariş bazlı değerlendirme ve puanlama. |
| `favorites` | Kullanıcı favori ürünleri. |
| `employee_assignments` | Çalışan-pazar atamaları. |

---

## API Yapısı

Backend 9 modülden oluşan RESTful API sağlar:

| Modül | Base Path | Açıklama |
|-------|-----------|----------|
| **Auth** | `/api/auth` | Kayıt, giriş, token yenileme, şifre işlemleri |
| **Users** | `/api/users` | Kullanıcı profili, hesap yönetimi |
| **Markets** | `/api/markets` | Pazar listeleme, detay, konum bazlı arama |
| **Products** | `/api/products` | Kategori, ürün ve tezgah-ürün yönetimi, fotoğraf yükleme |
| **Cart** | `/api/cart` | Sepet oluşturma, kalem ekleme/güncelleme/silme |
| **Orders** | `/api/orders` | Sipariş oluşturma, durum güncelleme, geçmiş sorgulama |
| **Couriers** | `/api/couriers` | Kurye profili, müsaitlik, ücret kademeleri, kazanç |
| **Admin** | `/api/admin` | Pazar/kullanıcı/çalışan yönetimi, istatistikler |
| **Notifications** | `/api/notifications` | Bildirim listeleme, okundu işaretleme |

---

## Kurulum ve Çalıştırma

### Gereksinimler

- [Node.js](https://nodejs.org/) (v18 veya üzeri)
- [MySQL](https://dev.mysql.com/downloads/) (v8.0 veya üzeri)
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.x)
- [Git](https://git-scm.com/)

### 1. Projeyi klonlayın

```bash
git clone https://github.com/jnost/Pazar_Yap.git
cd Pazar_Yap
```

### 2. Backend kurulumu

```bash
cd backend
npm install
```

Kök dizinde `.env` dosyası oluşturun:

```env
PORT=3000
DATABASE_URL="mysql://root:sifreniz@localhost:3306/pazar_yap"
JWT_SECRET=guclu-bir-jwt-secret-anahtari
JWT_REFRESH_SECRET=guclu-bir-refresh-secret-anahtari
```

Veritabanı tablolarını oluşturun ve başlangıç verilerini yükleyin:

```bash
npx prisma db push
npx prisma db seed
```

Sunucuyu başlatın:

```bash
npx ts-node src/index.ts
```

Sunucu varsayılan olarak `http://localhost:3000` adresinde çalışacaktır.

### 3. Mobil uygulama kurulumu

```bash
cd mobile
flutter pub get
```

Uygulamayı emülatör veya fiziksel cihazda çalıştırın:

```bash
flutter run
```

---

## Proje Yapısı

```
Pazar_Yap/
├── backend/
│   ├── prisma/
│   │   ├── schema.prisma          # Veritabanı şema tanımı
│   │   └── seed.ts                # Başlangıç veri yükleme scripti
│   ├── src/
│   │   ├── index.ts               # Express giriş noktası
│   │   ├── config/                # Veritabanı bağlantı yapılandırması
│   │   ├── middleware/            # Auth, rol kontrolü, validasyon
│   │   ├── modules/               # İş mantığı modülleri
│   │   ├── services/              # Harici servis entegrasyonları
│   │   └── utils/                 # Yardımcı fonksiyonlar
│   ├── package.json
│   └── tsconfig.json
├── mobile/
│   ├── lib/
│   │   ├── main.dart              # Uygulama giriş noktası
│   │   ├── app/                   # Router, tema, uygulama ayarları
│   │   ├── core/                  # Sabitler, API istemcisi, yardımcılar
│   │   ├── features/              # Özellik bazlı modüller
│   │   └── shared/                # Paylaşılan widget'lar
│   └── pubspec.yaml
├── docs/
│   └── screenshots/               # Uygulama ekran görüntüleri
├── .gitignore
├── README.md                        # Türkçe proje dokümantasyonu
├── README_EN.md                     # İngilizce proje dokümantasyonu
└── package-lock.json
```

---

## Güvenlik

- **Şifre saklama:** Kullanıcı şifreleri `bcryptjs` ile hash'lenerek saklanır (salt round: 12).
- **Token tabanlı kimlik doğrulama:** Access Token (15 dk) ve Refresh Token (7 gün) çifti kullanılır.
- **İstek doğrulama:** Tüm API istekleri Zod şemaları ile doğrulanır.
- **HTTP güvenlik başlıkları:** Helmet middleware ile koruma sağlanır.
- **Admin erişim kontrolü:** 6 haneli güvenlik PIN kodu gerektirir.
- **Dosya yükleme güvenliği:** MIME tipi kontrolü (JPEG, PNG, WebP) ve 5 MB boyutu sınırı.
- **Rol bazlı erişim kontrolü:** `requireRole()` middleware ile korunur.

---

## Lisans

Bu proje herhangi bir açık kaynak lisansı altında yayınlanmamıştır. Tüm hakları saklıdır.

---

<p align="center">
  Copyright &copy; 2026 Erdem Özbalta. Tüm hakları saklıdır.<br/>
  <a href="mailto:erdemozbalta@gmail.com">erdemozbalta@gmail.com</a>
</p>

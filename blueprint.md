# Blueprint: Car Launcher Projesi Entegrasyonu

Bu doküman, mevcut Flutter projesine Android araç multimedya sistemleri için tasarlanmış bir "Car Launcher" özelliğinin nasıl entegre edileceğini ana hatlarıyla belirtir. Mevcut ana ekran korunacak ve Car Launcher yeni bir sayfa olarak eklenecektir.

## Genel Bakış

**Amaç:** Google hizmetleri olmayan araç multimedya ekranları için; GPS hız göstergeli, müzik kontrollü, USB destekli ve otomatik başlayan bir ana ekran uygulamasını mevcut Flutter projesine ikinci bir sayfa olarak entegre etmek.

## Mevcut Durum ve Stil

Uygulama, modern ve temiz bir tasarıma sahip bir ana sayfadan oluşmaktadır. Bu ana sayfa korunacaktır. Yeni eklenecek Car Launcher sayfası, kullanıcının sağladığı tasarıma uygun olarak koyu tema ve işlevsel bir arayüze sahip olacaktır.

## Planlanan Değişiklikler

### Adım 1: Bağımlılıkların Eklenmesi
`pubspec.yaml` dosyasına aşağıdaki paketler eklenecektir:
- `permission_handler`: Konum, depolama gibi izinleri yönetmek için.
- `location`: GPS verilerini ve hızı almak için.
- `url_launcher`: Harita uygulamasını (navigasyon) başlatmak için.
- `device_apps`: Cihazda yüklü diğer uygulamaları listelemek için.
- `path_provider`: Cihaz depolama yollarını bularak MP3 dosyalarını aramak için.
- `google_fonts`: Tasarımı güzelleştirmek için.

### Adım 2: Android Platformu Yapılandırması
- **`AndroidManifest.xml` Güncellemesi:**
  - Gerekli izinler eklenecek: `ACCESS_FINE_LOCATION`, `READ_EXTERNAL_STORAGE`, `QUERY_ALL_PACKAGES`, `RECEIVE_BOOT_COMPLETED`.
  - Uygulamanın bir "Launcher" (Ana Ekran) olarak tanınması için `HOME` ve `DEFAULT` kategorilerini içeren intent filtreleri eklenecek.
  - Cihaz açıldığında uygulamayı başlatacak olan `BootReceiver` tanımlanacak.
- **`BootReceiver.kt` Oluşturulması:**
  - `android/app/src/main/kotlin/com/example/myapp/` dizininde, cihaz başladığında `MainActivity`'yi tetikleyecek olan `BootReceiver.kt` dosyası oluşturulacak.
- **Method Channel (Medya Kontrolü):**
  - `MainActivity.kt` içinde, Flutter'dan gönderilen komutları (Play/Pause, Next, Previous) alıp Android sistemine medya tuşu olayı olarak iletecek bir method channel oluşturulacak.

### Adım 3: Car Launcher Arayüzünün Oluşturulması (`lib/car_launcher_screen.dart`)
- Kullanıcının verdiği Jetpack Compose kod örneği, Flutter widget'ları kullanılarak Dart diline çevrilecek.
- `CarLauncherScreen` adında stateful bir widget oluşturulacak. Bu widget, "Ana Ekran", "Uygulamalar" ve "Müzik" görünümleri arasında geçişi yönetecek.
- **Ana Car Launcher Ekranı:**
  - **`TopInfoBar`:** Anlık saati ve `location` paketi ile GPS'ten alınan hızı gösterecek.
  - **`MediaControlPanel`:** Medya kontrolü için oluşturulan method channel'ı kullanarak sisteme evrensel medya komutları gönderecek.
  - **`ActionButtonsPanel`:** `url_launcher` ile harita uygulamasını açacak, müzik ve uygulama ekranlarına dahili yönlendirme yapacak butonları içerecek.
- **Uygulama Çekmecesi Ekranı:** `device_apps` paketini kullanarak cihazdaki yüklü uygulamaları bir grid içinde listeleyecek.
- **USB Müzik Ekranı:** `path_provider` ve `dart:io` kullanarak cihazın depolama alanında `.mp3` uzantılı dosyaları arayıp listeleyecek.

### Adım 4: Projeye Entegrasyon
- Mevcut `lib/main.dart` dosyasındaki ana ekrana, kullanıcıyı yeni oluşturulan `CarLauncherScreen` sayfasına yönlendirecek bir buton veya menü elemanı eklenecek.

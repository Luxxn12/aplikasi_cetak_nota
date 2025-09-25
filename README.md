# Aplikasi Cetak Nota via Bluetooth (Flutter)

Fitur:
- Login sederhana (`admin / admin123`).
- Input Nota dengan item dinamis (tambah/hapus baris).
- Simpan lokal menggunakan Hive (tanggal & waktu tersimpan).
- Rekap harian dengan filter tanggal + detail nota.
- Pratinjau template A6 (landscape) dan cetak ke printer Bluetooth.

Struktur utama kode:
- `lib/models/nota.dart` – Model data dan Hive adapters.
- `lib/services/hive_service.dart` – Inisialisasi dan query Hive.
- `lib/services/bluetooth_service.dart` – Pindai, pilih, koneksi, dan kirim cetak.
- `lib/services/print_service.dart` – Render widget ke PNG (untuk dicetak).
- `lib/ui/login_page.dart`, `lib/ui/nota_form_page.dart`, `lib/ui/recap_page.dart`, `lib/ui/nota_detail_page.dart` – UI.
- `lib/ui/widgets/nota_a6_widget.dart` – Template nota A6 landscape.

Dependensi (lihat `pubspec.yaml`): hive, hive_flutter, intl, path_provider, permission_handler, bluetooth_print, uuid.

Menjalankan proyek:
1. `flutter pub get`
2. Jalankan di Android: `flutter run`

Izin Android (otomatis ditambahkan ke `android/app/src/main/AndroidManifest.xml`):
- `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`, `ACCESS_FINE_LOCATION` (untuk scanning perangkat tertentu).

Langkah pairing & cetak:
1. Pair printer di pengaturan Bluetooth Android terlebih dahulu.
2. Buka aplikasi → Login → Input Nota → Pratinjau.
3. Di halaman pratinjau tekan ikon Bluetooth untuk memilih perangkat.
4. Tekan tombol “Cetak Bluetooth”.

Catatan teknis cetak:
- A6 landscape dirender sebagai widget berukuran tetap lalu di-capture menjadi PNG dan dikirim ke printer Bluetooth (ESC/POS) sebagai gambar, sehingga tata letak presisi (margin, ukuran font, posisi kolom) dapat dijaga.
- Untuk printer 58/80mm, hasil akan diskalakan otomatis oleh perangkat; Anda dapat menyesuaikan parameter `mm` pada `NotaA6Widget` dan `pixelRatio` pada `PrintService.captureToPng` bila perlu.

Error handling:
- Gagal konek/printer tidak ditemukan ditampilkan sebagai `SnackBar`.
- Izin Bluetooth/Lokasi diminta saat pemindaian perangkat.

Dummy data:
- Isi cepat pada form lalu gunakan tombol Pratinjau untuk mencoba cetak tanpa menyimpan.

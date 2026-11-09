# Absensi Mobile

Aplikasi Flutter absensi karyawan BMT Cinde Barokah.

## Menjalankan di browser

Pastikan Google Chrome terpasang, lalu dari folder proyek jalankan:

```powershell
flutter pub get
flutter run -d chrome
```

Jika API Laravel berjalan di alamat selain `http://127.0.0.1:8000/api`, atur
alamatnya saat menjalankan aplikasi:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

## Cara absen

1. Masuk ke akun karyawan.
2. Buka menu **Absen**.
3. Izinkan kamera dan lokasi, lalu pastikan GPS aktif.
4. Ambil foto selfie.
5. Jika lokasi berada dalam radius kantor, tekan **Kirim Absen**.

Absen dilakukan satu kali sehari dan tidak ada absen pulang. Jika tombol kirim
belum aktif, pastikan lokasi sudah ditemukan dan kamu berada di sekitar kantor.

Halaman login dan tampilan aplikasi bisa dicoba di browser. Untuk login dan
absen sungguhan, API harus aktif dan mengizinkan request dari origin aplikasi
(CORS). Fitur kamera dan lokasi juga memerlukan izin browser; browser biasanya
hanya mengizinkannya di `localhost` atau koneksi HTTPS. Pengujian browser tidak
menggantikan pengujian di HP Android, terutama untuk perilaku kamera, GPS, dan
izin perangkat.

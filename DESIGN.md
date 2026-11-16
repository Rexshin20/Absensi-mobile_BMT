# DESIGN.md: Absensi BMT Cinde Barokah

Arah visual untuk aplikasi absensi karyawan BMT Cinde Barokah.
Diturunkan dari sistem yang sudah dipakai di `lib/app_theme.dart`, bukan identitas baru.

## Design Read

Membaca ini sebagai: aplikasi absensi harian untuk karyawan koperasi syariah, dengan bahasa visual rapi seperti buku besar dan stempel waktu, dial ENERGY 2 / RHYTHM 2 / MOTION 1.

- **ENERGY 2**: ramah dan tenang, bukan startup yang berteriak.
- **RHYTHM 2**: pola konsisten, satu-dua komposisi berbeda per layar (kartu absen, strip ringkasan, daftar bergaris).
- **MOTION 1**: hanya transisi pendek dan umpan balik tekan. Jam berjalan karena datanya memang waktu, bukan animasi hiasan.

## Identitas

- Produk: pencatatan kehadiran harian dengan foto selfie dan geofence.
- Pengguna: karyawan BMT, sering membuka aplikasi pagi hari sambil berdiri di depan kantor.
- Karakter: tertib, terpercaya, tidak ramai. Angka waktu harus paling mudah dibaca.

## Palette

| Peran | Warna | Alasan |
|---|---|---|
| Utama | `#087A45` | Hijau BMT yang sudah dipakai di web admin dan aplikasi ini. |
| Identitas gelap | `#075C35` | Latar panel identitas; putih di atasnya lolos kontras WCAG AA. |
| Hijau muda | `#E6F4EC` | Permukaan aksen untuk keadaan berhasil, bukan warna teks. |
| Kertas | `#F4F8F5` | Latar halaman, netral dengan sedikit hijau. |
| Tinta | `#3A3541` | Teks utama. |
| Tinta redup | `#6B6773` | Teks sekunder; tetap di atas 4.5:1 pada kertas. |
| Aksen status | amber `#9A5B00` (terang) / `#F0B34A` (gelap) | Hanya untuk terlambat dan menunggu. |
| Bahaya | merah tema (`#B3261E` terang) | Hanya untuk ditolak dan galat. |

Batas palet: dua hijau brand, satu netral kertas, satu aksen amber. Merah dihitung warna fungsional, bukan bagian palet dekoratif.

## Tipografi

- Inter, alasan: sudah dipakai web admin dan huruf ini punya angka tabular yang rapi untuk jam dan jarak di layar HP kecil.
- Angka waktu dan jumlah memakai `FontFeature.tabularFigures()` supaya tidak bergeser saat berubah.
- Label kecil 11 sampai 12.5 px, judul kartu 15 px, angka utama 21 sampai 40 px.

## Bentuk dan Jarak

- Radius kartu 14, kontrol 10, tombol utama 8. Tidak semua elemen berbentuk pil.
- Garis pemisah 1 px memakai `outline`; ini motif utama, bukan hiasan tambahan.
- Jarak vertikal antar blok 12, di dalam kartu 14 sampai 16.
- Target sentuh minimal 44 px.

## Motif Identitas

**Baris buku besar.** Label kecil redup di atas, angka tabular besar di bawah, dipisah garis tipis. Muncul di strip ringkasan bulanan, daftar riwayat, dan daftar izin. Alasan: aplikasi ini mencatat angka harian, jadi tampilannya mengikuti cara buku absen dibaca.

## Focal Point per Layar

| Layar | Focal point | Alasan |
|---|---|---|
| Beranda | Jam absen hari ini | Pertanyaan pertama pengguna pagi hari: sudah jam berapa dan sudah absen atau belum. |
| Riwayat | Strip ringkasan bulan | Pengguna ingin tahu rekap bulan itu sebelum detail harian. |
| Izin | Daftar pengajuan | Status pengajuan adalah alasan layar ini dibuka. |
| Profil | Identitas karyawan | Konteks siapa yang sedang login sebelum pengaturan lain. |

## Teknik dan Alasan

- **Kaca (blur) di navbar saja**: bilah mengambang perlu tetap terbaca di atas konten yang bergulir tanpa menutupinya dengan blok pekat. Satu elemen saja, sesuai batas dosis.
- **Panel identitas hijau gelap**: membawa identitas BMT dan memisahkan sapaan dari data absen. Tanpa gradien karena gradien tidak menambah hierarki di sini.
- **Garis pemisah, bukan bayangan**: menghindari semua kartu terlihat melayang. Bayangan hanya di navbar.
- **Ikon garis bawaan Material**: relevan per aksi (kamera, izin, riwayat, peta). Bukan untuk hiasan.
- **Tanpa ilustrasi dekoratif**: foto absen asli dan peta nyata sudah menjadi visual produk.

## Larangan Lokal

- Tidak ada em dash di teks aplikasi.
- Tidak ada angka rekap fiktif; semua dari API.
- Tidak ada tombol yang tidak melakukan apa pun.
- Tidak ada warna sebagai satu-satunya penanda status; selalu ada teks.

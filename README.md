# RivNet Offline

RivNet adalah aplikasi Flutter untuk membuat dan mengelola turnamen sepak bola
atau futsal secara lokal. Data turnamen, peserta, dan pertandingan disimpan
menggunakan SQLite, jadi aplikasi tidak membutuhkan koneksi internet untuk
mengelola turnamen.

## Fitur

- Membuat turnamen dengan format gugur, round robin, atau liga.
- Mengelola peserta, pertandingan, hasil, dan klasemen.
- Melihat turnamen aktif dan riwayat turnamen yang sudah selesai.
- Menyesuaikan tata letak untuk ukuran layar ponsel, tablet, dan layar lebar.

## Struktur kode

- `lib/screens/` berisi halaman utama, pembuatan, detail, edit, dan riwayat.
- `lib/widgets/` berisi komponen tampilan yang dipakai ulang.
- `lib/models/` berisi model `Tournament`, `Pertandingan`, dan `KlasemenItem`.
- `lib/database/` mengelola penyimpanan SQLite.
- `lib/routes/` mendefinisikan route bernama yang dipakai GetX.

Widget Stateless digunakan untuk tampilan yang menerima data dari parent.
Stateful digunakan saat halaman perlu mengelola perubahan lokal, misalnya form,
filter, tab, dan skor. `setState` memperbarui state tersebut. Tata letak
responsif memakai `MediaQuery`, `Row`, dan `Column`.

Model turnamen dan pertandingan menyediakan getter, setter, serta
`toMap`/`fromMap` untuk memetakan data antara class dan SQLite. Navigasi halaman
menggunakan named route GetX; halaman atau dialog ditutup dengan `Get.back` atau
`Navigator.pop` sesuai konteksnya.

## Menjalankan aplikasi

Pastikan Flutter SDK sudah terpasang, lalu jalankan:

```sh
flutter pub get
flutter run
```

/// Item data klasemen khusus Sepak Bola / Futsal
class KlasemenItem {
  KlasemenItem({
    required this.idPeserta,
    required this.namaPeserta,
    this.main = 0,
    this.menang = 0,
    this.seri = 0,
    this.kalah = 0,
    this.gm = 0,
    this.gk = 0,
  });

  final String idPeserta;
  final String namaPeserta;
  int main;
  int menang;
  int seri;
  int kalah;
  int gm; // Gol Masuk (Goals For)
  int gk; // Gol Kebobolan (Goals Against)

  int get sg => gm - gk; // Selisih Gol
  int get poin => (menang * 3) + (seri * 1); // Poin: Menang 3, Seri 1, Kalah 0
}

/// Statistik satu peserta dalam klasemen.
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
  int gm;
  int gk;

  int get sg => gm - gk;
  int get poin => (menang * 3) + seri;
}

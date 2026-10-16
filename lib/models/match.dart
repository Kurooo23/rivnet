class Pertandingan {
  Pertandingan({
    required this.id,
    required this.idTurnamen,
    this.idPeserta1,
    this.idPeserta2,
    required this.babak,
    this.leg = 1,
    this._skor1 = 0,
    int skor2 = 0,
    this._penalti1,
    this._penalti2,
    this._status = 'Belum Mulai',
    this.urutan = 0,
    this.nextId,
  }) : _skor2 = skor2;

  final String id;
  final String idTurnamen;
  final String? idPeserta1;
  final String? idPeserta2;
  final String babak;
  final int leg; // 1 atau 2 (Home & Away)
  int _skor1;
  int _skor2;
  int? _penalti1; // hanya terisi kalau imbang dan lanjut adu penalti
  int? _penalti2;
  String _status;
  final int urutan;
  final String? nextId; // pertandingan berikutnya (bagan gugur)

  // ===================== GETTER =====================
  // Baca nilai field private
  int get skor1 => _skor1;
  int get skor2 => _skor2;
  int? get penalti1 => _penalti1;
  int? get penalti2 => _penalti2;
  String get status => _status;

  // ===================== SETTER (dengan validasi) =====================
  // Skor tidak boleh negatif
  set skor1(int val) {
    if (val >= 0) _skor1 = val;
  }

  set skor2(int val) {
    if (val >= 0) _skor2 = val;
  }

  set penalti1(int? val) {
    if (val == null || val >= 0) _penalti1 = val;
  }

  set penalti2(int? val) {
    if (val == null || val >= 0) _penalti2 = val;
  }

  // Status hanya boleh nilai yang valid
  static const _validStatus = ['Belum Mulai', 'Selesai'];
  set status(String val) {
    if (_validStatus.contains(val)) _status = val;
  }

  Map<String, Object?> toMap() => {
    'id_pertandingan': id,
    'id_turnamen': idTurnamen,
    'id_peserta_1': idPeserta1,
    'id_peserta_2': idPeserta2,
    'babak': babak,
    'leg': leg,
    'skor_peserta_1': skor1,
    'skor_peserta_2': skor2,
    'skor_penalti_peserta_1': penalti1,
    'skor_penalti_peserta_2': penalti2,
    'status': status,
    'urutan': urutan,
    'next_pertandingan_id': nextId,
  };

  factory Pertandingan.fromMap(Map<String, Object?> m) => Pertandingan(
    id: m['id_pertandingan'] as String,
    idTurnamen: m['id_turnamen'] as String,
    idPeserta1: m['id_peserta_1'] as String?,
    idPeserta2: m['id_peserta_2'] as String?,
    babak: m['babak'] as String,
    leg: m['leg'] as int,
    skor1: m['skor_peserta_1'] as int,
    skor2: m['skor_peserta_2'] as int,
    penalti1: m['skor_penalti_peserta_1'] as int?,
    penalti2: m['skor_penalti_peserta_2'] as int?,
    status: m['status'] as String,
    urutan: m['urutan'] as int,
    nextId: m['next_pertandingan_id'] as String?,
  );
}

class Tournament {
  Tournament({
    this.id,
    required this.name,
    required this.game,
    required this.date,
    this.deskripsi,
    this.format = 'Single Elimination',
    this.jumlahLeg = 1,
    this.kuota = 4,
    this.peserta = const [],
    this._status = 'Akan Datang',
    bool isFinished = false,
  }) : _isFinished = isFinished;

  String? id; // dibuat saat insert ke database
  final String name;
  final String game;
  final DateTime date;
  final String? deskripsi;
  final String format;
  final int jumlahLeg;
  final int kuota;
  final List<String> peserta;
  String _status;
  bool _isFinished;

  // ===================== GETTER =====================
  String get status => _status;
  bool get isFinished => _isFinished;

  // True kalau format-nya sistem gugur (Single Elimination)
  bool get isKnockout => format == 'Single Elimination';

  // ===================== SETTER (dengan validasi) =====================
  static const _validStatus = ['Akan Datang', 'Berlangsung', 'Selesai'];
  set status(String val) {
    if (_validStatus.contains(val)) _status = val;
  }

  set isFinished(bool val) => _isFinished = val;

  // peserta disimpan di tabel terpisah, jadi tidak ikut di sini
  Map<String, Object?> toMap() => {
    'id_turnamen': id,
    'nama_turnamen': name,
    'deskripsi': deskripsi,
    'tipe_game': game,
    'format_bracket': format,
    'jumlah_leg': jumlahLeg,
    'tanggal_mulai': date.toIso8601String(),
    'kuota': kuota,
    'status': status,
    'is_finished': isFinished ? 1 : 0,
  };

  factory Tournament.fromMap(Map<String, Object?> map, List<String> peserta) {
    return Tournament(
      id: map['id_turnamen'] as String,
      name: map['nama_turnamen'] as String,
      game: map['tipe_game'] as String,
      date: DateTime.parse(map['tanggal_mulai'] as String),
      deskripsi: map['deskripsi'] as String?,
      format: map['format_bracket'] as String,
      jumlahLeg: map['jumlah_leg'] as int,
      kuota: map['kuota'] as int,
      peserta: peserta,
      status: map['status'] as String,
      isFinished: (map['is_finished'] as int) == 1,
    );
  }
}

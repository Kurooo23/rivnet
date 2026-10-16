import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:rivnet/models/match.dart';
import 'package:rivnet/models/tournament.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  static const _dbName = 'rivnet_uts.db';
  static const _dbVersion = 2;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE turnamen (
        id_turnamen    TEXT PRIMARY KEY,
        nama_turnamen  TEXT NOT NULL,
        deskripsi      TEXT,
        tipe_game      TEXT NOT NULL DEFAULT 'Sepak Bola / Futsal',
        format_bracket TEXT NOT NULL,
        jumlah_leg     INTEGER NOT NULL DEFAULT 1,
        tanggal_mulai  TEXT NOT NULL,
        kuota          INTEGER NOT NULL,
        status         TEXT NOT NULL DEFAULT 'Akan Datang',
        is_finished    INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE peserta (
        id_peserta   TEXT PRIMARY KEY,
        id_turnamen  TEXT NOT NULL,
        urutan       INTEGER NOT NULL DEFAULT 0,
        nama_peserta TEXT NOT NULL,
        is_wo        INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (id_turnamen) REFERENCES turnamen(id_turnamen) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pertandingan (
        id_pertandingan        TEXT PRIMARY KEY,
        id_turnamen            TEXT NOT NULL,
        id_peserta_1           TEXT,
        id_peserta_2           TEXT,
        babak                  TEXT NOT NULL,
        leg                    INTEGER NOT NULL DEFAULT 1,
        skor_peserta_1         INTEGER NOT NULL DEFAULT 0,
        skor_peserta_2         INTEGER NOT NULL DEFAULT 0,
        skor_penalti_peserta_1 INTEGER,
        skor_penalti_peserta_2 INTEGER,
        status                 TEXT NOT NULL DEFAULT 'Belum Mulai',
        urutan                 INTEGER NOT NULL DEFAULT 0,
        next_pertandingan_id   TEXT,
        FOREIGN KEY (id_turnamen)  REFERENCES turnamen(id_turnamen) ON DELETE CASCADE,
        FOREIGN KEY (id_peserta_1) REFERENCES peserta(id_peserta) ON DELETE SET NULL,
        FOREIGN KEY (id_peserta_2) REFERENCES peserta(id_peserta) ON DELETE SET NULL
      )
    ''');
  }

  // versi 2: tambah kolom is_wo untuk peserta yang dihapus (walkover)
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE peserta ADD COLUMN is_wo INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

  Future<String> insertTournament(Tournament tournament) async {
    final db = await database;
    final id = _newId('trn');
    tournament.id = id;

    await db.transaction((txn) async {
      await txn.insert('turnamen', tournament.toMap());
      for (var i = 0; i < tournament.peserta.length; i++) {
        await txn.insert('peserta', {
          'id_peserta': '${id}_p$i',
          'id_turnamen': id,
          'urutan': i,
          'nama_peserta': tournament.peserta[i],
        });
      }
    });
    return id;
  }

  Future<List<Tournament>> getTournaments() async {
    final db = await database;
    final rows = await db.query('turnamen', orderBy: 'tanggal_mulai DESC');
    final pesertaRows = await db.query(
      'peserta',
      orderBy: 'id_turnamen, urutan',
    );

    final byTournament = <String, List<String>>{};
    for (final participant in pesertaRows) {
      byTournament
          .putIfAbsent(participant['id_turnamen'] as String, () => [])
          .add(participant['nama_peserta'] as String);
    }

    return [
      for (final row in rows)
        Tournament.fromMap(row, byTournament[row['id_turnamen']] ?? []),
    ];
  }

  Future<void> updateTournament({
    required String id,
    required String name,
    required String? deskripsi,
    required String game,
    required String status,
  }) async {
    final db = await database;
    await db.update(
      'turnamen',
      {
        'nama_turnamen': name,
        'deskripsi': deskripsi,
        'tipe_game': game,
        'status': status,
        'is_finished': status == 'Selesai' ? 1 : 0,
      },
      where: 'id_turnamen = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateStatus(String id, String status) async {
    final db = await database;
    await db.update(
      'turnamen',
      {'status': status, 'is_finished': status == 'Selesai' ? 1 : 0},
      where: 'id_turnamen = ?',
      whereArgs: [id],
    );
  }

  Future<void> markFinished(String id) async {
    final db = await database;
    await db.update(
      'turnamen',
      {'is_finished': 1, 'status': 'Selesai'},
      where: 'id_turnamen = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteTournament(String id) async {
    final db = await database;
    await db.delete('turnamen', where: 'id_turnamen = ?', whereArgs: [id]);
  }

  Future<List<Map<String, Object?>>> getPeserta(String idTurnamen) async {
    final db = await database;
    return db.query(
      'peserta',
      where: 'id_turnamen = ?',
      whereArgs: [idTurnamen],
      orderBy: 'urutan',
    );
  }

  // Menambah satu peserta, kuota ikut naik, dan jadwal lama dihapus
  // supaya dibuat ulang dengan jumlah peserta yang baru.
  Future<void> addPeserta(String idTurnamen, String nama) async {
    final db = await database;

    await db.transaction((txn) async {
      final result = await txn.rawQuery(
        'SELECT MAX(urutan) AS terakhir FROM peserta WHERE id_turnamen = ?',
        [idTurnamen],
      );
      final urutan = ((result.first['terakhir'] as int?) ?? -1) + 1;

      await txn.insert('peserta', {
        'id_peserta': '${idTurnamen}_p$urutan',
        'id_turnamen': idTurnamen,
        'urutan': urutan,
        'nama_peserta': nama,
      });
      await txn.rawUpdate(
        'UPDATE turnamen SET kuota = kuota + 1 WHERE id_turnamen = ?',
        [idTurnamen],
      );
      await txn.delete(
        'pertandingan',
        where: 'id_turnamen = ?',
        whereArgs: [idTurnamen],
      );
    });
  }

  Future<void> renamePeserta(String idPeserta, String nama) async {
    final db = await database;
    await db.update(
      'peserta',
      {'nama_peserta': nama},
      where: 'id_peserta = ?',
      whereArgs: [idPeserta],
    );
  }

  // peserta tidak benar-benar dihapus, hanya ditandai WO
  // supaya nama lawan di riwayat laga tetap ada
  Future<void> setPesertaWo(String idPeserta) async {
    final db = await database;
    await db.update(
      'peserta',
      {'is_wo': 1},
      where: 'id_peserta = ?',
      whereArgs: [idPeserta],
    );
  }

  Future<List<Pertandingan>> getMatches(String idTurnamen) async {
    final db = await database;
    final rows = await db.query(
      'pertandingan',
      where: 'id_turnamen = ?',
      whereArgs: [idTurnamen],
      orderBy: 'urutan, leg',
    );
    return [for (final row in rows) Pertandingan.fromMap(row)];
  }

  Future<void> insertMatches(List<Pertandingan> matches) async {
    final db = await database;
    final batch = db.batch();
    for (final match in matches) {
      batch.insert('pertandingan', match.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<void> saveScore(
    String idPertandingan, {
    required int skor1,
    required int skor2,
    int? penalti1,
    int? penalti2,
  }) async {
    final db = await database;
    await db.update(
      'pertandingan',
      {
        'skor_peserta_1': skor1,
        'skor_peserta_2': skor2,
        'skor_penalti_peserta_1': penalti1,
        'skor_penalti_peserta_2': penalti2,
        'status': 'Selesai',
      },
      where: 'id_pertandingan = ?',
      whereArgs: [idPertandingan],
    );
  }

  // slot 1 = id_peserta_1, slot 2 = id_peserta_2
  Future<void> setPeserta(
    String idPertandingan,
    int slot,
    String idPeserta,
  ) async {
    final db = await database;
    await db.update(
      'pertandingan',
      {'id_peserta_$slot': idPeserta},
      where: 'id_pertandingan = ?',
      whereArgs: [idPertandingan],
    );
  }

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

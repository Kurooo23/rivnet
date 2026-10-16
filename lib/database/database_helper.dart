import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/match.dart';
import '../models/tournament.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  static const _dbName = 'rivnet_uts.db';
  static const _dbVersion = 1;

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

  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

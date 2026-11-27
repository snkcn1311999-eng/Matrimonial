import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;

  static Future<void> _createPhotos(Database d) async {
    await d.execute('''
      CREATE TABLE IF NOT EXISTS photos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        profile_id INTEGER NOT NULL,
        file TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        created_at TEXT
      )
    ''');
    await d.execute(
        'CREATE INDEX IF NOT EXISTS idx_photo_profile ON photos(profile_id)');
  }

  static Future<Database> get db async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'matrimonial.db');
    _db = await openDatabase(
      path,
      version: 2,
      onCreate: (d, v) async {
        await d.execute('''
          CREATE TABLE profiles(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id TEXT UNIQUE,
            name TEXT NOT NULL,
            gender TEXT,
            dob TEXT,
            mobile TEXT,
            district TEXT,
            status TEXT DEFAULT 'active',
            created_at TEXT,
            data TEXT
          )
        ''');
        await d.execute('CREATE INDEX idx_name ON profiles(name)');
        await d.execute('CREATE INDEX idx_mobile ON profiles(mobile)');
        await _createPhotos(d);
      },
      onUpgrade: (d, oldV, newV) async {
        if (oldV < 2) await _createPhotos(d);
      },
    );
    return _db!;
  }

  static Future<int> insert(Map<String, dynamic> p) async {
    final d = await db;
    final n = Sqflite.firstIntValue(
            await d.rawQuery('SELECT COALESCE(MAX(id),0)+1 FROM profiles')) ??
        1;
    p['profile_id'] = 'MT${n.toString().padLeft(4, '0')}';
    p['created_at'] = DateTime.now().toIso8601String();
    return d.insert('profiles', p);
  }

  static Future<Map<String, dynamic>?> findByMobile(String mobile) async {
    final d = await db;
    final r = await d.query('profiles',
        where: 'mobile = ?', whereArgs: [mobile], limit: 1);
    return r.isEmpty ? null : r.first;
  }

  static Future<List<Map<String, dynamic>>> list(
      {String query = '', bool recentOnly = false}) async {
    final d = await db;
    final where = <String>[];
    final args = <Object?>[];
    if (query.trim().isNotEmpty) {
      where.add('(p.name LIKE ? OR p.profile_id LIKE ? OR p.mobile LIKE ?)');
      final q = '%${query.trim()}%';
      args.addAll([q, q, q]);
    }
    if (recentOnly) {
      where.add('p.created_at >= ?');
      args.add(DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String());
    }
    final sql = '''
      SELECT p.*,
        (SELECT file FROM photos WHERE profile_id = p.id
          ORDER BY sort_order, id LIMIT 1) AS main_photo
      FROM profiles p
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY p.id DESC
    ''';
    return d.rawQuery(sql, args);
  }

  // Deletes the profile and its photo rows; returns the photo file names
  // so the caller can remove the files from storage.
  static Future<List<String>> delete(int id) async {
    final d = await db;
    final r = await d.query('photos',
        columns: ['file'], where: 'profile_id = ?', whereArgs: [id]);
    await d.delete('photos', where: 'profile_id = ?', whereArgs: [id]);
    await d.delete('profiles', where: 'id = ?', whereArgs: [id]);
    return r.map((e) => e['file'] as String).toList();
  }

  static Future<void> addPhoto(int profileId, String file) async {
    final d = await db;
    final n = Sqflite.firstIntValue(await d.rawQuery(
            'SELECT COALESCE(MAX(sort_order),0)+1 FROM photos WHERE profile_id = ?',
            [profileId])) ??
        1;
    await d.insert('photos', {
      'profile_id': profileId,
      'file': file,
      'sort_order': n,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> photos(int profileId) async {
    final d = await db;
    return d.query('photos',
        where: 'profile_id = ?',
        whereArgs: [profileId],
        orderBy: 'sort_order, id');
  }

  static Future<void> deletePhoto(int photoId) async {
    final d = await db;
    await d.delete('photos', where: 'id = ?', whereArgs: [photoId]);
  }

  static Future<void> makeMain(int profileId, int photoId) async {
    final d = await db;
    final m = Sqflite.firstIntValue(await d.rawQuery(
            'SELECT COALESCE(MIN(sort_order),0)-1 FROM photos WHERE profile_id = ?',
            [profileId])) ??
        -1;
    await d.update('photos', {'sort_order': m},
        where: 'id = ?', whereArgs: [photoId]);
  }

  static Future<Map<String, int>> stats() async {
    final d = await db;
    Future<int> c(String where, [List<Object?>? args]) async {
      final sql =
          'SELECT COUNT(*) FROM profiles ${where.isEmpty ? '' : 'WHERE $where'}';
      return Sqflite.firstIntValue(await d.rawQuery(sql, args)) ?? 0;
    }

    final weekAgo = DateTime.now()
        .subtract(const Duration(days: 7))
        .toIso8601String();
    return {
      'total': await c(''),
      'male': await c("gender = 'male'"),
      'female': await c("gender = 'female'"),
      'newly': await c('created_at >= ?', [weekAgo]),
      'married': await c("status = 'married'"),
      'pending': await c("status = 'pending'"),
    };
  }
}

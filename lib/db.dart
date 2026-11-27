import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDb {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    final path = join(await getDatabasesPath(), 'matrimonial.db');
    _db = await openDatabase(
      path,
      version: 1,
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
      where.add('(name LIKE ? OR profile_id LIKE ? OR mobile LIKE ?)');
      final q = '%${query.trim()}%';
      args.addAll([q, q, q]);
    }
    if (recentOnly) {
      where.add('created_at >= ?');
      args.add(DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String());
    }
    return d.query(
      'profiles',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'id DESC',
    );
  }

  static Future<void> delete(int id) async {
    final d = await db;
    await d.delete('profiles', where: 'id = ?', whereArgs: [id]);
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

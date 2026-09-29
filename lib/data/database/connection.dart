// =============================================================================
// فتح اتصال قاعدة البيانات على الجهاز.
//
// تحسينات الأداء المطبقة هنا:
// - Isolate خلفي: كل استعلامات SQLite تعمل خارج خيط الواجهة (UI thread)
//   فلا يحدث تقطيع (jank) أثناء التمرير مهما كبرت البيانات.
// - WAL mode: القراءة والكتابة لا تحجب بعضها، والكتابة أسرع.
// - synchronous=NORMAL: آمن مع WAL وأسرع من FULL.
// =============================================================================

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:sqlite3/common.dart';

import 'app_database.dart';

/// اسم ملف قاعدة البيانات داخل مجلد مستندات التطبيق (daftry.sqlite).
const kDatabaseName = 'daftry';

/// يُنفَّذ داخل الـ Isolate الخلفي عند فتح الملف (يجب أن تكون دالة عامة).
void _setupSqlite(CommonDatabase db) {
  db.execute('PRAGMA journal_mode = WAL;');
  db.execute('PRAGMA synchronous = NORMAL;');
  db.execute('PRAGMA foreign_keys = ON;');
}

/// يفتح قاعدة بيانات التطبيق الحقيقية على الجهاز.
AppDatabase openAppDatabase() {
  final QueryExecutor executor = driftDatabase(
    name: kDatabaseName,
    native: const DriftNativeOptions(setup: _setupSqlite),
  );
  return AppDatabase(executor);
}

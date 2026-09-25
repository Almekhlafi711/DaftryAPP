// =============================================================================
// نقطة دخول تطبيق «دفتري».
//
// هيكل المشروع (الطبقات منفصلة — كل طبقة تعتمد على التي تحتها فقط):
//   lib/core      → أدوات عامة (المبالغ، التواريخ، الأخطاء، العملات)
//   lib/domain    → الأنواع والنماذج (Enums / Models)
//   lib/data      → قاعدة البيانات المحلية (Drift + SQLite)      ← «الباك إند»
//   lib/services  → منطق العمل وقواعده + حقن التبعيات             ← «الباك إند»
//   lib/ui        → الواجهات فقط: الثيم، المكونات، الشاشات        ← «التصميم»
//   lib/l10n      → النصوص بالعربية والإنجليزية
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/database/connection.dart';
import 'services/providers.dart';
import 'ui/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // قاعدة البيانات تُفتح مرة واحدة طوال عمر التطبيق (في Isolate خلفي).
  final database = openAppDatabase();

  runApp(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const DaftryApp(),
    ),
  );
}

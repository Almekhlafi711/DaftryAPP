// أداة توليد لقطات شاشة بالخطوط الحقيقية (ليست اختباراً دائماً).
// التشغيل: flutter test test/screenshots --update-goldens
@Tags(['screenshots'])
library;

import 'dart:io';

import 'package:daftry/data/database/app_database.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/services/providers.dart';
import 'package:daftry/services/settings_service.dart';
import 'package:daftry/ui/app.dart';
import 'package:daftry/ui/router/routes.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../ui/all_screens_render_test.dart' show seed;

Future<void> _loadFonts() async {
  final plex = FontLoader('IBMPlexSansArabic');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    plex.addFont(rootBundle.load('assets/fonts/IBMPlexSansArabic-$w.ttf'));
  }
  await plex.load();
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/opt/flutter';
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(
        ByteData.sublistView(
          File(
            '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
          ).readAsBytesSync(),
        ),
      ),
    );
  await icons.load();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
    await _loadFonts();
  });

  final shots = <(String, String, bool, bool)>[
    ('home_ar', AppRoutes.home, true, false),
    ('add_tx_ar', AppRoutes.newTransaction(), true, false),
    ('transactions_ar', AppRoutes.transactions, true, false),
    ('debts_ar', AppRoutes.debts, true, false),
    ('person_ar', AppRoutes.person(1), true, false),
    ('statement_ar', AppRoutes.personStatement(1), true, false),
    ('new_debt_ar', AppRoutes.newDebt(), true, false),
    ('reports_ar', AppRoutes.reports, true, false),
    ('budget_ar', AppRoutes.budget, true, false),
    ('accounts_ar', AppRoutes.accounts, true, false),
    ('settings_ar', AppRoutes.more, true, false),
    ('home_en', AppRoutes.home, false, false),
    ('home_ar_dark', AppRoutes.home, true, true),
  ];

  for (final (name, route, arabic, dark) in shots) {
    testWidgets(name, (tester) async {
      driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
      );
      addTearDown(db.close);
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        await seed(db, arabic: arabic);
        if (dark) await SettingsService(db).set(SettingKeys.themeMode, 'dark');
        // مصروفات إضافية لتظهر الرسوم البيانية بشكل واقعي.
        final cats = await (db.select(
          db.categories,
        )..where((c) => c.kind.equals(CategoryKind.expense.name))).get();
        final cash = await (db.select(db.accounts)..limit(1)).getSingle();
        for (var m = 0; m < 6; m++) {
          for (var i = 0; i < 4; i++) {
            await db
                .into(db.transactions)
                .insert(
                  TransactionsCompanion.insert(
                    type: TxType.expense,
                    amount: 15000 + (m * 7 + i * 13) % 9 * 12000,
                    currencyId: 1,
                    accountId: cash.id,
                    categoryId: Value(cats[i].id),
                    date: DateTime(
                      DateTime.now().year,
                      DateTime.now().month - m,
                      3 + i,
                    ),
                  ),
                );
          }
          await db
              .into(db.transactions)
              .insert(
                TransactionsCompanion.insert(
                  type: TxType.income,
                  amount: 1200000,
                  currencyId: 1,
                  accountId: cash.id,
                  categoryId: Value(
                    (await (db.select(db.categories)
                              ..where(
                                (c) => c.kind.equals(CategoryKind.income.name),
                              )
                              ..limit(1))
                            .getSingle())
                        .id,
                  ),
                  date: DateTime(
                    DateTime.now().year,
                    DateTime.now().month - m,
                    1,
                  ),
                ),
              );
        }
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [databaseProvider.overrideWithValue(db)],
          child: const DaftryApp(),
        ),
      );
      await tester.pumpAndSettle();
      ProviderScope.containerOf(tester.element(find.byType(DaftryApp)))
          .read(routerProvider)
          .go(route);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('out/$name.png'),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

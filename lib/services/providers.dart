// =============================================================================
// حقن التبعيات (Dependency Injection) عبر Riverpod.
//
// هذا الملف هو «لوحة التوصيل» بين الطبقات: يعرّف كيف تُنشأ كل خدمة وما
// تحتاجه. الواجهة تطلب الخدمة بـ ref.read(xServiceProvider) ولا تنشئها بنفسها،
// وفي الاختبارات يمكن استبدال أي خدمة بـ ProviderScope(overrides: ...).
// =============================================================================

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/database/app_database.dart';
import '../domain/enums.dart';
import 'account_service.dart';
import 'backup/backup_service.dart';
import 'backup/cloud_provider.dart';
import 'backup/google_drive_provider.dart';
import 'backup/icloud_provider.dart';
import 'budget_service.dart';
import 'category_service.dart';
import 'contact_service.dart';
import 'debt_service.dart';
import 'export/file_share_service.dart';
import 'external_link_service.dart';
import 'notification_service.dart';
import 'report_service.dart';
import 'security_service.dart';
import 'settings_service.dart';
import 'statement_service.dart';
import 'transaction_service.dart';

/// قاعدة البيانات — تُنشأ في main.dart وتُمرَّر عبر overrides.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider must be overridden'),
);

final settingsServiceProvider = Provider(
  (ref) => SettingsService(ref.watch(databaseProvider)),
);

final accountServiceProvider = Provider(
  (ref) => AccountService(ref.watch(databaseProvider)),
);

final categoryServiceProvider = Provider(
  (ref) => CategoryService(ref.watch(databaseProvider)),
);

final contactServiceProvider = Provider(
  (ref) => ContactService(ref.watch(databaseProvider)),
);

final budgetServiceProvider = Provider(
  (ref) => BudgetService(ref.watch(databaseProvider)),
);

final transactionServiceProvider = Provider(
  (ref) => TransactionService(
    ref.watch(databaseProvider),
    ref.watch(budgetServiceProvider),
  ),
);

final notificationServiceProvider = Provider((ref) => NotificationService());

final debtServiceProvider = Provider(
  (ref) => DebtService(
    ref.watch(databaseProvider),
    reminders: ref.watch(notificationServiceProvider),
  ),
);

final reportServiceProvider = Provider(
  (ref) => ReportService(ref.watch(databaseProvider)),
);

final statementServiceProvider = Provider(
  (ref) => StatementService(ref.watch(databaseProvider)),
);

final securityServiceProvider = Provider((ref) => SecurityService());

final fileShareServiceProvider = Provider((ref) => const FileShareService());

final externalLinkServiceProvider = Provider(
  (ref) => const ExternalLinkService(),
);

/// معرّف Google OAuth (Web client) يُمرَّر وقت البناء:
/// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

/// مزوّدو السحابة المتاحون.
final cloudProvidersProvider = Provider<Map<BackupProvider, CloudProvider>>(
  (ref) => {
    BackupProvider.googleDrive: GoogleDriveProvider(
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    ),
    BackupProvider.iCloud: ICloudProvider(),
  },
);

final backupServiceProvider = Provider(
  (ref) => BackupService(
    db: ref.watch(databaseProvider),
    settings: ref.watch(settingsServiceProvider),
    secrets: ref.watch(securityServiceProvider).store,
    tempDirectory: getTemporaryDirectory,
    providers: ref.watch(cloudProvidersProvider),
    isOnWifi: () async => (await Connectivity().checkConnectivity()).contains(
      ConnectivityResult.wifi,
    ),
  ),
);

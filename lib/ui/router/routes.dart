// =============================================================================
// خريطة التنقل (الشكلان 4-1 و 4-2 في الوثيقة).
//
// - أربعة تبويبات بشريط سفلي: الرئيسية، المعاملات، الديون، المزيد.
//   كل تبويب يحتفظ بحالته عند التنقل (StatefulShellRoute.indexedStack).
// - الشاشات الفرعية (إضافة معاملة، ملف الشخص، كشف الحساب، الحسابات،
//   التقارير، الميزانية، الفئات، النسخ، القفل) تُفتح بـ push فوق الشريط
//   السفلي، فيعود زر الرجوع دائماً إلى الصفحة السابقة نفسها.
// - زر الرجوع في التبويبات يعود إلى «الرئيسية»، وفيها يُطلب ضغطه مرتين للخروج
//   (انظر [MainShell]).
// - إن لم يكتمل الإعداد الأول يُعاد التوجيه تلقائياً إلى شاشة اختيار العملة.
//
// لإضافة شاشة: أضف مساراً في [AppRoutes] ثم GoRoute في [routerProvider].
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/enums.dart';
import '../features/accounts/accounts_screen.dart';
import '../features/backup/backup_screen.dart';
import '../features/budget/budget_screen.dart';
import '../features/categories/categories_screen.dart';
import '../features/debts/contact_form_screen.dart';
import '../features/debts/debt_form_screen.dart';
import '../features/debts/debts_screen.dart';
import '../features/debts/person_profile_screen.dart';
import '../features/debts/statement_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/security/security_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/shell/main_shell.dart';
import '../features/transactions/transaction_form_screen.dart';
import '../features/transactions/transactions_screen.dart';
import '../state/app_state.dart';

/// كل مسارات التطبيق في مكان واحد (لا نكتب نصوص المسارات داخل الشاشات).
abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const transactions = '/transactions';
  static const debts = '/debts';
  static const more = '/more';

  // صفحات فرعية تُفتح دائماً بـ context.push (لا go) ليعمل الرجوع خطوة بخطوة.
  static const accounts = '/accounts';
  static const reports = '/reports';
  static const budget = '/budget';
  static const categories = '/categories';
  static const backup = '/backup';
  static const security = '/security';

  static String newTransaction([TxType type = TxType.expense]) =>
      '/tx/new?type=${type.name}';
  static String editTransaction(int id) => '/tx/$id';

  static String newDebt({int? contactId}) =>
      contactId == null ? '/debt/new' : '/debt/new?contact=$contactId';
  static String editDebt(int id) => '/debt/$id/edit';

  static const newPerson = '/person/new';
  static String person(int id) => '/person/$id';
  static String personStatement(int id) => '/person/$id/statement';
  static String editPerson(int id) => '/person/$id/edit';
}

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  // نراقب حالة الإعداد الأول لإعادة التوجيه تلقائياً (مثلاً بعد «حذف كل البيانات»).
  final onboarded = ValueNotifier<bool>(
    ref.read(preferencesProvider).value?.onboarded ?? false,
  );
  ref.listen(preferencesProvider, (_, next) {
    final value = next.value?.onboarded;
    if (value != null) onboarded.value = value;
  });
  ref.onDispose(onboarded.dispose);

  int? idParam(GoRouterState s, String name) =>
      int.tryParse(s.pathParameters[name] ?? '');

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.home,
    refreshListenable: onboarded,
    redirect: (context, state) {
      final atOnboarding = state.matchedLocation == AppRoutes.onboarding;
      if (!onboarded.value && !atOnboarding) return AppRoutes.onboarding;
      if (onboarded.value && atOnboarding) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),

      // ---------------- التبويبات الأربعة مع الشريط السفلي ----------------
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.transactions,
                builder: (_, _) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.debts,
                builder: (_, _) => const DebtsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (_, _) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ---------------- شاشات كاملة فوق الشريط السفلي ----------------
      for (final (path, screen) in const <(String, Widget)>[
        (AppRoutes.accounts, AccountsScreen()),
        (AppRoutes.reports, ReportsScreen()),
        (AppRoutes.budget, BudgetScreen()),
        (AppRoutes.categories, CategoriesScreen()),
        (AppRoutes.backup, BackupScreen()),
        (AppRoutes.security, SecurityScreen()),
      ])
        GoRoute(
          parentNavigatorKey: _rootKey,
          path: path,
          builder: (_, _) => screen,
        ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/tx/new',
        pageBuilder: (_, s) => MaterialPage(
          fullscreenDialog: true,
          child: TransactionFormScreen(
            initialType: TxType.values.firstWhere(
              (t) => t.name == s.uri.queryParameters['type'],
              orElse: () => TxType.expense,
            ),
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/tx/:id',
        builder: (_, s) =>
            TransactionFormScreen(transactionId: idParam(s, 'id')),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/debt/new',
        pageBuilder: (_, s) => MaterialPage(
          fullscreenDialog: true,
          child: DebtFormScreen(
            contactId: int.tryParse(s.uri.queryParameters['contact'] ?? ''),
          ),
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/debt/:id/edit',
        builder: (_, s) => DebtFormScreen(debtId: idParam(s, 'id')),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: AppRoutes.newPerson,
        builder: (_, _) => const ContactFormScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/person/:id',
        builder: (_, s) => PersonProfileScreen(contactId: idParam(s, 'id')!),
        routes: [
          GoRoute(
            path: 'statement',
            builder: (_, s) => StatementScreen(contactId: idParam(s, 'id')!),
          ),
          GoRoute(
            path: 'edit',
            builder: (_, s) => ContactFormScreen(contactId: idParam(s, 'id')),
          ),
        ],
      ),
    ],
  );
});

// =============================================================================
// مزوّدات البيانات المشتركة بين أكثر من شاشة (تدفقات تفاعلية من الخدمات).
// كل مزوّد هنا «رفيع»: يربط الواجهة بدالة watch في طبقة الخدمات فقط،
// ويُلغى تلقائياً (autoDispose) عند مغادرة الشاشة لتوفير الذاكرة.
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/date_range.dart';
import '../../data/database/app_database.dart';
import '../../domain/enums.dart';
import '../../domain/models/budget_report_models.dart';
import '../../domain/models/debt_models.dart';
import '../../domain/models/transaction_models.dart';
import '../../services/providers.dart';

/// إجمالي أرصدة الحسابات النشطة.
final totalBalanceProvider = StreamProvider.autoDispose<int>(
  (ref) => ref.watch(accountServiceProvider).watchTotalBalance(),
);

/// دخل ومصروف الشهر الحالي.
final monthTotalsProvider = StreamProvider.autoDispose<PeriodTotals>(
  (ref) => ref
      .watch(transactionServiceProvider)
      .watchTotals(DateRange.month(DateTime.now())),
);

/// آخر المعاملات للرئيسية.
final recentTransactionsProvider =
    StreamProvider.autoDispose<List<TransactionView>>(
      (ref) => ref.watch(transactionServiceProvider).watchRecent(limit: 5),
    );

/// ملخص ميزانيات الشهر الحالي.
final budgetOverviewProvider = StreamProvider.autoDispose<BudgetOverview>(
  (ref) => ref.watch(budgetServiceProvider).watchOverview(DateTime.now()),
);

/// مجموع «لي» و«عليّ».
final debtTotalsProvider = StreamProvider.autoDispose<DebtTotals>(
  (ref) => ref.watch(debtServiceProvider).watchTotals(),
);

/// فئات نوع معيّن (للإضافة والفلترة والميزانية).
final categoriesByKindProvider = StreamProvider.autoDispose
    .family<List<Category>, CategoryKind>(
      (ref, kind) => ref.watch(categoryServiceProvider).watchByKind(kind),
    );

/// فئات شاشة المعاملة (دون فئتي المسامحة والإعفاء الخاصتين بالديون).
final transactionCategoriesProvider = StreamProvider.autoDispose
    .family<List<Category>, CategoryKind>(
      (ref, kind) => ref
          .watch(categoryServiceProvider)
          .watchByKind(kind, forTransactions: true),
    );

/// الأشخاص غير المؤرشفين (لاختيار شخص عند تسجيل دين).
final contactsProvider = StreamProvider.autoDispose<List<Contact>>(
  (ref) => ref.watch(contactServiceProvider).watchActive(),
);

/// الملف المالي لشخص.
final personProfileProvider = StreamProvider.autoDispose
    .family<PersonProfile?, int>(
      (ref, id) => ref.watch(debtServiceProvider).watchProfile(id),
    );

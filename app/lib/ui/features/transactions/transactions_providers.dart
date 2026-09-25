// =============================================================================
// حالة شاشة سجل المعاملات: الفلتر الحالي، وعدد العناصر المحمّلة (تحميل تدريجي).
// =============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_range.dart';
import '../../../domain/models/transaction_models.dart';
import '../../../services/providers.dart';
import '../../state/app_state.dart';

/// الفلتر الحالي (الافتراضي: هذا الشهر).
class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  static TransactionFilter get initial =>
      TransactionFilter(range: DateRange.month(DateTime.now()));

  @override
  TransactionFilter build() => initial;

  void set(TransactionFilter filter) {
    state = filter;
    ref.read(transactionPageSizeProvider.notifier).reset();
  }

  void search(String query) => set(state.copyWith(query: query));

  void reset() => set(initial.copyWith(query: state.query));
}

final transactionFilterProvider =
    NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
      TransactionFilterNotifier.new,
    );

/// عدد العناصر المعروضة؛ يزيد عند الاقتراب من نهاية القائمة.
/// نجلب دفعات صغيرة بدل آلاف المعاملات دفعة واحدة — أسرع وأخف على الذاكرة.
class PageSizeNotifier extends Notifier<int> {
  static const pageSize = 60;

  @override
  int build() => pageSize;

  void more() => state += pageSize;

  void reset() => state = pageSize;
}

final transactionPageSizeProvider = NotifierProvider<PageSizeNotifier, int>(
  PageSizeNotifier.new,
);

/// نتائج السجل حسب الفلتر.
final filteredTransactionsProvider =
    StreamProvider.autoDispose<List<TransactionView>>((ref) {
      final filter = ref.watch(transactionFilterProvider);
      final limit = ref.watch(transactionPageSizeProvider);
      final factor = ref.watch(moneyParserProvider).factor;
      return ref
          .watch(transactionServiceProvider)
          .watchFiltered(filter, limit: limit, amountFactor: factor);
    });

/// ملخص الدخل والمصروف لفترة الفلتر (حركات الديون مستبعدة دائماً).
final filteredTotalsProvider = StreamProvider.autoDispose<PeriodTotals>((ref) {
  final range =
      ref.watch(transactionFilterProvider.select((f) => f.range)) ??
      DateRange(DateTime(2000), DateTime(2100));
  return ref.watch(transactionServiceProvider).watchTotals(range);
});

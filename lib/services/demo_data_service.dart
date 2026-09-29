// =============================================================================
// بيانات تجريبية للاختبارات الآلية (لا تظهر في واجهة التطبيق).
//
// تملأ التطبيق ببيانات ستة أشهر واقعية عبر الخدمات نفسها (وليس SQL مباشرة)،
// فتبقى الأرصدة والحالات متسقة تماماً مع قواعد العمل:
// - حسابان إضافيان (بنكي ومحفظة) ودخل شهري ومصروفات متنوعة وتحويلات.
// - ميزانيات لأربع فئات (إحداها قريبة من التجاوز).
// - أشخاص بديون: مفتوح بدفعة جزئية، بيع بالآجل، دين «عليّ» متأخر، ودين مسدَّد.
// =============================================================================

import 'dart:math';

import '../core/money/money.dart';
import '../data/database/app_database.dart';
import '../data/seed/default_categories.dart';
import '../domain/enums.dart';
import '../domain/models/debt_models.dart';
import '../domain/models/transaction_models.dart';
import 'account_service.dart';
import 'budget_service.dart';
import 'category_service.dart';
import 'contact_service.dart';
import 'debt_service.dart';
import 'transaction_service.dart';

class DemoDataService {
  DemoDataService({
    required this.db,
    required this.accounts,
    required this.transactions,
    required this.budgets,
    required this.contacts,
    required this.debts,
  });

  final AppDatabase db;
  final AccountService accounts;
  final TransactionService transactions;
  final BudgetService budgets;
  final ContactService contacts;
  final DebtService debts;

  /// يُحمّل البيانات. [arabic] لأسماء الحسابات والأشخاص. [now] للاختبارات.
  Future<void> load({required bool arabic, DateTime? now}) async {
    final today = now ?? DateTime.now();
    final currency = (await db.baseCurrency())!;
    final factor = MoneyParser(currency.decimals).factor;
    int money(num major) => (major * factor).round();
    String t(String ar, String en) => arabic ? ar : en;
    // مولّد ثابت البذرة: نفس البيانات في كل مرة (أسهل للمقارنة أثناء الاختبار).
    final random = Random(42);

    final cash = (await accounts.getDefault())!;
    final bank = await accounts.create(
      name: t('الراجحي', 'Al Rajhi'),
      type: AccountType.bank,
      openingBalance: money(18500),
    );
    final wallet = await accounts.create(
      name: 'STC Pay',
      type: AccountType.wallet,
      openingBalance: money(1200),
    );

    final categories = await db.select(db.categories).get();
    final expense = categories
        .where((c) => c.kind == CategoryKind.expense)
        .toList();
    final salary = categories.firstWhere((c) => c.kind == CategoryKind.income);
    Category byIcon(String icon) =>
        expense.firstWhere((c) => c.icon == icon, orElse: () => expense.first);

    final notes = arabic
        ? [
            'سوبرماركت',
            'مطعم',
            'بنزين',
            'كهرباء',
            'صيدلية',
            'ملابس',
            'قهوة',
            null,
          ]
        : [
            'Supermarket',
            'Restaurant',
            'Fuel',
            'Electricity',
            'Pharmacy',
            'Clothes',
            'Coffee',
            null,
          ];

    // ستة أشهر: راتب، تحويل إلى النقدية، ومصروفات متنوعة.
    for (var m = 5; m >= 0; m--) {
      final month = DateTime(today.year, today.month - m);
      DateTime day(int d) {
        final date = DateTime(
          month.year,
          month.month,
          d,
          10 + random.nextInt(10),
        );
        return date.isAfter(today) ? today : date;
      }

      await transactions.add(
        TransactionDraft(
          type: TxType.income,
          amount: money(12000),
          accountId: bank,
          categoryId: salary.id,
          date: day(1),
        ),
      );
      await transactions.add(
        TransactionDraft(
          type: TxType.transfer,
          amount: money(2000),
          accountId: bank,
          toAccountId: cash.id,
          date: day(2),
        ),
      );
      final lastDay = m == 0 ? today.day : 28;
      final count = m == 0 ? max(3, today.day ~/ 3) : 10;
      for (var i = 0; i < count; i++) {
        final category = expense[random.nextInt(expense.length - 1)];
        await transactions.add(
          TransactionDraft(
            type: TxType.expense,
            amount: money(20 + random.nextInt(480)),
            accountId: [cash.id, cash.id, bank, wallet][random.nextInt(4)],
            categoryId: category.id,
            date: day(1 + random.nextInt(lastDay)),
            note: notes[random.nextInt(notes.length)],
          ),
        );
      }
    }

    // الميزانيات الشهرية.
    await budgets.upsert(categoryId: byIcon('food').id, limit: money(1500));
    await budgets.upsert(categoryId: byIcon('transport').id, limit: money(800));
    await budgets.upsert(categoryId: byIcon('bills').id, limit: money(1200));
    await budgets.upsert(categoryId: byIcon('shopping').id, limit: money(600));

    // الديون — كل مصادر الدين: إقراض، بيع بالآجل، شراء بالآجل، دين سابق،
    // مع استلام موزّع على دينين ومسامحة.
    final ahmed = await contacts.create(
      name: t('أحمد علي', 'Ahmed Ali'),
      phone: '0551234567',
    );
    // بيع بالآجل: دخل بفئة «مبيعات» دون حركة حساب.
    await debts.createDebt(
      DebtDraft(
        contactId: ahmed,
        direction: DebtDirection.owedToMe,
        source: DebtSource.creditSale,
        amount: money(800),
        startDate: today.subtract(const Duration(days: 40)),
        categoryId: byIcon('sales').id,
        note: t('بضاعة بالآجل', 'Goods on credit'),
      ),
    );
    await debts.createDebt(
      DebtDraft(
        contactId: ahmed,
        direction: DebtDirection.owedToMe,
        source: DebtSource.loan,
        amount: money(1200),
        startDate: today.subtract(const Duration(days: 20)),
        dueDate: today.add(const Duration(days: 5)),
        accountId: cash.id,
        note: t('سلفة جهاز', 'Device loan'),
      ),
    );
    // استلام 1,000: يُغلق البضاعة (800) ويُسدد 200 من السلفة — عملية واحدة.
    await debts.recordPayment(
      PaymentDraft(
        contactId: ahmed,
        direction: DebtDirection.owedToMe,
        amount: money(1000),
        paidAt: today.subtract(const Duration(days: 2)),
        accountId: cash.id,
      ),
    );

    final khaled = await contacts.create(
      name: t('خالد سعيد', 'Khaled Saeed'),
      phone: '0509876543',
    );
    await debts.createDebt(
      DebtDraft(
        contactId: khaled,
        direction: DebtDirection.iOwe,
        source: DebtSource.loan,
        amount: money(1500),
        startDate: today.subtract(const Duration(days: 30)),
        dueDate: today.subtract(const Duration(days: 3)), // متأخر
        accountId: bank,
      ),
    );
    // شراء بالآجل: مصروف بفئة دون حركة حساب.
    await debts.createDebt(
      DebtDraft(
        contactId: khaled,
        direction: DebtDirection.iOwe,
        source: DebtSource.creditPurchase,
        amount: money(350),
        startDate: today.subtract(const Duration(days: 12)),
        categoryId: byIcon('shopping').id,
        note: t('قطع غيار', 'Spare parts'),
      ),
    );

    final mohammed = await contacts.create(
      name: t('محمد حسن', 'Mohammed Hassan'),
    );
    final settled = await debts.createDebt(
      DebtDraft(
        contactId: mohammed,
        direction: DebtDirection.owedToMe,
        source: DebtSource.loan,
        amount: money(650),
        startDate: today.subtract(const Duration(days: 60)),
        accountId: wallet,
      ),
    );
    await debts.recordPayment(
      PaymentDraft(
        contactId: mohammed,
        direction: DebtDirection.owedToMe,
        debtId: settled,
        amount: money(500),
        paidAt: today.subtract(const Duration(days: 10)),
        accountId: wallet,
      ),
    );
    // مسامحة بالمتبقي (150): مصروف «مسامحة ديون» دون حركة حساب.
    final writeOff = await CategoryService(db)
        .ensureSystemCategory(kWriteOffCategory, arabic: arabic);
    await debts.writeOffRemaining(
      contactId: mohammed,
      direction: DebtDirection.owedToMe,
      date: today.subtract(const Duration(days: 1)),
      categoryId: writeOff.id,
    );

    // دين سابق (قبل استخدام التطبيق): في الدفتر فقط.
    final saleh = await contacts.create(name: t('صالح عمر', 'Saleh Omar'));
    await debts.createDebt(
      DebtDraft(
        contactId: saleh,
        direction: DebtDirection.owedToMe,
        source: DebtSource.opening,
        amount: money(300),
        startDate: today.subtract(const Duration(days: 90)),
      ),
    );
  }
}

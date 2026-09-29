// =============================================================================
// تدقيق محاسبي شامل: محاكاة آلاف العمليات العشوائية (ببذور ثابتة قابلة
// للتكرار) مع «دفتر ظلّ» مستقل مكتوب بـ Dart يحسب ما يجب أن تكون عليه كل
// الأرقام، ثم مقارنته بعد كل عملية بما يعرضه التطبيق فعلاً:
//
//   - رصيد كل حساب (والإجمالي)، ومطابقته لإعادة الاحتساب من المعاملات.
//   - كل دين: الأصل، المدفوع، المُسامَح، المتبقي، الحالة، نسبة السداد.
//   - التوزيع على الأقدم أولاً، والزائد ديناً معاكساً، والإلغاء، والمسامحة.
//   - «لي» و«عليّ» وعدد الأشخاص، والملف المالي لكل شخص (النِّسب المرجّحة).
//   - الدخل والمصروف والتسويات في التقارير وحسب الفئة وحسب الشهر.
//   - مصروف الميزانية لكل فئة.
//   - كشف الحساب: الرصيد الجاري والختامي = المتبقي.
//   - معادلة التطابق الشاملة = صفر دائماً.
//   - العمليات المرفوضة لا تغيّر أي رقم (الذرّية).
// =============================================================================

import 'dart:math';

import 'package:daftry/core/errors/app_exception.dart';
import 'package:daftry/core/utils/date_range.dart';
import 'package:daftry/data/seed/default_categories.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/debt_models.dart';
import 'package:daftry/domain/models/transaction_models.dart';
import 'package:daftry/services/debt_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

class _Tx {
  _Tx(this.type, this.amount, this.account, this.to, this.category, this.date);
  TxType type;
  int amount;
  int account;
  int? to;
  int? category;
  DateTime date;
}

class _Debt {
  _Debt({
    required this.id,
    required this.contact,
    required this.dir,
    required this.source,
    required this.amount,
    required this.start,
    this.account,
    this.category,
  });
  final int id;
  final int contact;
  final DebtDirection dir;
  final DebtSource source;
  int amount;
  final DateTime start;
  final int? account;
  final int? category;
  int paid = 0;
  int writtenOff = 0;
  int get remaining => amount - paid - writtenOff;
}

class _Op {
  _Op(this.id, this.dir, this.account, this.parts);
  final String id;
  final DebtDirection dir;
  final int account;
  final Map<int, int> parts;
  bool cancelled = false;
  int get applied => parts.values.fold(0, (s, v) => s + v);
}

/// دفتر الظل: ما يجب أن تكون عليه الأرقام وفق قواعد الوثيقة.
class _Shadow {
  final balance = <int, int>{};
  final opening = <int, int>{};
  final archived = <int>{};
  var income = 0;
  var expense = 0;
  var adjustments = 0;
  final incomeByCat = <int, int>{};
  final expenseByCat = <int, int>{};
  final txs = <int, _Tx>{};
  final debts = <int, _Debt>{};
  final ops = <String, _Op>{};

  void addIncome(int cat, int amount) {
    income += amount;
    incomeByCat.update(cat, (v) => v + amount, ifAbsent: () => amount);
  }

  void addExpense(int cat, int amount) {
    expense += amount;
    expenseByCat.update(cat, (v) => v + amount, ifAbsent: () => amount);
  }

  void applyTx(_Tx t, int sign) {
    switch (t.type) {
      case TxType.income:
        balance[t.account] = balance[t.account]! + sign * t.amount;
        addIncome(t.category!, sign * t.amount);
      case TxType.expense:
        balance[t.account] = balance[t.account]! - sign * t.amount;
        addExpense(t.category!, sign * t.amount);
      case TxType.transfer:
        balance[t.account] = balance[t.account]! - sign * t.amount;
        balance[t.to!] = balance[t.to!]! + sign * t.amount;
      default:
        throw StateError('unexpected ${t.type}');
    }
  }

  /// أثر قيد الدين عند إنشائه (sign = 1) أو حذفه (-1)، أو فرق تعديله.
  void applyDebtEntry(_Debt d, int amount) {
    switch (d.source) {
      case DebtSource.loan:
        final delta = d.dir == DebtDirection.owedToMe ? -amount : amount;
        balance[d.account!] = balance[d.account!]! + delta;
      case DebtSource.creditSale:
        addIncome(d.category!, amount);
      case DebtSource.creditPurchase:
        addExpense(d.category!, amount);
      case DebtSource.opening:
        break;
    }
  }

  int remaining(DebtDirection dir, {int? contact}) => debts.values
      .where((d) => d.dir == dir && (contact == null || d.contact == contact))
      .fold(0, (s, d) => s + d.remaining);

  /// التوزيع المتوقع: الديون المفتوحة الأقدم أولاً (تاريخ البدء ثم الرقم).
  List<(int, int)> expectedAllocation(
    int contact,
    DebtDirection dir,
    int amount, {
    int? debtId,
  }) {
    final open =
        debts.values
            .where(
              (d) =>
                  d.contact == contact &&
                  d.dir == dir &&
                  d.remaining > 0 &&
                  (debtId == null || d.id == debtId),
            )
            .toList()
          ..sort((a, b) {
            final byDate = a.start.compareTo(b.start);
            return byDate != 0 ? byDate : a.id.compareTo(b.id);
          });
    final result = <(int, int)>[];
    var left = amount;
    for (final d in open) {
      if (left <= 0) break;
      final part = min(left, d.remaining);
      result.add((d.id, part));
      left -= part;
    }
    return result;
  }
}

/// عدد مرات تنفيذ كل نوع عملية (للتأكد أن المحاكاة غطّت كل الفروع فعلاً).
final _coverage = <String, int>{};
void _hit(String kind) =>
    _coverage.update(kind, (v) => v + 1, ifAbsent: () => 1);

Future<void> _runScenario(int seed, int steps) async {
  final env = await TestEnv.create();
  addTearDown(env.dispose);
  final rnd = Random(seed);
  final shadow = _Shadow();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final allTime = DateRange(
    today.subtract(const Duration(days: 400)),
    today.add(const Duration(days: 1)),
  );

  // --------------------------- الإعداد -----------------------------------
  final cash = await env.cash;
  shadow.balance[cash.id] = 0;
  shadow.opening[cash.id] = 0;
  final incomeCats =
      (await env.categories
              .watchByKind(CategoryKind.income, forTransactions: true)
              .first)
          .map((c) => c.id)
          .toList();
  final expenseCats =
      (await env.categories
              .watchByKind(CategoryKind.expense, forTransactions: true)
              .first)
          .map((c) => c.id)
          .toList();
  final writeOffCat = (await env.categories.ensureSystemCategory(
    kWriteOffCategory,
    arabic: true,
  )).id;
  final forgivenCat = (await env.categories.ensureSystemCategory(
    kForgivenCategory,
    arabic: true,
  )).id;
  final contacts = [
    for (final n in ['أحمد', 'خالد', 'سارة', 'محمد'])
      await env.contacts.create(name: n),
  ];

  T pick<T>(List<T> list) => list[rnd.nextInt(list.length)];
  int amount() => switch (rnd.nextInt(4)) {
    0 => 1 + rnd.nextInt(999), // أقل من 10 ريالات بالهللات
    1 => 1000 + rnd.nextInt(99000),
    2 => 100000 + rnd.nextInt(900000),
    _ => (1 + rnd.nextInt(50)) * 10000, // مبالغ مستديرة
  };
  DateTime pastDate() =>
      today.subtract(Duration(days: rnd.nextInt(90), hours: rnd.nextInt(20)));
  List<int> activeAccounts() => [
    for (final id in shadow.balance.keys)
      if (!shadow.archived.contains(id)) id,
  ];

  /// عملية يجب أن تُرفض دون أن تغيّر أي رقم.
  Future<void> expectRejected(
    Future<Object?> Function() action,
    BusinessError error,
  ) async {
    final before = await _fingerprint(env);
    await expectLater(action(), throwsA(isA<BusinessException>()));
    try {
      await action();
    } on BusinessException catch (e) {
      expect(e.error, error);
    }
    expect(await _fingerprint(env), before, reason: 'الرفض غيّر البيانات');
  }

  for (var step = 0; step < steps; step++) {
    final roll = rnd.nextInt(100);
    final accounts = activeAccounts();

    if (roll < 6) {
      // حساب جديد برصيد افتتاحي (قد يكون صفراً).
      final opening = rnd.nextBool() ? amount() : 0;
      final id = await env.accounts.create(
        name: 'حساب $seed-$step',
        type: pick(AccountType.values),
        openingBalance: opening,
      );
      shadow.balance[id] = opening;
      shadow.opening[id] = opening;
      _hit('account');
    } else if (roll < 26) {
      // دخل / مصروف / تحويل.
      final type = pick([
        TxType.income,
        TxType.expense,
        TxType.expense,
        if (accounts.length > 1) TxType.transfer,
      ]);
      final from = pick(accounts);
      final to = type == TxType.transfer
          ? pick([
              for (final a in accounts)
                if (a != from) a,
            ])
          : null;
      final cat = switch (type) {
        TxType.income => pick(incomeCats),
        TxType.expense => pick(expenseCats),
        _ => null,
      };
      final t = _Tx(type, amount(), from, to, cat, pastDate());
      final r = await env.transactions.add(
        TransactionDraft(
          type: t.type,
          amount: t.amount,
          accountId: t.account,
          toAccountId: t.to,
          categoryId: t.category,
          date: t.date,
        ),
      );
      shadow.txs[r.id] = t;
      shadow.applyTx(t, 1);
      _hit('tx:${t.type.name}');
    } else if (roll < 32 && shadow.txs.isNotEmpty) {
      // تعديل معاملة: مبلغ وحساب وتاريخ جديد (ينطبق الفرق فقط).
      final id = pick(shadow.txs.keys.toList());
      final t = shadow.txs[id]!;
      final involved = {t.account, ?t.to};
      if (involved.any(shadow.archived.contains)) continue;
      final updated = _Tx(
        t.type,
        amount(),
        pick(accounts),
        null,
        t.category,
        pastDate(),
      );
      if (t.type == TxType.transfer) {
        final others = [
          for (final a in accounts)
            if (a != updated.account) a,
        ];
        if (others.isEmpty) continue;
        updated.to = pick(others);
      }
      await env.transactions.update(
        id,
        TransactionDraft(
          type: updated.type,
          amount: updated.amount,
          accountId: updated.account,
          toAccountId: updated.to,
          categoryId: updated.category,
          date: updated.date,
        ),
      );
      shadow.applyTx(t, -1);
      shadow.applyTx(updated, 1);
      shadow.txs[id] = updated;
      _hit('tx:update');
    } else if (roll < 36 && shadow.txs.isNotEmpty) {
      // حذف معاملة يعيد أثرها.
      final id = pick(shadow.txs.keys.toList());
      final t = shadow.txs[id]!;
      if ({t.account, ?t.to}.any(shadow.archived.contains)) continue;
      await env.transactions.delete(id);
      shadow.applyTx(t, -1);
      shadow.txs.remove(id);
      _hit('tx:delete');
    } else if (roll < 54) {
      // دين جديد بأي مصدر.
      final dir = pick(DebtDirection.values);
      final source = pick(DebtSource.forDirection(dir));
      final d = _Debt(
        id: -1,
        contact: pick(contacts),
        dir: dir,
        source: source,
        amount: amount(),
        start: pastDate(),
        account: source.needsAccount ? pick(accounts) : null,
        category: switch (source) {
          DebtSource.creditSale => pick(incomeCats),
          DebtSource.creditPurchase => pick(expenseCats),
          _ => null,
        },
      );
      final id = await env.debts.createDebt(
        DebtDraft(
          contactId: d.contact,
          direction: d.dir,
          source: d.source,
          amount: d.amount,
          startDate: d.start,
          accountId: d.account,
          categoryId: d.category,
          dueDate: rnd.nextBool()
              ? d.start.add(Duration(days: rnd.nextInt(60)))
              : null,
        ),
      );
      final created = _Debt(
        id: id,
        contact: d.contact,
        dir: d.dir,
        source: d.source,
        amount: d.amount,
        start: d.start,
        account: d.account,
        category: d.category,
      );
      shadow.debts[id] = created;
      shadow.applyDebtEntry(created, created.amount);
      _hit('debt:${source.name}');
    } else if (roll < 58 && shadow.debts.isNotEmpty) {
      // تعديل أصل دين: لا يقل عن المدفوع + المُسامَح، والأثر بالفرق فقط.
      final d = pick(shadow.debts.values.toList());
      if (d.account != null && shadow.archived.contains(d.account)) continue;
      final floor = d.paid + d.writtenOff;
      final tooLow = floor > 0 && rnd.nextInt(4) == 0;
      final newAmount = tooLow
          ? floor - 1
          : max(floor, 1) + rnd.nextInt(200000);
      Future<void> update() => env.debts.updateDebt(
        d.id,
        DebtDraft(
          contactId: d.contact,
          direction: d.dir,
          source: d.source,
          amount: newAmount,
          startDate: d.start,
          accountId: d.account,
          categoryId: d.category,
        ),
      );
      if (tooLow) {
        await expectRejected(update, BusinessError.debtAmountBelowPaid);
        _hit('reject:belowPaid');
      } else {
        await update();
        shadow.applyDebtEntry(d, newAmount - d.amount);
        d.amount = newAmount;
        _hit('debt:update');
      }
    } else if (roll < 61 && shadow.debts.isNotEmpty) {
      // حذف دين: فقط لخطأ إدخال (بلا دفعات ولا مسامحة).
      final d = pick(shadow.debts.values.toList());
      if (d.account != null && shadow.archived.contains(d.account)) continue;
      if (d.paid > 0 || d.writtenOff > 0) {
        await expectRejected(
          () => env.debts.deleteDebt(d.id),
          BusinessError.debtHasMovements,
        );
        _hit('reject:deleteWithMovements');
      } else {
        await env.debts.deleteDebt(d.id);
        shadow.applyDebtEntry(d, -d.amount);
        shadow.debts.remove(d.id);
        _hit('debt:delete');
      }
    } else if (roll < 80) {
      // استلام / سداد: كامل أو جزئي أو بزيادة، تلقائي أو على دين معيّن.
      final open = shadow.debts.values.where((d) => d.remaining > 0).toList();
      if (open.isEmpty) continue;
      final target = pick(open);
      final specific = rnd.nextInt(5) == 0 ? target.id : null;
      final total = specific != null
          ? target.remaining
          : shadow.remaining(target.dir, contact: target.contact);
      final kind = rnd.nextInt(10);
      final pay = switch (kind) {
        < 3 => total, // كامل المتبقي
        < 8 => 1 + rnd.nextInt(total), // جزئي
        _ => total + 1 + rnd.nextInt(50000), // زائد
      };
      final account = pick(accounts);
      final draft = PaymentDraft(
        contactId: target.contact,
        direction: target.dir,
        amount: pay,
        paidAt: now,
        accountId: account,
        debtId: specific,
      );
      if (pay > total && rnd.nextBool()) {
        // الزائد دون موافقة: يُرفض دون أي أثر.
        await expectRejected(
          () => env.debts.recordPayment(draft),
          BusinessError.paymentExceedsRemaining,
        );
        _hit('reject:excess');
        continue;
      }
      final expected = shadow.expectedAllocation(
        target.contact,
        target.dir,
        min(pay, total),
        debtId: specific,
      );
      final result = await env.debts.recordPayment(
        draft,
        excessAsOppositeDebt: pay > total,
      );
      expect(
        [for (final a in result.allocations) (a.debtId, a.amount)],
        expected,
        reason: 'التوزيع على الأقدم أولاً',
      );
      final op = _Op(result.operationId, target.dir, account, {
        for (final (id, part) in expected) id: part,
      });
      shadow.ops[op.id] = op;
      for (final (id, part) in expected) {
        shadow.debts[id]!.paid += part;
      }
      final sign = target.dir == DebtDirection.owedToMe ? 1 : -1;
      shadow.balance[account] = shadow.balance[account]! + sign * op.applied;
      if (pay > total) {
        // الزائد دين معاكس (إقراض/اقتراض على الحساب نفسه).
        expect(result.excessDebtId, isNotNull);
        final excess = _Debt(
          id: result.excessDebtId!,
          contact: target.contact,
          dir: target.dir == DebtDirection.owedToMe
              ? DebtDirection.iOwe
              : DebtDirection.owedToMe,
          source: DebtSource.loan,
          amount: pay - total,
          start: now,
          account: account,
        );
        shadow.debts[excess.id] = excess;
        shadow.applyDebtEntry(excess, excess.amount);
        _hit('payment:excess');
      } else {
        expect(result.excessDebtId, isNull);
        _hit(expected.length > 1 ? 'payment:split' : 'payment:single');
      }
    } else if (roll < 86) {
      // إلغاء عملية (مرة واحدة فقط؛ الثانية تُرفض).
      final live = shadow.ops.values
          .where((o) => !shadow.archived.contains(o.account))
          .toList();
      if (live.isEmpty) continue;
      final op = pick(live);
      if (op.cancelled) {
        await expectRejected(
          () => env.debts.cancelOperation(op.id),
          BusinessError.paymentAlreadyCancelled,
        );
        _hit('reject:cancelTwice');
        continue;
      }
      await env.debts.cancelOperation(op.id);
      op.cancelled = true;
      _hit('payment:cancel');
      op.parts.forEach((id, part) => shadow.debts[id]!.paid -= part);
      final sign = op.dir == DebtDirection.owedToMe ? 1 : -1;
      shadow.balance[op.account] =
          shadow.balance[op.account]! - sign * op.applied;
    } else if (roll < 90) {
      // مسامحة بالمتبقي (لدين معيّن أو لكل ديون الاتجاه).
      final open = shadow.debts.values.where((d) => d.remaining > 0).toList();
      if (open.isEmpty) continue;
      final target = pick(open);
      final specific = rnd.nextBool() ? target.id : null;
      final affected = shadow.debts.values.where(
        (d) =>
            d.contact == target.contact &&
            d.dir == target.dir &&
            d.remaining > 0 &&
            (specific == null || d.id == specific),
      );
      final owedToMe = target.dir == DebtDirection.owedToMe;
      await env.debts.writeOffRemaining(
        contactId: target.contact,
        direction: target.dir,
        date: now,
        categoryId: owedToMe ? writeOffCat : forgivenCat,
        debtId: specific,
      );
      for (final d in affected.toList()) {
        if (owedToMe) {
          shadow.addExpense(writeOffCat, d.remaining);
        } else {
          shadow.addIncome(forgivenCat, d.remaining);
        }
        d.writtenOff += d.remaining;
      }
      _hit('writeOff:${target.dir.name}');
    } else if (roll < 94) {
      // تسوية الرصيد إلى رقم فعلي (قد يكون أقل أو أكثر).
      final id = pick(accounts);
      final real = rnd.nextInt(3) == 0 ? 0 : amount() - 300000;
      await env.accounts.adjustBalance(id, real);
      shadow.adjustments += real - shadow.balance[id]!;
      shadow.balance[id] = real;
      _hit('adjust');
    } else if (roll < 97) {
      // أرشفة حساب (غير الافتراضي) بعد تحويل رصيده في العملية نفسها.
      final candidates = [
        for (final a in accounts)
          if (a != cash.id) a,
      ];
      if (candidates.isEmpty) continue;
      final id = pick(candidates);
      final target = pick([
        for (final a in accounts)
          if (a != id) a,
      ]);
      if (shadow.balance[id] != 0 && rnd.nextBool()) {
        await expectRejected(
          () => env.accounts.archive(id),
          BusinessError.accountHasBalance,
        );
        _hit('reject:archiveWithBalance');
        continue;
      }
      await env.accounts.archive(id, transferToId: target);
      shadow.balance[target] = shadow.balance[target]! + shadow.balance[id]!;
      shadow.balance[id] = 0;
      shadow.archived.add(id);
      _hit('account:archive');
    } else if (shadow.archived.isNotEmpty) {
      // رفع الأرشفة يعيده نشطاً برصيد صفر.
      final id = pick(shadow.archived.toList());
      await env.accounts.unarchive(id);
      shadow.archived.remove(id);
      _hit('account:unarchive');
    }

    // ------------------ التحقق بعد كل عملية ------------------
    await _checkBalances(env, shadow, step);
    expect(await env.accounts.reconciliationGap(), 0, reason: 'خطوة $step');
    final totals = await env.debts.watchTotals().first;
    expect(
      (totals.owedToMe, totals.iOwe),
      (
        shadow.remaining(DebtDirection.owedToMe),
        shadow.remaining(DebtDirection.iOwe),
      ),
      reason: 'لي / عليّ — خطوة $step',
    );
    if (step % 15 == 14 || step == steps - 1) {
      await _deepCheck(env, shadow, allTime, contacts, step);
    }
  }
}

/// بصمة كل الأرقام المهمة (للتأكد من أن العملية المرفوضة لم تغيّر شيئاً).
Future<List<Object>> _fingerprint(TestEnv env) async {
  final accounts = await env.db.select(env.db.accounts).get();
  final debts = await env.db.select(env.db.debts).get();
  final payments = await env.db.select(env.db.debtPayments).get();
  final txs = await env.db.select(env.db.transactions).get();
  return [
    for (final a in accounts) (a.id, a.balance, a.isArchived),
    for (final d in debts) (d.id, d.amount, d.writtenOff),
    for (final p in payments) (p.id, p.amount, p.isCancelled),
    txs.length,
    txs.fold<int>(0, (s, t) => s + t.amount),
  ];
}

Future<void> _checkBalances(TestEnv env, _Shadow shadow, int step) async {
  final accounts = await env.db.select(env.db.accounts).get();
  for (final a in accounts) {
    expect(a.balance, shadow.balance[a.id], reason: 'رصيد ${a.name} — $step');
    expect(a.isArchived, shadow.archived.contains(a.id));
  }
  final total = await env.accounts.watchTotalBalance().first;
  expect(
    total,
    shadow.balance.entries
        .where((e) => !shadow.archived.contains(e.key))
        .fold(0, (s, e) => s + e.value),
    reason: 'إجمالي الأرصدة النشطة — $step',
  );
}

Future<void> _deepCheck(
  TestEnv env,
  _Shadow shadow,
  DateRange allTime,
  List<int> contacts,
  int step,
) async {
  final why = 'خطوة $step';

  // 1) الرصيد = الافتتاحي + أثر كل المعاملات، محسوباً هنا باستقلال تام.
  final txs = await env.db.select(env.db.transactions).get();
  final recomputed = {...shadow.opening};
  for (final t in txs) {
    void add(int? account, int v) {
      if (account != null) recomputed[account] = recomputed[account]! + v;
    }

    switch (t.type) {
      case TxType.income || TxType.debtIn || TxType.adjustment:
        add(t.accountId, t.amount);
      case TxType.expense || TxType.debtOut:
        add(t.accountId, -t.amount);
      case TxType.transfer:
        add(t.accountId, -t.amount);
        add(t.toAccountId, t.amount);
      case TxType.writeOff || TxType.debtForgiven:
        expect(t.accountId, isNull, reason: 'المسامحة بلا حركة حساب');
    }
  }
  expect(recomputed, shadow.balance, reason: 'إعادة الاحتساب المستقلة — $why');
  expect(await env.accounts.recalculateAll(), 0, reason: why);

  // 2) كل دين.
  for (final d in shadow.debts.values) {
    final v = (await env.debts.debtView(d.id))!;
    expect(
      (v.amount, v.paid, v.writtenOff, v.remaining),
      (d.amount, d.paid, d.writtenOff, d.remaining),
      reason: 'دين ${d.id} — $why',
    );
    expect(v.remaining, greaterThanOrEqualTo(0));
    expect(
      v.status,
      d.remaining == 0
          ? DebtStatus.closed
          : d.remaining == d.amount
          ? DebtStatus.open
          : DebtStatus.partial,
    );
    expect(v.progress, (d.paid * 100) ~/ d.amount);
  }

  // 3) الدخل والمصروف والتسويات (السجل والتقارير والأشهر والفئات).
  final totals = await env.transactions.totals(allTime);
  expect((totals.income, totals.expense), (shadow.income, shadow.expense));
  final report = await env.reports.report(allTime, months: 14);
  expect((report.income, report.expense), (shadow.income, shadow.expense));
  expect(report.adjustments, shadow.adjustments, reason: 'التسويات — $why');
  Map<int, int> nonZero(Map<int, int> m) => {
    for (final e in m.entries)
      if (e.value != 0) e.key: e.value,
  };
  expect({
    for (final c in report.expenseByCategory) c.category.id: c.total,
  }, nonZero(shadow.expenseByCat));
  expect({
    for (final c in report.incomeByCategory) c.category.id: c.total,
  }, nonZero(shadow.incomeByCat));
  final shares = report.expenseByCategory.fold<double>(
    0,
    (s, c) => s + c.share,
  );
  if (report.expenseByCategory.isNotEmpty) expect(shares, closeTo(1, 1e-9));
  final months = await env.reports.monthlyTotals(
    DateRange(allTime.start, allTime.end),
  );
  expect(
    (
      months.fold<int>(0, (s, m) => s + m.income),
      months.fold<int>(0, (s, m) => s + m.expense),
    ),
    (shadow.income, shadow.expense),
    reason: 'مجموع الأشهر — $why',
  );
  expect(
    await env.budgets.spentByCategory(allTime),
    nonZero(shadow.expenseByCat),
    reason: 'مصروف الميزانية لكل فئة — $why',
  );

  // 4) الأشخاص: الملف المالي، القائمة، وكشف الحساب.
  final people = {
    for (final p in await env.debts.watchPeople().first) p.contact.id: p,
  };
  for (final contact in contacts) {
    final mine = shadow.debts.values.where((d) => d.contact == contact);
    final profile = (await env.debts.profile(contact))!;
    final statement = await env.statements.build(contact, allTime);
    for (final dir in DebtDirection.values) {
      final list = mine.where((d) => d.dir == dir).toList();
      final summary = profile.summary(dir);
      if (list.isEmpty) {
        expect(summary, isNull);
        continue;
      }
      final total = list.fold(0, (s, d) => s + d.amount);
      final paid = list.fold(0, (s, d) => s + d.paid);
      final w = list.fold(0, (s, d) => s + d.writtenOff);
      final remaining = total - paid - w;
      expect(
        (summary!.total, summary.paid, summary.writtenOff, summary.remaining),
        (total, paid, w, remaining),
        reason: 'ملف $contact ${dir.name} — $why',
      );
      // نسبة السداد مرجّحة بالمبالغ وتُقرَّب للأسفل.
      expect(summary.progress, (paid * 100) ~/ total);

      final section = statement.sections.firstWhere((s) => s.direction == dir);
      expect(section.opening, 0);
      var running = 0;
      for (final line in section.lines) {
        running += line.movement;
        expect(line.balance, running, reason: 'الرصيد الجاري في الكشف');
      }
      expect(running, remaining, reason: 'الختامي = المتبقي — $why');
      // الخط الزمني في الملف ينتهي بالمتبقي نفسه.
      // (الأحدث أولاً؛ الملغاة بلا رصيد لأنها لا تُحتسب).
      final live = profile.timeline.where(
        (e) => e.direction == dir && !e.cancelled,
      );
      if (live.isNotEmpty) {
        expect(
          live.first.balanceAfter,
          remaining,
          reason: 'الخط الزمني — $why',
        );
      }
    }
    final p = people[contact];
    if (p != null) {
      expect(
        (p.receivable, p.payable),
        (
          shadow.remaining(DebtDirection.owedToMe, contact: contact),
          shadow.remaining(DebtDirection.iOwe, contact: contact),
        ),
      );
    }
  }
}

void main() {
  // بذور ثابتة: أي فشل يمكن تكراره بالضبط.
  for (final seed in [7, 21, 42, 99, 1234, 2026, 31337, 777]) {
    test('تدقيق محاسبي عشوائي (بذرة $seed، 400 عملية)', () async {
      await _runScenario(seed, 400);
    }, timeout: const Timeout(Duration(minutes: 5)));
  }

  test('المحاكاة غطّت كل أنواع العمليات والرفض', () {
    const kinds = [
      'account',
      'tx:income',
      'tx:expense',
      'tx:transfer',
      'tx:update',
      'tx:delete',
      'debt:loan',
      'debt:creditSale',
      'debt:creditPurchase',
      'debt:opening',
      'debt:update',
      'debt:delete',
      'payment:single',
      'payment:split',
      'payment:excess',
      'payment:cancel',
      'writeOff:owedToMe',
      'writeOff:iOwe',
      'adjust',
      'account:archive',
      'account:unarchive',
      'reject:belowPaid',
      'reject:deleteWithMovements',
      'reject:excess',
      'reject:cancelTwice',
      'reject:archiveWithBalance',
    ];
    for (final k in kinds) {
      expect(_coverage[k] ?? 0, greaterThan(0), reason: k);
    }
    // ignore: avoid_print
    print('تغطية العمليات: $_coverage');
  });

  test('حالات حدّية للنِّسب والتقريب', () {
    // لا تظهر 100% إلا عند السداد الكامل (99.6% ← 99%).
    expect(DebtMath.progress(paid: 99600, amount: 100000), 99);
    expect(DebtMath.progress(paid: 100000, amount: 100000), 100);
    expect(DebtMath.progress(paid: 1, amount: 3), 33);
    expect(DebtMath.progress(paid: 0, amount: 0), 0);
    // المسامحة المتممة: المجموع 100% عند الإغلاق.
    final paid = 58123;
    final w = 100000 - paid;
    expect(
      DebtMath.progress(paid: paid, amount: 100000) +
          DebtMath.writtenOffPercent(paid: paid, writtenOff: w, amount: 100000),
      100,
    );
    expect(DebtMath.status(amount: 500, remaining: 500), DebtStatus.open);
    expect(DebtMath.status(amount: 500, remaining: 1), DebtStatus.partial);
    expect(DebtMath.status(amount: 500, remaining: 0), DebtStatus.closed);
    // التوزيع لا يتجاوز متبقي أي دين ولا المبلغ نفسه.
    final parts = DebtService.allocate(const [
      (debtId: 1, remaining: 30000),
      (debtId: 2, remaining: 120000),
      (debtId: 3, remaining: 5000),
    ], 50000);
    expect(
      [for (final a in parts) (a.debtId, a.amount)],
      [(1, 30000), (2, 20000)],
    );
  });
}

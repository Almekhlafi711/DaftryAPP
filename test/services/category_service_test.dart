// اختبارات خدمة الفئات.
import 'package:daftry/core/errors/app_exception.dart';
import 'package:daftry/domain/enums.dart';
import 'package:daftry/domain/models/transaction_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late TestEnv env;
  setUp(() async => env = await TestEnv.create());
  tearDown(() => env.dispose());

  test('إضافة فئة في آخر الترتيب ثم تعديلها', () async {
    final before = await env.categories.watchByKind(CategoryKind.expense).first;
    final id = await env.categories.create(
      name: 'قهوة',
      kind: CategoryKind.expense,
      icon: 'coffee',
      color: 0xFF7C3AED,
    );
    final after = await env.categories.watchByKind(CategoryKind.expense).first;
    expect(after.last.id, id);
    expect(after.length, before.length + 1);

    await env.categories.update(
      id,
      name: 'مقاهي',
      icon: 'coffee',
      color: 0xFF0F766E,
    );
    expect((await env.categories.getById(id))!.name, 'مقاهي');
  });

  test('الاسم الفارغ مرفوض', () async {
    expect(
      env.categories.create(
        name: '  ',
        kind: CategoryKind.income,
        icon: 'gift',
        color: 0,
      ),
      throwsA(isA<BusinessException>()),
    );
  });

  test('لا تُحذف فئة مستخدمة، وتُحذف غير المستخدمة', () async {
    final food = await env.category(CategoryKind.expense);
    await env.transactions.add(
      TransactionDraft(
        type: TxType.expense,
        amount: 100,
        accountId: (await env.cash).id,
        categoryId: food.id,
        date: DateTime.now(),
      ),
    );
    expect(
      env.categories.delete(food.id),
      throwsA(
        isA<BusinessException>().having(
          (e) => e.error,
          'error',
          BusinessError.categoryInUse,
        ),
      ),
    );
    final unused = await env.categories.create(
      name: 'مؤقتة',
      kind: CategoryKind.expense,
      icon: 'other',
      color: 0,
    );
    await env.categories.delete(unused);
    expect(await env.categories.getById(unused), isNull);
    expect(await env.categories.watchAll().first, isNotEmpty);
  });
}

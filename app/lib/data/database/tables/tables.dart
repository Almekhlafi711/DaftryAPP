// =============================================================================
// تعريف جداول قاعدة البيانات المحلية (SQLite عبر Drift).
//
// تطابق هذه الجداول نموذج البيانات (ERD) في الوثيقة — عشرة جداول:
// CURRENCY, ACCOUNT, CATEGORY, TRANSACTION, CONTACT, DEBT, DEBT_PAYMENT,
// BUDGET, SETTINGS, BACKUP_LOG.
//
// ملاحظات تصميمية:
// 1) المبالغ أعداد صحيحة بأصغر وحدة للعملة (انظر core/money/money.dart).
// 2) لا يوجد جدول مستخدمين لأن التطبيق يعمل بدون تسجيل دخول.
// 3) يبقى جدول العملات وحقل currency_id رغم أن التطبيق بعملة واحدة،
//    حتى يمكن تفعيل تعدد العملات لاحقاً دون ترحيل بيانات المستخدمين.
// 4) الفهارس (Indexes) مضافة على الأعمدة التي نبحث ونرتب بها كثيراً
//    (التاريخ، الحساب، الفئة، الدين) لتسريع الاستعلامات.
// =============================================================================

export 'accounts.dart';
export 'backup_logs.dart';
export 'budgets.dart';
export 'categories.dart';
export 'contacts.dart';
export 'currencies.dart';
export 'debt_payments.dart';
export 'debts.dart';
export 'settings.dart';
export 'transactions.dart';

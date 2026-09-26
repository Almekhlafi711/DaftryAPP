# معمارية تطبيق «دفتري»

## 1) الطبقات

الوثيقة (سجل القرارات 3.13) رفضت Clean Architecture + DDD بوحدات كثيرة لأنها مبالغة لحجم التطبيق، واعتمدت **طبقات بسيطة**. هذا ما طُبّق:

```
┌──────────────────────────────────────────────────────────────┐
│ ui/        التصميم فقط: شاشات، مكونات، ثيم، تنقل، ترجمة        │
│            يقرأ التدفقات (Streams) ويستدعي الخدمات              │
├──────────────────────────────────────────────────────────────┤
│ services/  منطق العمل: القواعد، التحقق، العمليات الذرية         │
│            (AccountService, TransactionService, DebtService…) │
├──────────────────────────────────────────────────────────────┤
│ data/      قاعدة البيانات المحلية: Drift + SQLite               │
│            الجداول، الفهارس، المشغّلات، الترحيل                  │
├──────────────────────────────────────────────────────────────┤
│ domain/ + core/   الأنواع والنماذج والأدوات المشتركة             │
└──────────────────────────────────────────────────────────────┘
```

- **الواجهة لا تعرف SQL**، ولا تغيّر رصيداً بنفسها.
- **الخدمات لا تعرف Flutter Widgets**؛ ترمي `BusinessException` برمز، والواجهة تترجمه إلى رسالة (`ui/widgets/feedback.dart`).
- **حقن التبعيات** عبر Riverpod في `services/providers.dart`: أي خدمة يمكن استبدالها في الاختبارات.
- الخدمات تطابق مخطط «طبقة الخدمات» (الشكل 3-12): `AccountService`، `TransactionService`، `DebtService`، `BudgetService`، `StatementService`، `ReportService`، `BackupService` + واجهة `CloudProvider` (يحققها `GoogleDriveProvider` و `ICloudProvider`).

## 2) تدفق البيانات (مثال: إضافة مصروف)

```
TransactionFormScreen ──add(draft)──▶ TransactionService
                                        │ db.transaction {           ← عملية ذرية (ACID)
                                        │   _validate(draft)          ← القواعد
                                        │   Ledger.insert(row)        ← حفظ المعاملة
                                        │   UPDATE balance = balance - amount
                                        │ }
                                        └─▶ BudgetService.check()    ← تنبيه 75% / 100%
SQLite يُبلغ Drift بتغيّر الجداول ──▶ كل Stream مرتبط يعيد القراءة
HomeScreen / TransactionsScreen / AccountsScreen تتحدث تلقائياً (بلا تحديث يدوي)
```

## 3) لماذا هذا أسرع وصول للبيانات؟

| القرار | الأثر |
|---|---|
| قاعدة بيانات محلية على الجهاز | لا انتظار للشبكة إطلاقاً — كل قراءة بأجزاء من الملّي ثانية |
| Isolate خلفي لـ SQLite (`drift_flutter`) | الاستعلامات لا تحجز خيط الواجهة؛ التمرير سلس دائماً |
| WAL + `synchronous=NORMAL` | القراءة والكتابة لا تحجب بعضها، والكتابة أسرع |
| **الرصيد مخزَّن** ويُحدَّث بعبارة `balance = balance + ?` داخل نفس العملية | عرض الأرصدة فوري دون جمع آلاف المعاملات؛ ويمكن إعادة احتسابه للتدقيق (FR-27) |
| `paid_amount` مخزَّن في جدول الديون | قائمة الأشخاص وحالاتهم باستعلام واحد |
| فهارس على (التاريخ)، (الحساب، التاريخ)، (الفئة، التاريخ)، (الدين)… | الفلترة والتقارير تستخدم الفهارس بدل المسح الكامل |
| التجميع داخل SQL (`SUM`, `GROUP BY`, `strftime`) | التقارير والميزانية والملخصات بلا نقل آلاف الصفوف إلى Dart |
| JOIN واحد لقوائم المعاملات | اسم الفئة والحساب والشخص مع كل معاملة دون استعلام لكل عنصر |
| تحميل تدريجي (60 عنصراً ثم المزيد عند التمرير) | ذاكرة أقل وفتح أسرع للسجل |
| تدفقات تفاعلية + `autoDispose` | لا تحديث يدوي، ولا استهلاك موارد لشاشات مغلقة |
| المبالغ أعداد صحيحة بأصغر وحدة | دقة 100% (لا أخطاء تقريب) ومقارنات وجمع أسرع |

## 4) نموذج البيانات

عشرة جداول مطابقة للـ ERD (الشكل 3-10) في `data/database/tables/` — ملف لكل جدول:

| الجدول | ملاحظات التنفيذ |
|---|---|
| `currencies` | صف واحد حالياً؛ يبقى مع `currency_id` في الجداول للتوسع لتعدد العملات دون ترحيل |
| `accounts` | **مشغّل `trg_accounts_no_delete` يمنع DELETE**؛ فهرس فريد جزئي يضمن حساباً افتراضياً واحداً |
| `categories` | منفصلة للدخل والمصروف، `parent_id` للفئات الفرعية، `sort_order` للعرض |
| `transactions` | `CHECK`: المبلغ ≠ 0، وموجب إلا في «التسوية» |
| `contacts` | `is_active` لإخفاء الشخص مع بقاء سجله |
| `debts` | `status` يُحسب آلياً، `paid_amount` مشتق مخزَّن |
| `debt_payments` | علاقة تركيب: `ON DELETE CASCADE` |
| `budgets` | فريد على (الفئة، الفترة) |
| `settings` | مفتاح/قيمة (انظر `SettingKeys`) |
| `backup_logs` | سجل عمليات النسخ |

### أثر أنواع المعاملات على الرصيد

| النوع | الرصيد | في التقارير والميزانية؟ |
|---|---|---|
| `income` دخل | + | نعم |
| `expense` مصروف | − | نعم |
| `transfer` تحويل | − المصدر، + الوجهة | لا |
| `adjustment` تسوية | ± (مبلغ موقَّع) | لا |
| `debtOut` حركة دين (خرج المال) | − | لا |
| `debtIn` حركة دين (دخل المال) | + | لا |

### حركات الديون (قاعدة 3.12.4)

| الحدث | «لي» (أقرضت) | «عليّ» (اقترضت) |
|---|---|---|
| إنشاء دين مرتبط بحساب | `debtOut` | `debtIn` |
| دفعة مرتبطة بحساب | `debtIn` | `debtOut` |
| بيع/شراء بالآجل (بدون حساب) | الدفتر فقط — لا حركة | الدفتر فقط — لا حركة |

## 5) ربط المتطلبات بالكود

| المتطلب | الموضع |
|---|---|
| FR-01, FR-02 الإعداد الأول وقفل العملة | `services/settings_service.dart` (`completeOnboarding`)، `ui/features/onboarding/` |
| FR-03, FR-04 الحسابات والأرشفة | `services/account_service.dart`، مشغّل المنع في `data/database/app_database.dart`، `ui/features/accounts/` |
| FR-05, FR-06 الإظهار التدريجي واقتراح الحساب | `TransactionService.suggestAccount`، `transaction_form_screen.dart`، `home_screen.dart` |
| FR-07…FR-09 المعاملات والتحويل والتراجع | `services/transaction_service.dart`، `ui/features/transactions/` |
| FR-10, FR-27 التسوية وإعادة الاحتساب | `AccountService.adjustBalance / recalculateAll` |
| FR-11 الإيصال | `transaction_form_screen.dart` (`_pickReceipt`) |
| FR-12 البحث والفلترة | `TransactionService.watchFiltered`، `filter_sheet.dart` |
| FR-13 الفئات | `services/category_service.dart`، `ui/features/categories/` |
| FR-14…FR-18 الأشخاص والديون والدفعات والملف المالي | `services/debt_service.dart`، `services/contact_service.dart`، `ui/features/debts/` |
| FR-19 كشف الحساب | `services/statement_service.dart`، `services/export/statement_pdf.dart`، `statement_screen.dart` |
| FR-20 التذكير | `services/notification_service.dart` عبر واجهة `ReminderScheduler` |
| FR-21 الميزانية | `services/budget_service.dart`، `ui/features/budget/` |
| FR-22 لوحة التحكم | `ui/features/home/home_screen.dart` |
| FR-23 التقارير والتصدير | `services/report_service.dart`، `services/export/report_exporter.dart`، `ui/features/reports/` |
| FR-24 القفل | `services/security_service.dart`، `ui/features/security/` |
| FR-25 النسخ الاحتياطي | `services/backup/`، `ui/features/backup/` |
| FR-26 اللغتان والوضع الداكن | `lib/l10n/`، `tool/strings.py`، `ui/theme/` |

## 6) الأمان والخصوصية

- **صفر طلبات شبكة في الوضع الافتراضي**: الخط مضمَّن، لا تحليلات، ولا خادم. الشبكة تُستخدم فقط إذا فعّل المستخدم النسخ السحابي.
- **PIN** يُخزَّن كبصمة PBKDF2-SHA256 مع ملح عشوائي في Keychain/Keystore، ويُقارن بزمن ثابت.
- **النسخة الاحتياطية**: لقطة `VACUUM INTO` ← GZip ← **AES-256-GCM** بمفتاح مشتق من كلمة مرور المستخدم (PBKDF2، 120 ألف دورة). مزوّد السحابة لا يستطيع قراءتها.
- **الاستعادة ذرية**: `ATTACH` ← التحقق من الملف وإصداره (والترحيل إن كان أقدم) ← نسخ الجداول داخل عملية واحدة؛ مع الحفاظ على إعدادات القفل الخاصة بالجهاز.
- `android:allowBackup="false"` حتى لا ينسخ النظام قاعدة البيانات دون علم المستخدم.

## 7) الاختبارات

| المجموعة | ماذا تغطي |
|---|---|
| `test/services/*` | كل قواعد العمل: الأرصدة، الأرشفة، التسوية، الديون والدفعات، الميزانية، التقارير، كشف الحساب، النسخ والاستعادة، التشفير، PIN، التصدير |
| `test/core/*` | تحويل المبالغ وتنسيقها والأرقام الهندية ونطاقات التواريخ |
| `test/ui/app_flow_test.dart` | تدفق كامل: الإعداد الأول ← إضافة مصروف ← تحديث الرئيسية |
| `test/ui/debt_flow_test.dart` | دين جديد ← سداد كامل من الملف المالي |
| `test/ui/all_screens_render_test.dart` | عرض الشاشات الـ19 بالعربية والإنجليزية دون أي خطأ أو تجاوز للعرض |
| `test/ui/interactions_test.dart` | الأرشفة، نافذة الفلترة، إنشاء PIN وتفعيل القفل، عرض الإيصال |
| `test/services/demo_data_test.dart` | البيانات التجريبية متسقة (إعادة الاحتساب لا تجد فرقاً) |
| `integration_test/` (على الجهاز) | التدفقات السابقة على Android/iOS + قاعدة حقيقية بـ WAL + Keystore + نسخ مشفّر لملف وحذف واستعادة + أداء كشف 100 حركة |

الاختبارات تعمل على قاعدة SQLite حقيقية في الذاكرة (`NativeDatabase.memory()`)، فتختبر الـ SQL والمشغّلات والقيود فعلياً.

## 8) قيود معروفة وأعمال مستقبلية

- مزوّدا السحابة (Google Drive و iCloud) يحتاجان إعداداً لمرة واحدة خارج الكود (معرّف OAuth، قدرة iCloud) — انظر `CLOUD_BACKUP_SETUP.md`. لم يُختبرا على أجهزة حقيقية في بيئة التطوير هذه.
- صور الإيصالات لا تُضمَّن في ملف النسخة الاحتياطية حالياً (البيانات النصية كاملة).
- «واتساب» في كشف الحساب يفتح ورقة المشاركة في النظام ويختار المستخدم واتساب منها (لا يمكن إرسال ملف لواتساب مباشرة دون ذلك).
- مؤجل حسب الوثيقة: تعدد العملات (قاعدة البيانات جاهزة)، الأهداف، الفواتير المتكررة، أداة الشاشة الرئيسية، قراءة الإيصالات OCR، التاريخ الهجري.

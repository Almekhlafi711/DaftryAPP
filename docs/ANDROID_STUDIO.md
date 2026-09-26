# تشغيل «دفتري» على Android Studio

## 1) المتطلبات (مرة واحدة)

| الأداة | الإصدار | ملاحظات |
|---|---|---|
| **Flutter SDK** | 3.47.5 أو أحدث (stable) | من https://docs.flutter.dev/get-started/install — أضفه إلى PATH ثم نفّذ `flutter doctor` |
| **Android Studio** | أحدث إصدار مستقر | المشروع يستخدم Android Gradle Plugin 9.1 و Gradle 9.3 |
| **إضافة Flutter** في Android Studio | الأحدث | Settings ← Plugins ← Marketplace ← Flutter (تُثبّت Dart معها) |
| **Android SDK** | Platform 36 + Build-Tools | Settings ← Languages & Frameworks ← Android SDK |
| **الإنترنت** | لأول بناء فقط | لتنزيل مكتبات Gradle ومكتبة SQLite |

تحقق أن كل شيء جاهز:

```bash
flutter doctor
flutter doctor --android-licenses   # اقبل التراخيص
```

## 2) فتح المشروع

1. فك ضغط `DaftryAPP.zip`.
2. في Android Studio: **File ← Open** واختر المجلد **`DaftryAPP/app`** (مجلد `app` تحديداً وليس المجلد الرئيسي).
3. إن طُلب مسار Flutter: Settings ← Languages & Frameworks ← Flutter ← Flutter SDK path.
4. اضغط **Pub get** في الشريط الذي يظهر أعلى `pubspec.yaml`، أو في الطرفية (Terminal) داخل Android Studio:
   ```bash
   flutter pub get
   ```

## 3) إنشاء محاكي (Emulator)

**Device Manager ← + ← Create Virtual Device** ← اختر **Pixel 8** ← صورة نظام **API 35 أو 36 (Google Play)** ← Finish.

> صورة Google Play مفيدة لتجربة تسجيل الدخول بـ Google للنسخ السحابي.

## 4) التشغيل

- اختر المحاكي من قائمة الأجهزة أعلى النافذة، واختر `main.dart`، ثم اضغط **▶ Run**.
- **أول بناء يستغرق عدة دقائق** (تنزيل Gradle والمكتبات)، والبناءات التالية أسرع بكثير.
- **جهاز حقيقي:** فعّل «خيارات المطوّر» و«تصحيح USB» في الهاتف ثم وصّله بالكابل.
- أثناء التشغيل: **Hot Reload ⚡** يطبّق تعديلات الكود فوراً دون إعادة التشغيل.

### بيانات تجريبية للاختبار السريع

في نسخة التطوير (Debug) يظهر في **المزيد ← للمطوّر ← تحميل بيانات تجريبية**: ستة أشهر من المعاملات، ثلاثة حسابات، أربع ميزانيات، وأشخاص بديون (مفتوح، بالآجل، متأخر، مسدَّد). **هذا الزر لا يظهر في نسخة الإصدار.**

## 5) تجهيز المحاكي لاختبار المزايا

| الميزة | الإعداد في المحاكي |
|---|---|
| **البصمة** | إعدادات المحاكي ← Security ← أضف قفل شاشة PIN ثم بصمة. للمس المستشعر: زر **⋯ (Extended controls) ← Fingerprint ← Touch the sensor** |
| **العربية** | من داخل التطبيق: المزيد ← اللغة والمظهر (أو لغة النظام) |
| **الإشعارات** | اسمح بالإشعارات عند الطلب. لتجربة التذكير غيّر وقت الجهاز: Settings ← System ← Date & time |
| **جهات الاتصال** | أضف جهة اتصال من تطبيق Contacts في المحاكي |
| **الكاميرا** | كاميرا المحاكي الافتراضية تكفي لتجربة إرفاق الإيصال |
| **الطباعة** | اختر طابعة «Save as PDF» |
| **نقل ملف النسخة** | View ← Tool Windows ← **Device Explorer** ← `/sdcard/Download` لحفظ الملف على الحاسوب، واسحب أي ملف وأفلته فوق نافذة المحاكي لنسخه إلى Download |
| **واتساب** | غير موجود في المحاكي؛ تظهر بقية تطبيقات المشاركة. جرّب واتساب على هاتف حقيقي |
| **بدون إنترنت** | اسحب شريط الإشعارات ← وضع الطيران |

## 6) تشغيل الاختبارات الآلية

| النوع | كيف | العدد |
|---|---|---|
| **اختبارات الوحدة والواجهة** (على الحاسوب) | انقر بالزر الأيمن على مجلد `test` ← **Run 'tests in test'**، أو `flutter test` | 81 اختباراً |
| **اختبارات على المحاكي/الجهاز** | شغّل المحاكي، افتح `integration_test/app_test.dart` واضغط ▶ بجانب `main`، أو `flutter test integration_test` | تدفقات كاملة + كل الشاشات + فحوص الجهاز |

اختبارات الجهاز تفحص أشياء لا تعمل إلا على Android فعلياً: قاعدة البيانات الحقيقية (WAL)، **التخزين الآمن Keystore**، **النسخ المشفّر والاستعادة بملف**، و**قياس أداء كشف 100 حركة (أقل من 3 ثوانٍ)**. كلها تستخدم قواعد بيانات مؤقتة فلا تمس بياناتك.

## 7) بناء ملف APK لتثبيته على هاتف

```bash
flutter build apk --release
```

الملف: `app/build/app/outputs/flutter-apk/app-release.apk` — انسخه للهاتف وثبّته.

> النسخة موقّعة حالياً بمفتاح التطوير، وهذا يكفي للتجربة. قبل النشر على Google Play أنشئ مفتاح توقيع خاصاً: https://docs.flutter.dev/deployment/android

## 8) حل المشكلات الشائعة

| الرسالة | الحل |
|---|---|
| `The current Dart SDK version is ... requires ^3.13.4` | حدّث Flutter: `flutter upgrade` |
| `flutter upgrade` على Windows: `Rename-Item ... being used by another process` | أغلق Android Studio و VS Code تماماً، وأنهِ `dart.exe` من مدير المهام، ثم نفّذ `flutter upgrade` من PowerShell خارجي. إن تكرر: احذف مجلد `flutter\bin\cache` ثم `flutter --version` |
| خطأ في إصدار Gradle / Android Gradle Plugin | حدّث Android Studio لأحدث إصدار مستقر |
| `NDK not configured` أو `No version of NDK matched` | SDK Manager ← SDK Tools ← فعّل **NDK (Side by side)** |
| فشل تنزيل `sqlite3` أثناء البناء | أول بناء يحتاج إنترنت للوصول إلى github.com |
| `Unsupported class file major version` | Settings ← Build Tools ← Gradle ← Gradle JDK: اختر **JBR 21** أو **17** |
| البصمة لا تظهر | أضف قفل شاشة وبصمة في إعدادات المحاكي أولاً، ثم فعّل «الفتح بالبصمة» داخل التطبيق |
| أي خطأ آخر في البناء | انسخ نص الخطأ كاملاً من نافذة **Build** وأرسله لي |

# إعداد النسخ الاحتياطي السحابي (اختياري)

التطبيق يعمل بالكامل دون هذه الخطوات؛ النسخ المحلي (تصدير/استيراد ملف `.dftry` مشفّر) متاح دائماً.
هذه الخطوات لمرة واحدة من المطوّر لتفعيل الرفع إلى حساب المستخدم الشخصي.

## Google Drive (Android و iOS)

يحفظ التطبيق النسخ في مجلد `appDataFolder` — مجلد مخفي خاص بالتطبيق — بصلاحية `drive.appdata` فقط (أضيق صلاحية ممكنة).

1. في [Google Cloud Console](https://console.cloud.google.com/) أنشئ مشروعاً وفعّل **Google Drive API**.
2. اضبط **OAuth consent screen** وأضف النطاق `https://www.googleapis.com/auth/drive.appdata`.
3. أنشئ معرّفات OAuth:
   - **Android**: اسم الحزمة `com.daftry.daftry` مع بصمة SHA-1 لمفتاح التوقيع (`keytool -list -v -keystore <keystore>`).
   - **iOS**: معرّف الحزمة `com.daftry.daftry`.
   - **Web application**: هذا هو `serverClientId` الذي يحتاجه Android.
4. **iOS** — أضف إلى `app/ios/Runner/Info.plist`:
   ```xml
   <key>GIDClientID</key>
   <string>IOS_CLIENT_ID.apps.googleusercontent.com</string>
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array><string>com.googleusercontent.apps.IOS_CLIENT_ID</string></array>
     </dict>
   </array>
   ```
5. شغّل أو ابنِ التطبيق مع معرّف الويب:
   ```bash
   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=WEB_CLIENT_ID.apps.googleusercontent.com
   ```

## iCloud (iOS فقط)

1. افتح `app/ios/Runner.xcworkspace` في Xcode.
2. **Runner ← Signing & Capabilities ← + Capability ← iCloud**، وفعّل **iCloud Documents**، وأضف الحاوية `iCloud.com.daftry.daftry` (أو غيّرها في `Runner.entitlements` و `Info.plist` لتطابق حسابك).
3. تأكد أن `Runner.entitlements` مرتبط بالهدف (Xcode يربطه تلقائياً عند إضافة القدرة).

التنفيذ الأصلي في `app/ios/Runner/AppDelegate.swift` (`ICloudBackupChannel`) ويتصل به `lib/services/backup/icloud_provider.dart` عبر القناة `daftry/icloud_backup`.

## كيف يعمل التشفير؟

- عند أول تفعيل يطلب التطبيق **كلمة مرور تشفير** ويحفظها في التخزين الآمن للجهاز (للنسخ المجدول).
- الملف: لقطة SQLite ← GZip ← AES-256-GCM بمفتاح PBKDF2 من كلمة المرور.
- للاستعادة على جهاز جديد يحتاج المستخدم كلمة المرور نفسها — **لا يمكن استرجاعها إن نُسيت**.

## إضافة مزوّد جديد (Dropbox مثلاً)

1. أنشئ صنفاً يحقق `CloudProvider` في `lib/services/backup/`.
2. أضف قيمة في `BackupProvider` (`lib/domain/enums.dart`) — أضف فقط ولا تغيّر القيم الموجودة.
3. سجّله في `cloudProvidersProvider` داخل `lib/services/providers.dart`، وأضف بطاقته في `backup_screen.dart`.

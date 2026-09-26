// =============================================================================
// اختبارات تعمل على المحاكي أو الجهاز الحقيقي (Integration tests).
//
// التشغيل من Android Studio: شغّل المحاكي ثم افتح هذا الملف واضغط ▶ بجانب main،
// أو من الطرفية داخل مجلد app:
//     flutter test integration_test
//
// تشمل: تدفقات الواجهة الكاملة، عرض كل الشاشات باللغتين، الأرشفة والفلترة
// والقفل برمز PIN، والنسخ الاحتياطي والاستعادة وقياس الأداء على الجهاز نفسه.
// كل الاختبارات تستخدم قاعدة بيانات في الذاكرة فلا تمس بيانات التطبيق الحقيقية.
// =============================================================================

import 'package:integration_test/integration_test.dart';

import '../test/ui/all_screens_render_test.dart' as all_screens;
import '../test/ui/app_flow_test.dart' as app_flow;
import '../test/ui/debt_flow_test.dart' as debt_flow;
import '../test/ui/interactions_test.dart' as interactions;
import 'device_checks_test.dart' as device_checks;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  app_flow.main();
  debt_flow.main();
  interactions.main();
  all_screens.main();
  device_checks.main();
}

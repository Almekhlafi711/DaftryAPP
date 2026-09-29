// =============================================================================
// فتح الروابط الخارجية (واتساب، الاتصال، إنستغرام) في تطبيقاتها الأصلية.
// =============================================================================

import 'package:url_launcher/url_launcher.dart';

class ExternalLinkService {
  const ExternalLinkService();

  /// يفتح الرابط خارج التطبيق. يعيد false إن لم يوجد تطبيق يفتحه.
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}

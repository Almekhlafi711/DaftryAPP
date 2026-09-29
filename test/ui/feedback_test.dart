// كل رمز خطأ في قواعد العمل له رسالة مترجمة بالعربية والإنجليزية.
import 'package:daftry/core/errors/app_exception.dart';
import 'package:daftry/l10n/app_localizations.dart';
import 'package:daftry/ui/widgets/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in const [Locale('ar'), Locale('en')]) {
    test('رسائل الأخطاء مترجمة (${locale.languageCode})', () {
      final l10n = lookupAppLocalizations(locale);
      final messages = {
        for (final e in BusinessError.values)
          e: errorMessage(
            l10n,
            BusinessException(e, 1500),
            formatAmount: (m) => '$m',
          ),
      };
      for (final entry in messages.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key.name);
      }
      // رسالة تجاوز المتبقي تتضمن المبلغ.
      expect(messages[BusinessError.paymentExceedsRemaining], contains('1500'));
      // الأخطاء غير المعروفة لها رسالة عامة.
      expect(errorMessage(l10n, StateError('x')), l10n.errUnexpected);
    });
  }
}

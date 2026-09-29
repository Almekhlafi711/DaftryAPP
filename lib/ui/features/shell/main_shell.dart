// =============================================================================
// الهيكل الرئيسي: شريط تنقل سفلي بأربعة تبويبات وزر إضافة عائم دائم في المنتصف.
// الترتيب يتبع اتجاه اللغة: في العربية «الرئيسية» أقصى اليمين.
//
// زر الرجوع في النظام (Android):
//   - الصفحات المفتوحة فوق التبويبات تُغلق أولاً (يتولاها المُوجّه).
//   - في أي تبويب غير «الرئيسية» ← يعود إلى «الرئيسية».
//   - في «الرئيسية» ← رسالة «اضغط رجوع مرة أخرى للخروج»، والضغطة الثانية خلال
//     ثانيتين تخرج من التطبيق (السلوك المعتاد في التطبيقات العالمية).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  /// المهلة بين ضغطتي الرجوع للخروج.
  static const exitWindow = Duration(seconds: 2);

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  DateTime? _lastBack;

  StatefulNavigationShell get shell => widget.shell;

  void _onBack() {
    // من أي تبويب آخر: الرجوع إلى «الرئيسية».
    if (shell.currentIndex != 0) {
      _lastBack = null;
      shell.goBranch(0);
      return;
    }
    final now = DateTime.now();
    final last = _lastBack;
    if (last != null && now.difference(last) <= MainShell.exitWindow) {
      SystemNavigator.pop();
      return;
    }
    _lastBack = now;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.pressBackAgainToExit),
        duration: MainShell.exitWindow,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = context.colors;
    final items = [
      (Icons.home_outlined, Icons.home_rounded, l10n.navHome),
      (Icons.list_alt_outlined, Icons.list_alt_rounded, l10n.navTransactions),
      (Icons.people_outline_rounded, Icons.people_rounded, l10n.navDebts),
      (Icons.settings_outlined, Icons.settings_rounded, l10n.navMore),
    ];

    Widget tab(int index) {
      final (icon, activeIcon, label) = items[index];
      final selected = shell.currentIndex == index;
      return Expanded(
        child: InkResponse(
          // الضغط على التبويب الحالي يعيده لبدايته.
          onTap: () => shell.goBranch(index, initialLocation: selected),
          child: Semantics(
            selected: selected,
            button: true,
            label: label,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  color: selected ? c.primary : c.textSecondary,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? c.primary : c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  tab(0),
                  tab(1),
                  // زر الإضافة الدائم (FR-22 / الشاشة 3 — العنصر 5)
                  Expanded(
                    child: Center(
                      child: Tooltip(
                        message: l10n.addTransaction,
                        child: Material(
                          color: c.brand,
                          elevation: 4,
                          shadowColor: c.primary.withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () =>
                                context.push(AppRoutes.newTransaction()),
                            child: const SizedBox(
                              width: 56,
                              height: 52,
                              child: Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  tab(2),
                  tab(3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

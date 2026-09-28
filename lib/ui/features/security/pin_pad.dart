// =============================================================================
// لوحة إدخال رمز PIN من 4 أرقام مع نقاط تُظهر عدد الأرقام المدخلة.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';

class PinPad extends StatefulWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.onCompleted,
    this.error,
    this.extraAction,
  });

  final String title;

  /// يُستدعى عند إدخال 4 أرقام. أعد true لمسح الإدخال (عند الخطأ مثلاً).
  final Future<bool> Function(String pin) onCompleted;
  final String? error;

  /// زر إضافي في الخانة اليسرى السفلية (مثل البصمة).
  final Widget? extraAction;

  @override
  State<PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<PinPad> {
  static const length = 4;
  String _pin = '';

  Future<void> _press(String digit) async {
    if (_pin.length >= length) return;
    HapticFeedback.selectionClick();
    setState(() => _pin += digit);
    if (_pin.length == length) {
      final clear = await widget.onCompleted(_pin);
      if (clear && mounted) setState(() => _pin = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget key(String d) => SizedBox(
      width: 76,
      height: 76,
      child: TextButton(
        style: TextButton.styleFrom(shape: const CircleBorder()),
        onPressed: () => _press(d),
        child: Text(d, style: TextStyle(fontSize: 28, color: c.textPrimary)),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < length; i++)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < _pin.length ? c.primary : Colors.transparent,
                  border: Border.all(color: c.primary, width: 2),
                ),
              ),
          ],
        ),
        SizedBox(
          height: 28,
          child: widget.error == null
              ? null
              : Center(
                  child: Text(
                    widget.error!,
                    style: TextStyle(color: c.expense),
                  ),
                ),
        ),
        // لوحة الأرقام دائماً بترتيب الهاتف (LTR) بغض النظر عن لغة الواجهة.
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [for (final d in row) key(d)],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 76, height: 76, child: widget.extraAction),
                  key('0'),
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: IconButton(
                      icon: Icon(
                        Icons.backspace_outlined,
                        color: c.textSecondary,
                      ),
                      onPressed: _pin.isEmpty
                          ? null
                          : () => setState(
                              () => _pin = _pin.substring(0, _pin.length - 1),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppAlertDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const AppAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: '.SF Pro Text', // iOS system font
          fontWeight: FontWeight.w600,
        ),
      ),
      content: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: '.SF Pro Text',
          color: CupertinoColors.label,
          fontSize: 13,
        ),
        child: content,
      ),
      actions: actions,
    );
  }
}

Future<T?> showAppAlertDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
}) {
  return showCupertinoDialog<T>(
    context: context,
    barrierDismissible: true,
    builder: (context) => AppAlertDialog(
      title: title,
      content: content,
      actions: actions,
    ),
  );
}

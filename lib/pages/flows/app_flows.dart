import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/pages/other/notifications.dart';

Future<void> runAppFlow(
  BuildContext context,
  FutureOr<void> Function() action,
) async {
  try {
    await Future.sync(action);
  } catch (e, s) {
    final AppException error = e is AppException ? e : AppException.unknown(cause: e, stackTrace: s);

    if (!context.mounted) return;
    await Notify.dialog(
      context: context,
      type: NotificationType.error,
      title: 'Error occurred!',
      content: Text(error.toString()),
    );
  }
}

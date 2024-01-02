import 'package:flutter/material.dart';


Future<bool?> simpleDialog ({
  required BuildContext context,
  Widget? title,
  Widget? content,
  bool okButton = true,
  bool Function()? onPressOk,
  bool cancelButton = true,
  bool barrierDismissible = false
}) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: title,
        content: content,
        actions: <Widget>[
          if (cancelButton) ...[
            IconButton(
              icon: const Icon(Icons.cancel, color: Colors.redAccent),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],

          if (okButton) ...[
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green),
              onPressed: () {
                if (onPressOk != null) {
                  if (!onPressOk.call()) return;
                }
                Navigator.of(context).pop(true);
              },
            ),
          ],

        ],
      );
    },
  );
}

Future<bool> warningDialog (BuildContext context, String message) async {
  final result = await simpleDialog(
    context: context,
    title: Text(message),
  );

  if (result == null || !result) return false;
  return true;
}
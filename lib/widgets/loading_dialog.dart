import 'package:flutter/material.dart';

//to show our dialog
Future<void> showLoadingDialog(BuildContext context, String title) {
  return showDialog(
    barrierDismissible: false,
    context: context,
    builder: (context) {
      return SimpleDialog(title: Text(title), children: [
        const Center(
          child: CircularProgressIndicator(),
        ),
      ]);
    },
  );
}

// to hide our current dialog
void hideLoadingDialog(BuildContext context) {
  Navigator.of(context).pop();
}

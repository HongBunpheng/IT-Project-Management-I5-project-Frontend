import 'package:flutter/material.dart';
import 'snackbar.dart';

class Helpers {
  static void showSnackBar(BuildContext context, String message) {
    CustomSnackBar.info(title: message);
  }
}

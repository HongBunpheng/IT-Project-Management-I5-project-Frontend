import 'package:flutter/material.dart';

class Responsive {
  static double getPadding(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width > 600) {
      return 32.0;
    } else {
      return 16.0;
    }
  }
}

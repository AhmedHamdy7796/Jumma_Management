import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Colors.indigo;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
  static const Color red = Colors.red;
  static const Color green = Colors.green;
  static const Color blue = Colors.blue;
  static const Color orange = Colors.orange;
  static const Color purple = Colors.purple;
  static const Color teal = Colors.teal;

  static const Color success = Colors.green;
  static const Color error = Colors.red;

  static Color get lightGrey => Colors.grey.shade100;
  static Color get darkGrey => Colors.grey.shade600;
  static Color get primaryOp10 => primary.withOpacity(0.1);
  static Color get successOp10 => success.withOpacity(0.1);
  static Color get errorOp10 => error.withOpacity(0.1);
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppText {
  AppText._();

  static Color _text(BuildContext context, {Color? override}) {
    if (override != null) return override;
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : AppColors.lightTextPrimary;
  }

  static Color _textSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : AppColors.lightTextSecondary;
  }

  static const double _defaultHeight = 1.35;

  static TextStyle display(
    double size, {
    Color? color,
    BuildContext? context,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: 0.5,
        color: color ?? (context != null ? _text(context) : AppColors.darkTextPrimary),
      );

  static TextStyle displayItalic(
    double size, {
    Color? color,
    BuildContext? context,
  }) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        height: 1.3,
        letterSpacing: 0.3,
        color:
            color ?? (context != null ? _textSecondary(context) : AppColors.darkTextSecondary),
      );

  static TextStyle script(double size, {Color? color}) =>
      GoogleFonts.dancingScript(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1.2,
        color: color ?? AppColors.orangePrimary,
      );

  static TextStyle body(
    double size, {
    Color? color,
    BuildContext? context,
  }) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w400,
        height: _defaultHeight,
        letterSpacing: 0.2,
        color: color ?? (context != null ? _text(context) : AppColors.darkTextPrimary),
      );

  static TextStyle bodySemiBold(
    double size, {
    Color? color,
    BuildContext? context,
  }) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: _defaultHeight,
        letterSpacing: 0.2,
        color: color ?? (context != null ? _text(context) : AppColors.darkTextPrimary),
      );

  static TextStyle bodyBold(
    double size, {
    Color? color,
    BuildContext? context,
  }) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: _defaultHeight,
        letterSpacing: 0.2,
        color: color ?? (context != null ? _text(context) : AppColors.darkTextPrimary),
      );

  static TextStyle label(
    double size, {
    Color? color,
    BuildContext? context,
  }) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: _defaultHeight,
        letterSpacing: 0.5,
        color: color ?? (context != null ? _textSecondary(context) : AppColors.darkTextSecondary),
      );
}


import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppText {
  AppText._();

  static TextStyle display(double size, {Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle displayItalic(double size, {Color? color}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: color ?? AppColors.textSecondary,
        letterSpacing: 0.3,
      );

  static TextStyle script(double size, {Color? color}) =>
      GoogleFonts.dancingScript(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.primary,
      );

  static TextStyle body(double size, {Color? color}) => GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodySemiBold(double size, {Color? color}) =>
      GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle bodyBold(double size, {Color? color}) => GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  static TextStyle label(double size, {Color? color}) => GoogleFonts.nunito(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textSecondary,
        letterSpacing: 0.8,
      );
}


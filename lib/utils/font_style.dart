import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class FontStyle {
  static const String clashDisplay = 'Clash Display';

  // Clash Display Font Styles
  // Suitable for children: slightly larger and very legible

  // Display/Heading Styles
  TextStyle get clashDisplayBold36 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 36,
    fontWeight: FontWeight.w700,
  );

  TextStyle get clashDisplayBold34 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 34,
    fontWeight: FontWeight.w700,
  );

  TextStyle get clashDisplayBold30 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 30,
    fontWeight: FontWeight.w600,
  );
  TextStyle get clashDisplayBold24 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );
  TextStyle get clashDisplayBold18 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );
  TextStyle get clashDisplayBold16 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );
  TextStyle get clashDisplayBold14 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  TextStyle get clashDisplayBold12 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  TextStyle get clashDisplaySemiBold24 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );
  TextStyle get clashDisplaySemiBold20 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  TextStyle get clashDisplaySemiBold18 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );
  TextStyle get clashDisplaySemiBold16 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
  TextStyle get clashDisplaySemiBold14 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  TextStyle get clashDisplaySemiBold12 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  TextStyle get clashDisplayMedium20 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );
  TextStyle get clashDisplayMedium14 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  TextStyle get clashDisplayMedium12 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  TextStyle get clashDisplayMedium10 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  // Body Styles
  TextStyle get clashDisplayRegular18 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  TextStyle get clashDisplayRegular16 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  TextStyle get clashDisplayRegular14 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  TextStyle get clashDisplayRegular12 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );
  TextStyle get clashDisplayRegular10 => const TextStyle(
    fontFamily: clashDisplay,
    fontSize: 10,
    fontWeight: FontWeight.w400,
  );

  // Aliases for compatibility with existing code (dmSans -> Clash Display)
  TextStyle get dmSansBold30 => clashDisplayBold30;
  TextStyle get dmSansRegular14 => clashDisplayRegular14;
  TextStyle get dmSansBold16 =>
      clashDisplayRegular16.copyWith(fontWeight: FontWeight.w700);
}

// Font Weight Constants
const FontWeight light = FontWeight.w300;
const FontWeight regular = FontWeight.w400;
const FontWeight medium = FontWeight.w500;
const FontWeight semiBold = FontWeight.w600;
const FontWeight bold = FontWeight.w700;

// Helper function to match the user's 'clashDisplay()' usage
TextStyle clashDisplay({double? fontsize, FontWeight? fontWeight}) {
  return TextStyle(
    fontFamily: FontStyle.clashDisplay,
    fontSize: fontsize,
    fontWeight: fontWeight,
  );
}

// Global instance to use in widgets
final fontStyle = FontStyle();

// Extensions to support the chaining style seen in the project
extension TextStyleExtensions on TextStyle {
  TextStyle textColor(Color color) => copyWith(color: color);

  // Adding more common helpers for the chaining style
  TextStyle letterSpace(double space) => copyWith(letterSpacing: space);
  TextStyle size(double size) => copyWith(fontSize: size);
  TextStyle weight(FontWeight weight) => copyWith(fontWeight: weight);
  TextStyle italic() => copyWith(fontStyle: ui.FontStyle.italic);
}

// Widget Extensions for padding
extension WidgetExtensions on Widget {
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }

  Widget paddingAll(double padding) {
    return Padding(padding: EdgeInsets.all(padding), child: this);
  }
}

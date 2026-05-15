import 'package:flutter/material.dart';

class AppColors {
  final BuildContext context;
  AppColors(this.context);

  // Define your colors here
  Color get darkText => const Color(0xFF1E1E1E);
  Color get lightText => const Color(0xFF9E9E9E);
  Color get white => Colors.white;
  Color get black => Colors.black;
  Color get primary => const Color(0xFFD42554); // #DA2A5A
  Color get primaryDark => const Color(0xFF851F3A); // Darker version of primary

  // New Colors
  Color get secondary => const Color(0xFFEB3667); // #EB3667
  Color get cyan => const Color(0xFF0CA1CF); // #0CA1CF
  Color get grey => const Color(0xFFCDCDCD); // #CDCDCD
  Color get bgGrey => const Color(0xFFF9F9F9); // #F9F9F9
  Color get silver => const Color(0xFFC0C0C0); // #C0C0C0
  Color get green => const Color(0xFF1A9E16); // #1A9E16
  Color get red => const Color(0xFFC61D1D); // #C61D1D
  Color get darkGrey => const Color(0xFF292929); // #292929
  Color get textSecondary => const Color(0xFF767779);
  Color get textGrey => const Color(0xFFABABAB);
  Color get textMediumGrey => const Color(0xFF4E4E4E);
  Color get versionGrey => const Color(0xFF535862); // #273B93
  Color get orange => const Color(0xFFEF6C00); // #EF6C00
  Color get orangeLight => const Color(0xFFFFF3E0); // #FFF3E0
  Color get transparent => Colors.transparent;

  // Material Grey Shades
  Color get grey50 => Colors.grey.shade50;
  Color get grey100 => Colors.grey.shade100;
  Color get grey200 => Colors.grey.shade200;
  Color get grey300 => Colors.grey.shade300;
  Color get grey400 => Colors.grey.shade400;
  Color get grey500 => Colors.grey.shade500;
  Color get grey600 => Colors.grey.shade600;
  Color get grey700 => Colors.grey.shade700;
  Color get grey800 => Colors.grey.shade800;
  Color get grey900 => Colors.grey.shade900;

  // Translucent Material Colors
  Color get black26 => Colors.black26;
  Color get black45 => Colors.black45;
  Color get black54 => Colors.black54;
  Color get black87 => Colors.black87;
  Color get white24 => Colors.white24;
  Color get white38 => Colors.white38;
}

// Helper function to access colors
AppColors appColor(BuildContext context) => AppColors(context);

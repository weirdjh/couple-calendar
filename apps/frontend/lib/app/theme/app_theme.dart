import 'package:flutter/material.dart';

class AppPalette {
  const AppPalette._();

  static const ivory = Color(0xFFF8FAFC);
  static const paper = Color(0xFFFFFFFF);
  static const shell = Color(0xFFF1F5F9);
  static const ink = Color(0xFF263247);
  static const mutedInk = Color(0xFF64748B);
  static const teal = Color(0xFF4169E1);
  static const deepTeal = Color(0xFF304C9A);
  static const rose = Color(0xFFE85D75);
  static const softRose = Color(0xFFFBE9ED);
  static const sage = Color(0xFF16A085);
  static const violet = Color(0xFF7C6EE6);
  static const sky = Color(0xFF3C8DCC);
  static const line = Color(0xFFD8E0EA);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final colorScheme = const ColorScheme(
      brightness: Brightness.light,
      primary: AppPalette.teal,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE9EEFF),
      onPrimaryContainer: AppPalette.deepTeal,
      secondary: AppPalette.violet,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEFEDFF),
      onSecondaryContainer: Color(0xFF4B4666),
      tertiary: AppPalette.sage,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFFE3F6F1),
      onTertiaryContainer: Color(0xFF315C56),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF410002),
      surface: AppPalette.paper,
      onSurface: AppPalette.ink,
      surfaceContainerHighest: AppPalette.shell,
      onSurfaceVariant: AppPalette.mutedInk,
      outline: Color(0xFFAAB7C7),
      outlineVariant: AppPalette.line,
      shadow: Color(0x14000000),
      scrim: Colors.black,
      inverseSurface: AppPalette.deepTeal,
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFFFFFFFF),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppPalette.ivory,
      fontFamilyFallback: const [
        'Apple SD Gothic Neo',
        'Noto Sans KR',
        'Roboto',
      ],
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppPalette.ivory,
        foregroundColor: AppPalette.ink,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppPalette.ink,
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.ivory,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppPalette.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppPalette.line),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppPalette.shell,
        selectedColor: Color(0xFFEDEBF4),
        side: const BorderSide(color: AppPalette.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.ivory,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        titleTextStyle: const TextStyle(
          color: AppPalette.ink,
          fontSize: 22,
          fontWeight: FontWeight.w900,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.line,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppPalette.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.teal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        backgroundColor: AppPalette.teal,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppPalette.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppPalette.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppPalette.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppPalette.teal, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppPalette.mutedInk),
        prefixIconColor: AppPalette.mutedInk,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: AppPalette.ink,
        textColor: AppPalette.ink,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: AppPalette.paper,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? AppPalette.teal : AppPalette.mutedInk,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppPalette.teal : AppPalette.mutedInk,
            size: selected ? 25 : 23,
          );
        }),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.ink,
          side: const BorderSide(color: AppPalette.line),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.deepTeal,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.ink,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          color: AppPalette.ink,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          color: AppPalette.ink,
          letterSpacing: 0,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          color: AppPalette.mutedInk,
          letterSpacing: 0,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

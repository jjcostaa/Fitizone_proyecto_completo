import 'package:flutter/material.dart';

class AppTheme {
  // === PALETA SOBRIA: NEGRO MATE + BLANCO LIMPIO + ROJO CONTROLADO ===
  // Superficies neutras (80–85% de la interfaz)
  static const Color bgDark = Color(0xFF0D0D0F);
  static const Color surfaceDark = Color(0xFF141417);
  static const Color cardDark = Color(0xFF18181C);
  static const Color cardElevated = Color(0xFF202026);
  static const Color borderSubtle = Color(0xFF27272D);

  // Acento rojo deportivo mate (sin brillo luminoso ni neón)
  static const Color primaryCrimson = Color(0xFFD92638);
  static const Color neonRed = primaryCrimson; // Alias de compatibilidad en tono mate sobrio
  static const Color primaryOrange = primaryCrimson; // Alias para compatibilidad interna
  static const Color primaryMuted = Color(0xFF2A1417);
  static const Color accentRed = Color(0xFFB91C2E);

  static List<BoxShadow> get neonBoxShadow => const [];

  static Border get neonBorder => Border.all(
        color: borderSubtle,
        width: 1.0,
      );

  // Estados semánticos discretos
  static const Color successGreen = Color(0xFF2E9E5B);
  static const Color warningAmber = Color(0xFFD99116);
  static const Color infoBlue = Color(0xFF8E9AAF);

  // Textos neutros con alto contraste cómodo
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);

  // Constantes de espaciado y radios coherentes
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bgDark,
      dividerColor: borderSubtle,
      colorScheme: const ColorScheme.dark(
        primary: primaryCrimson,
        secondary: textPrimary,
        surface: surfaceDark,
        error: primaryCrimson,
        onPrimary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: base.textTheme.copyWith(
        headlineMedium: const TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          height: 1.2,
        ),
        titleLarge: const TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
          height: 1.3,
        ),
        titleMedium: const TextStyle(
          color: textPrimary,
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
        bodyMedium: const TextStyle(
          color: textPrimary,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: const TextStyle(
          color: textSecondary,
          fontSize: 12.5,
          height: 1.4,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shadowColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        labelStyle: const TextStyle(color: textSecondary, fontSize: 13.5),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryCrimson, width: 1.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryCrimson, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primaryCrimson, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryCrimson,
          foregroundColor: Colors.white,
          disabledBackgroundColor: cardElevated,
          disabledForegroundColor: textMuted,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: borderSubtle, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: primaryCrimson,
        disabledColor: surfaceDark,
        side: const BorderSide(color: borderSubtle, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12.5, fontWeight: FontWeight.w600),
        secondaryLabelStyle: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: bgDark,
        surfaceTintColor: Colors.transparent,
        indicatorColor: cardElevated,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: textPrimary, fontSize: 11, fontWeight: FontWeight.w700);
          }
          return const TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.w500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryCrimson, size: 22);
          }
          return const IconThemeData(color: textMuted, size: 21);
        }),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: primaryCrimson,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: borderSubtle,
        labelColor: textPrimary,
        unselectedLabelColor: textMuted,
        labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardElevated,
        contentTextStyle: const TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13.5),
        behavior: SnackBarBehavior.floating,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
    );
  }
}

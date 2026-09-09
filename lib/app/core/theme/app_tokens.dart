import 'package:flutter/material.dart';

/// VAMOS OPS design tokens for the staff app.
///
/// This is the single semantic layer shared with the web dashboard
/// (`apps/dashboard/app/globals.css`): same brand green, same ink, same
/// AA-checked text tones, same 4pt spacing rhythm. Screens should reach for
/// these names instead of raw `Color(0x...)` or bare `fontSize: 11` so a dark
/// theme can later be added by remapping [AppColors] alone.
class AppColors {
  AppColors._();

  // Brand
  static const Color brandGreen = Color(0xFF7AC943);
  static const Color brandInk = Color(0xFF1B1F2A);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSunken = Color(0xFFF4F5F1);
  static const Color surfaceRaised = Color(0xFFF7F8F5);
  static const Color surfaceInverse = brandInk;
  static const Color surfaceInverseRaised = Color(0xFF343A47);

  // Foreground — every value clears 4.5:1 on [surface].
  static const Color onSurface = brandInk; //          15.1:1
  static const Color onSurfaceMuted = Color(0xFF5F6875); //  5.6:1
  static const Color onSurfaceSubtle = Color(
    0xFF656E7A,
  ); // 5.2:1 surface, 4.8:1 sunken
  static const Color onInverse = Color(0xFFFFFFFF);
  static const Color onInverseMuted = Color(0xFFB7BEC8); // 8.1:1 on ink
  static const Color onInverseSubtle = Color(0xFF9AA0AD); // 5.6:1 on ink

  // Primary action
  static const Color primary = brandGreen;
  static const Color onPrimary = Color(0xFF192014); //   11.4:1 on primary
  static const Color primarySubtle = Color(0xFFEDF8E6);
  static const Color primaryText = Color(0xFF3D7A18); // 5.3:1 — green TEXT
  static const Color primaryOnInverse = Color(0xFFA9E47E);

  // Status — decorative tone + subtle background + AA text tone
  static const Color success = Color(0xFF4D9822);
  static const Color successSubtle = Color(0xFFEDF8E6);
  static const Color successText = Color(0xFF3D7A18);
  static const Color warning = Color(0xFFD99B2B);
  static const Color warningSubtle = Color(0xFFFFF6DF);
  static const Color warningText = Color(0xFF8F5E02); // 5.6:1
  static const Color danger = Color(0xFFD84B4B);
  static const Color dangerSubtle = Color(0xFFFFF0EF);
  static const Color dangerText = Color(0xFFB3261E); // 6.5:1
  static const Color info = Color(0xFF3B78CE);
  static const Color infoSubtle = Color(0xFFEDF4FF);
  static const Color infoText = Color(0xFF2C5DA3);
  static const Color accent = Color(0xFF7A5AF8);

  // Lines
  static const Color border = Color(0xFFE5E8E1);
  static const Color borderSubtle = Color(0xFFEEF0EC);
  static const Color borderStrong = Color(0xFFCDD1CB);

  // Overlays
  static const Color scrim = Color(0x8A0F1219); // ~54% — isolates sheets
  static const Color shadow = Color(0x261B1F2A);
}

/// 4pt spacing scale. Pick the tier by hierarchy, not by eye.
class AppSpace {
  AppSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;
  static const double page = 48;
  static const EdgeInsets screen = EdgeInsets.fromLTRB(20, 16, 20, 24);
}

class AppRadius {
  AppRadius._();
  static const double sm = 10;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;
}

/// Type scale in logical pixels. Nothing user-facing goes below [xs];
/// body copy is [base]. Text scales with the OS setting because these are
/// applied through [TextStyle], never through fixed-height boxes.
class AppText {
  AppText._();
  static const double xs = 12; // micro labels, uppercase eyebrows only
  static const double sm = 13; // dense meta
  static const double base = 14; // list body, secondary
  static const double md = 15; // primary body
  static const double lg = 16; // inputs, card titles
  static const double xl = 18;
  static const double xxl = 22;
  static const double display = 26;
  static const double hero = 30;
  static const double heroLg = 34;

  static const String bodyFamily = 'Barlow';
  static const String displayFamily = 'BarlowCondensed';
}

/// Minimum interactive size — Apple HIG 44pt, Material 48dp. Use the larger.
const double kTapMin = 48;

/// Motion tokens shared across sheets, buttons and page transitions.
class AppMotion {
  AppMotion._();
  static const Duration fast = Duration(milliseconds: 140);
  static const Duration base = Duration(milliseconds: 220);
  static const Duration slow = Duration(milliseconds: 320);
  static const Curve enter = Cubic(0.16, 1, 0.3, 1);
  static const Curve exit = Cubic(0.65, 0, 0.35, 1);
}

/// Builds the light Material 3 theme from the tokens above.
ThemeData buildVamosTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.brandGreen,
        brightness: Brightness.light,
        surface: AppColors.surface,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        onSurface: AppColors.onSurface,
        onSurfaceVariant: AppColors.onSurfaceMuted,
        outline: AppColors.border,
        outlineVariant: AppColors.borderSubtle,
        error: AppColors.dangerText,
        errorContainer: AppColors.dangerSubtle,
        onErrorContainer: AppColors.dangerText,
      );

  const body = TextStyle(
    fontFamily: AppText.bodyFamily,
    color: AppColors.onSurface,
    height: 1.45,
  );
  const display = TextStyle(
    fontFamily: AppText.displayFamily,
    color: AppColors.onSurface,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.2,
  );

  final textTheme = TextTheme(
    displayLarge: display.copyWith(fontSize: AppText.heroLg),
    displayMedium: display.copyWith(fontSize: AppText.hero),
    displaySmall: display.copyWith(fontSize: AppText.display),
    headlineMedium: display.copyWith(fontSize: AppText.xxl),
    headlineSmall: display.copyWith(fontSize: AppText.xl),
    titleLarge: body.copyWith(
      fontSize: AppText.lg,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    titleMedium: body.copyWith(
      fontSize: AppText.md,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    titleSmall: body.copyWith(
      fontSize: AppText.base,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    bodyLarge: body.copyWith(fontSize: AppText.lg),
    bodyMedium: body.copyWith(fontSize: AppText.md),
    bodySmall: body.copyWith(
      fontSize: AppText.base,
      color: AppColors.onSurfaceMuted,
    ),
    labelLarge: body.copyWith(
      fontSize: AppText.md,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    labelMedium: body.copyWith(
      fontSize: AppText.sm,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    labelSmall: body.copyWith(
      fontSize: AppText.xs,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
      height: 1.2,
    ),
  );

  RoundedRectangleBorder shape(double radius) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.surfaceSunken,
    fontFamily: AppText.bodyFamily,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    visualDensity: VisualDensity.standard,
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      space: 1,
      thickness: 1,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.surfaceSunken,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.headlineSmall,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.38),
        disabledForegroundColor: AppColors.onPrimary.withValues(alpha: 0.5),
        minimumSize: const Size.fromHeight(52),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
        shape: shape(AppRadius.lg),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.onSurface,
        minimumSize: const Size(kTapMin, kTapMin),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        side: const BorderSide(color: AppColors.border),
        shape: shape(AppRadius.md),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryText,
        minimumSize: const Size(kTapMin, kTapMin),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
        shape: shape(AppRadius.sm),
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(kTapMin, kTapMin),
        foregroundColor: AppColors.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceRaised,
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceMuted,
      ),
      hintStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.onSurfaceSubtle,
      ),
      helperStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.onSurfaceMuted,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.dangerText,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.dangerText),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.dangerText, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.lg,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      side: const BorderSide(color: AppColors.border),
      labelStyle: textTheme.labelMedium,
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: AppColors.onPrimary,
        fontWeight: FontWeight.w700,
      ),
      checkmarkColor: AppColors.onPrimary,
      shape: shape(AppRadius.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.md,
        vertical: AppSpace.sm,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primarySubtle,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => textTheme.labelMedium!.copyWith(
          color: states.contains(WidgetState.selected)
              ? AppColors.onSurface
              : AppColors.onSurfaceMuted,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.successText
              : AppColors.onSurfaceMuted,
        ),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: AppColors.scrim,
      showDragHandle: true,
      dragHandleColor: AppColors.borderStrong,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xxl),
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: shape(AppRadius.xl),
      titleTextStyle: textTheme.headlineSmall,
      contentTextStyle: textTheme.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceInverse,
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: AppColors.onInverse,
      ),
      behavior: SnackBarBehavior.floating,
      shape: shape(AppRadius.md),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.borderSubtle,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.success
            : AppColors.surface,
      ),
      checkColor: const WidgetStatePropertyAll(AppColors.onInverse),
      side: const BorderSide(color: AppColors.borderStrong, width: 1.5),
      shape: shape(6),
    ),
    listTileTheme: const ListTileThemeData(
      minVerticalPadding: AppSpace.md,
      minTileHeight: kTapMin,
    ),
  );
}

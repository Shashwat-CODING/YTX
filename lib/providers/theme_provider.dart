import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:ytx/providers/player_provider.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeData>((ref) {
  return ThemeNotifier(ref);
});

class ThemeNotifier extends StateNotifier<ThemeData> {
  final Ref ref;

  ThemeNotifier(this.ref) : super(_darkTheme) {
    _listenToMediaChanges();
  }

  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFF0000), // YouTube Red
      secondary: Color(0xFFFFFFFF),
      surface: Color(0xFF1E1E1E),
    ),
    // Use system font (San Francisco on iOS)
    fontFamily: '.SF Pro Text',
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F0F0F),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 17, // iOS standard title size
        fontWeight: FontWeight.w600,
        fontFamily: '.SF Pro Text',
      ),
    ),
  );

  void _listenToMediaChanges() {
    ref.listen(currentMediaItemProvider, (previous, next) async {
      if (next?.value != null && next!.value!.artUri != null) {
        await _updateThemeFromImage(next.value!.artUri.toString());
      } else {
        state = _darkTheme;
      }
    });
  }

  Future<void> _updateThemeFromImage(String imageUrl) async {
    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        maximumColorCount: 20,
      );

      final dominantColor = paletteGenerator.dominantColor?.color ?? const Color(0xFFFF0000);
      final vibrantColor = paletteGenerator.vibrantColor?.color ?? dominantColor;
      final mutedColor = paletteGenerator.mutedColor?.color ?? const Color(0xFF1E1E1E);

      state = ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
        colorScheme: ColorScheme.dark(
          primary: vibrantColor,
          secondary: dominantColor,
          surface: mutedColor.withValues(alpha: 0.5), // Slightly transparent surface
          onPrimary: _getTextColorForBackground(vibrantColor),
          onSurface: Colors.white,
        ),
        fontFamily: '.SF Pro Text',
        useMaterial3: true,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
            TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F0F0F),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: vibrantColor,
          thumbColor: vibrantColor,
          inactiveTrackColor: vibrantColor.withValues(alpha: 0.3),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: vibrantColor,
        ),
      );
    } catch (e) {
      debugPrint('Error generating palette: $e');
      state = _darkTheme;
    }
  }

  Color _getTextColorForBackground(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}

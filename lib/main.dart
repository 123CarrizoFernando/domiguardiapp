import 'package:flutter/material.dart';

import 'theme_controller.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const DomiGuardiaApp());
}

class DomiGuardiaApp extends StatelessWidget {
  const DomiGuardiaApp({super.key});

  @override
  Widget build(BuildContext context) {
    const medicalSkyBlue = Color(0xFF0284C7); // Celeste clínico profesional
    const darkSkyBlue = Color(0xFF38BDF8); // Celeste luminoso para modo noche

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'DomiGuardia Salta',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          // TEMA CLARO (Blanco clínico y celeste)
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: medicalSkyBlue,
              primary: medicalSkyBlue,
              secondary: const Color(0xFF0369A1),
              surface: Colors.white,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Color(0xFF0F172A),
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            cardTheme: CardThemeData(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE0F2FE), width: 1.2),
              ),
            ),
          ),
          // TEMA OSCURO (Azul noche profundo)
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: darkSkyBlue,
              primary: darkSkyBlue,
              secondary: medicalSkyBlue,
              surface: const Color(0xFF1E293B),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0B1120),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
            ),
            cardTheme: CardThemeData(
              color: const Color(0xFF1E293B),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFF334155), width: 1.2),
              ),
            ),
          ),
          home: const LoginScreen(),
        );
      },
    );
  }
}

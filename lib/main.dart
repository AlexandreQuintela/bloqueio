import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuoridorApp());
}

class QuoridorApp extends StatelessWidget {
  const QuoridorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      title: 'Quoridor',
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: const Color(0xFF29C079),
          secondary: const Color(0xFF2A5298),
          surface: const Color(0xFF102542),
        ),
        textTheme: baseTheme.textTheme.apply(fontFamily: 'Roboto'),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        cardTheme: baseTheme.cardTheme.copyWith(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

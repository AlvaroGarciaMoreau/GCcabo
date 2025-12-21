import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gccabo/firebase_options.dart';
import 'package:gccabo/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gccabo/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Load dark mode preference before running the app
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;
  themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'GCcabo',
          theme: ThemeData(
            // Define a ColorScheme with matching brightness to avoid assertion errors
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue, brightness: Brightness.light),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue, brightness: Brightness.dark).copyWith(secondary: Colors.blueAccent),
          ),
          themeMode: themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}


import 'dart:io';
import 'package:amazing_icons/amazing_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/login/login.dart';
import 'package:flutter_application_1/login/splash.dart';
import 'package:flutter_application_1/pages/about.dart';
import 'package:flutter_application_1/pages/calculate.dart';
import 'package:flutter_application_1/pages/home.dart';
import 'package:flutter_application_1/pages/progress.dart';
import 'package:flutter_application_1/pages/settings.dart';
import 'package:flutter_application_1/pages/user_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://lgbdtqnlxxwhvvphvytt.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxnYmR0cW5seHh3aHZ2cGh2eXR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjI4MjA4NjgsImV4cCI6MjA3ODM5Njg2OH0.HdkW8GIZcvMwxyooZ45UPNMq9q7QVaSXavNfcnGlvuA';

// global Supabase client reference (set after initialize)
late final SupabaseClient supabase;

// --- Custom AppColors Definition (Based on user's initial structure) ---
// This class holds the base colors and allows static mutation as per the user's logic
class AppColors {
  static Color whiteColor = const Color(0xFFF6FAFD); 
  static Color blackColor = const Color(0xFF0A1931);
  static Color darkBlueColor = const Color(0xFF1A3D63);
  static Color babyBlueColor = const Color(0xFFB3CFE5);
  static Color lightBlueColor = const Color(0xFF4A7FA7);

  static void setDarkMode(bool isDark) {
    if (isDark == true) {
      // Swapping colors for dark mode (as per user's original intent)
      darkBlueColor = const Color(0xFFF6FAFD); // white-like
      whiteColor = const Color(0xFF1A3D63); // dark blue-like
    } else {
      // Light mode defaults
      darkBlueColor = const Color(0xFF1A3D63);
      whiteColor = const Color(0xFFF6FAFD);
    }
  }
}

// --- Theme Data Definitions ---
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.darkBlueColor,
  scaffoldBackgroundColor: const Color(0xFFE5E5E5), // Light gray background
  colorScheme: ColorScheme.light(
    primary: AppColors.darkBlueColor,
    onPrimary: AppColors.whiteColor,
    secondary: AppColors.lightBlueColor,
    background: AppColors.whiteColor,
    onBackground: AppColors.blackColor,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.darkBlueColor,
    foregroundColor: AppColors.whiteColor,
  ),
  // Define text theme colors for light mode
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Color(0xFF333333)),
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: AppColors.lightBlueColor,
  scaffoldBackgroundColor: AppColors.blackColor,
  colorScheme: ColorScheme.dark(
    primary: AppColors.lightBlueColor,
    onPrimary: AppColors.blackColor,
    secondary: AppColors.babyBlueColor,
    background: AppColors.blackColor,
    onBackground: AppColors.whiteColor,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.blackColor,
    foregroundColor: AppColors.whiteColor,
  ),
  // Define text theme colors for dark mode
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: Color(0xFFEEEEEE)),
  ),
);

// --- ThemeScope: Inherited Widget for Theme State Management ---
// Used to pass the theme state and toggle function down the widget tree.
class ThemeScope extends InheritedWidget {
  final bool isDarkMode;
  final ValueChanged<bool> toggleTheme;

  const ThemeScope({
    super.key,
    required this.isDarkMode,
    required this.toggleTheme,
    required super.child,
  });

  static ThemeScope of(BuildContext context) {
    final ThemeScope? result = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(result != null, 'No ThemeScope found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ThemeScope oldWidget) {
    return oldWidget.isDarkMode != isDarkMode;
  }
}

// --- Persistence Functions (Using 'themeMood' key) ---
Future<void> saveDarkModePreference(bool isDark) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('themeMood', isDark);
}

Future<bool> loadDarkModePreference() async {
  final prefs = await SharedPreferences.getInstance();
  print(prefs.getBool('themeMood'));
  return prefs.getBool('themeMood') ?? false;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // We no longer need the outer MaterialApp, as BootApp will provide the themed MaterialApp
  bool isDark = await loadDarkModePreference();
  AppColors.setDarkMode(isDark); // Set static colors for initial dialogs/widgets
  runApp(
    BootApp(isDarkMode: isDark),
  );
}

/// BootApp checks network first, shows retry dialog if offline,
/// then initializes Supabase and starts the real app.
// ignore: must_be_immutable
class BootApp extends StatefulWidget {
  bool isDarkMode;
  BootApp({super.key, required this.isDarkMode});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  bool _ready = false;
  bool _initializing = false;
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    _startSequence();
    // loadDarkModePreference is already called in main(), no need to call again here
  }

  // MODIFIED: Updates state, calls static color setter, and saves preference
  void toggleDarkMode(bool value) async {
    setState(() {
      isDarkMode = value;
      AppColors.setDarkMode(value); // Keep static colors updated for dialogs/legacy widgets
    });
    await saveDarkModePreference(value);
  }

  Future<void> _startSequence() async {
    if (_initializing) return;
    _initializing = true;

    while (mounted) {
      final ok = await _hasNetwork();
      if (ok) {
        try {
          await Supabase.initialize(
            url: supabaseUrl,
            anonKey: supabaseKey,
            authOptions: const FlutterAuthClientOptions(
              authFlowType: AuthFlowType.pkce,
            ),
            realtimeClientOptions: const RealtimeClientOptions(
              logLevel: RealtimeLogLevel.info,
            ),
            storageOptions: const StorageClientOptions(retryAttempts: 10),
          );
          supabase = Supabase.instance.client;
          // any additional startup can be done here
          setState(() => _ready = true);
          return;
        } catch (e) {
          // initialization failed -> show retry dialog
          await _showOfflineDialog(
            title: 'Initialization failed',
            message: 'Failed to initialize services. Retry?',
          );
        }
      } else {
        await _showOfflineDialog(
          title: 'No internet connection',
          message: 'Please check your network connection and tap Retry.',
        );
      }
    }
  }

  Future<bool> _hasNetwork() async {
    try {
      // quick DNS lookup to verify connectivity
      final result = await InternetAddress.lookup(
        'example.com',
      ).timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _showOfflineDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    // show blocking dialog with Retry button
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          icon: Icon(
            AmazingIconOutlined.wifi,
            size: 60,
            color: AppColors.darkBlueColor,
          ),
          backgroundColor: AppColors.whiteColor,
          title: Text(title),
          titleTextStyle: TextStyle(
            color: AppColors.darkBlueColor,
            fontFamily: 'main',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          content: Text(message, style: TextStyle(color: AppColors.blackColor)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // pop dialog and retry loop continues
              },
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.lightBlueColor,
                  fontFamily: 'main',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // While not ready, show a minimal loading UI so the dialog can be shown.
    if (!_ready) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    // Wrap the main app in ThemeScope to make theme state accessible
    return ThemeScope(
      isDarkMode: isDarkMode,
      toggleTheme: toggleDarkMode,
      // Once ready, run your real app
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme, // Set default light theme
        darkTheme: darkTheme, // Set dark theme
        themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light, // Control theme mode
        home: const Splash(),
        routes: {
          '/login': (context) => const LoginPage(),
          // Passing ThemeScope down to HomePage so it can pass to SettingsPage
          '/home': (context) => const HomePage(), 
          '/user_data': (context) => const UserDataPage(),
          '/aboutus': (context) => const AboutUsPage(),
          '/calculate': (context) => CalculatePage(),
          '/progress': (context) => ProgressPage(),
          '/settings': (context) => const settingsPage(), // Added /settings route
        },
      ),
    );
  }
}

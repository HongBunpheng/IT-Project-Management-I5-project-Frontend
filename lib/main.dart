import 'package:flutter/material.dart';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter_locales/flutter_locales.dart';
import 'configs/app_colors.dart';
import 'configs/app_theme_extension.dart';
import 'auth/screen/login_screen.dart';
import 'main_shell.dart';
import 'services/token_storage.dart';
import 'utils/snackbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Locales.init(['en', 'km']);
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MyApp(savedThemeMode: savedThemeMode));
}

class MyApp extends StatefulWidget {
  final AdaptiveThemeMode? savedThemeMode;

  const MyApp({super.key, this.savedThemeMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.white,
        extensions: [AppThemeExtension.light],
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
      ),
      dark: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        extensions: [AppThemeExtension.dark],
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          surfaceTintColor: Colors.transparent,
        ),
      ),
      initial: widget.savedThemeMode ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => LocaleBuilder(
        builder: (locale) {
          final appLocale = locale ?? const Locale('en', '');
          return MaterialApp(
            title: 'CG Intern Project',
            theme: theme,
            darkTheme: darkTheme,
            navigatorKey: CustomSnackBar.navigatorKey,
            locale: appLocale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('km', ''),
            ],
            localizationsDelegates: Locales.delegates,
            home: const AuthCheckScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

/// Screen that checks if user is already logged in
class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final TokenStorage _tokenStorage = TokenStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final token = await _tokenStorage.readToken();
    
    if (!mounted) return;

    // If token exists, user is logged in - go to dashboard
    // Otherwise, show login screen
    if (token != null && token.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: const Center(
        child: CircularProgressIndicator(
          color: AppColors.white,
        ),
      ),
    );
  }
}

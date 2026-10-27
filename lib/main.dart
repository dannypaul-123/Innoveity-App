import 'package:flutter/material.dart';

import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/admin_portal_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    PushNotificationService().initialize();
  } catch (_) {}
  runApp(const InnoveityApp());
}

class InnoveityApp extends StatefulWidget {
  const InnoveityApp({super.key});

  @override
  State<InnoveityApp> createState() => _InnoveityAppState();
}

class _InnoveityAppState extends State<InnoveityApp> {
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _appState.addListener(_onStateChange);
  }

  void _onStateChange() {
    setState(() {});
  }

  @override
  void dispose() {
    _appState.removeListener(_onStateChange);
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Innoveity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final width = mediaQuery.size.width;
        final scale = width < 380
            ? 0.85
            : width < 480
            ? 0.93
            : 1.0;
        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: TextScaler.linear(scale)),
          child: IconTheme.merge(
            data: IconThemeData(size: width < 380 ? 18 : 22),
            child: child!,
          ),
        );
      },
      home: _appState.isLoggedIn
          ? (_appState.isAdmin && !_appState.previewAsEmployee
              ? AdminPortalScreen(state: _appState)
              : MainNavigationScreen(state: _appState))
          : LoginScreen(
              onLoginSuccess: _appState.login,
              onLoginWithCredentials: (email, password) =>
                  _appState.loginWithCredentials(email, password),
              onToggleTheme: _appState.toggleTheme,
              isDarkMode: _appState.isDarkMode,
            ),
    );
  }
}

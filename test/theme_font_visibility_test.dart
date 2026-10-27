import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innoveity_app/theme/app_theme.dart';
import 'package:innoveity_app/theme/app_colors.dart';
import 'package:innoveity_app/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppTheme Font Visibility Tests', () {
    test('Dark theme textTheme colors are high-contrast light colors', () {
      final dark = AppTheme.darkTheme;
      final t = dark.textTheme;

      expect(t.headlineLarge?.color, equals(AppColors.textLight));
      expect(t.headlineMedium?.color, equals(AppColors.textLight));
      expect(t.headlineSmall?.color, equals(AppColors.textLight));
      expect(t.titleLarge?.color, equals(AppColors.textLight));
      expect(t.titleMedium?.color, equals(AppColors.textLight));
      expect(t.titleSmall?.color, equals(AppColors.textLight));
      expect(t.bodyLarge?.color, equals(AppColors.textLight));
      expect(t.bodyMedium?.color, equals(AppColors.textLight));
      expect(t.bodySmall?.color, equals(AppColors.textLightMuted));
      expect(t.labelLarge?.color, equals(AppColors.textLight));
      expect(t.labelMedium?.color, equals(AppColors.textLight));
      expect(t.labelSmall?.color, equals(AppColors.textLightMuted));
      expect(dark.colorScheme.onSurface, equals(AppColors.textLight));
      expect(dark.colorScheme.onSurfaceVariant, equals(AppColors.textLightMuted));
    });

    test('Light theme textTheme colors are high-contrast dark colors', () {
      final light = AppTheme.lightTheme;
      final t = light.textTheme;

      expect(t.headlineLarge?.color, equals(AppColors.textDark));
      expect(t.headlineMedium?.color, equals(AppColors.textDark));
      expect(t.headlineSmall?.color, equals(AppColors.textDark));
      expect(t.titleLarge?.color, equals(AppColors.textDark));
      expect(t.titleMedium?.color, equals(AppColors.textDark));
      expect(t.titleSmall?.color, equals(AppColors.textDark));
      expect(t.bodyLarge?.color, equals(AppColors.textDark));
      expect(t.bodyMedium?.color, equals(AppColors.textDark));
      expect(t.bodySmall?.color, equals(AppColors.textMuted));
      expect(t.labelLarge?.color, equals(AppColors.textDark));
      expect(t.labelMedium?.color, equals(AppColors.textDark));
      expect(t.labelSmall?.color, equals(AppColors.textMuted));
      expect(light.colorScheme.onSurface, equals(AppColors.textDark));
      expect(light.colorScheme.onSurfaceVariant, equals(AppColors.textMuted));
    });
  });

  group('LoginScreen Font Visibility Widget Tests', () {
    testWidgets('LoginScreen renders fonts clearly in dark theme', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Scaffold(
            body: LoginScreen(
              onLoginSuccess: () {},
              onToggleTheme: () {},
              isDarkMode: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Work Email tab label is white in dark mode
      final emailTab = tester.widget<Text>(find.text('Work Email'));
      expect(emailTab.style?.color, equals(Colors.white));

      // Check Company Email Address label is textLight in dark mode
      final emailLabel = tester.widget<Text>(find.text('Company Email Address'));
      expect(emailLabel.style?.color, equals(AppColors.textLight));

      // Check Password label is textLight in dark mode
      final passLabel = tester.widget<Text>(find.text('Password'));
      expect(passLabel.style?.color, equals(AppColors.textLight));

      // Check Okta SSO button text is textLight in dark mode
      final oktaLabel = tester.widget<Text>(find.text('Okta SSO'));
      expect(oktaLabel.style?.color, equals(AppColors.textLight));

      // Switch to PIN tab
      await tester.tap(find.text('PIN / Passcode'));
      await tester.pumpAndSettle();

      // Check PIN / Passcode tab label is white when active in dark mode
      final pinTab = tester.widget<Text>(find.text('PIN / Passcode'));
      expect(pinTab.style?.color, equals(Colors.white));

      // Check keypad digits (e.g. '1', '5', '9', '0') have textLight color in dark mode
      final digit1 = tester.widget<Text>(find.text('1'));
      expect(digit1.style?.color, equals(AppColors.textLight));
      final digit5 = tester.widget<Text>(find.text('5'));
      expect(digit5.style?.color, equals(AppColors.textLight));
      final digit0 = tester.widget<Text>(find.text('0'));
      expect(digit0.style?.color, equals(AppColors.textLight));
    });

    testWidgets('LoginScreen renders fonts clearly in light theme', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: Scaffold(
            body: LoginScreen(
              onLoginSuccess: () {},
              onToggleTheme: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Work Email tab label is primaryPine in light mode
      final emailTab = tester.widget<Text>(find.text('Work Email'));
      expect(emailTab.style?.color, equals(AppColors.primaryPine));

      // Check Company Email Address label is textDark in light mode
      final emailLabel = tester.widget<Text>(find.text('Company Email Address'));
      expect(emailLabel.style?.color, equals(AppColors.textDark));

      // Check Password label is textDark in light mode
      final passLabel = tester.widget<Text>(find.text('Password'));
      expect(passLabel.style?.color, equals(AppColors.textDark));

      // Switch to PIN tab
      await tester.tap(find.text('PIN / Passcode'));
      await tester.pumpAndSettle();

      // Check keypad digits have textDark color in light mode
      final digit1 = tester.widget<Text>(find.text('1'));
      expect(digit1.style?.color, equals(AppColors.textDark));
    });
  });
}

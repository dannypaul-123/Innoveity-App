import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innoveity_app/core/storage/token_storage.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:innoveity_app/screens/login_screen.dart';
import 'package:innoveity_app/theme/app_theme.dart';
import 'package:innoveity_app/services/biometric_auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.resetMemoryCacheForTesting();
    BiometricAuthService.mockAuthResult = true;
  });

  tearDown(() {
    TokenStorage.resetMemoryCacheForTesting();
    BiometricAuthService.mockAuthResult = null;
  });

  group('Google Sign-In Company & Employee Email Policy Tests', () {
    test('Google Sign-In syncs when company email and employee email match the same', () {
      final antoResult = AppState.validateGoogleSignIn('antorajan501@gmail.com');
      expect(antoResult.canSync, isTrue);
      expect(antoResult.errorTitle, isNull);
      expect(antoResult.profile, isNotNull);
      expect(antoResult.profile!.email, 'antorajan501@gmail.com');
      expect(antoResult.profile!.isCompanyAndEmployeeEmailSame, isTrue);
      expect(antoResult.profile!.hasCustomCompanyEmail, isFalse);

      final paulResult = AppState.validateGoogleSignIn('paulrenine9487@gmail.com');
      expect(paulResult.canSync, isTrue);
      expect(paulResult.errorTitle, isNull);
    });

    test('Google Sign-In is blocked when custom company mail is assigned to user (intern Daniel Paul)', () {
      // Trying with custom company email
      final customMailResult = AppState.validateGoogleSignIn('danielpaul@enterprise-crm.com');
      expect(customMailResult.canSync, isFalse);
      expect(customMailResult.errorTitle, 'Custom Company Mail Assigned');
      expect(customMailResult.assignedCompanyEmail, 'danielpaul@enterprise-crm.com');
      expect(
        customMailResult.errorMessage,
        contains('Corporate security policy requires logging in using your username and password'),
      );

      // Trying with personal intern email when custom company mail is assigned
      final internMailResult = AppState.validateGoogleSignIn('dp0345217@gmail.com');
      expect(internMailResult.canSync, isFalse);
      expect(internMailResult.errorTitle, 'Custom Company Mail Assigned');
      expect(internMailResult.assignedCompanyEmail, 'danielpaul@enterprise-crm.com');
      expect(
        internMailResult.errorMessage,
        contains('Corporate security policy requires logging in using your username and password'),
      );
    });

    test('Google Sign-In is blocked for admin and staff with custom enterprise company mail', () {
      final adminResult = AppState.validateGoogleSignIn('admin@enterprise-crm.com');
      expect(adminResult.canSync, isFalse);
      expect(adminResult.errorTitle, 'Custom Company Mail Assigned');
      expect(adminResult.assignedCompanyEmail, 'admin@enterprise-crm.com');

      final harishResult = AppState.validateGoogleSignIn('harish@enterprise-crm.com');
      expect(harishResult.canSync, isFalse);
      expect(harishResult.errorTitle, 'Custom Company Mail Assigned');
    });

    test('Google Sign-In is denied for unregistered accounts not in CRM backend', () {
      final unknownResult = AppState.validateGoogleSignIn('stranger@unknown-domain.com');
      expect(unknownResult.canSync, isFalse);
      expect(unknownResult.errorTitle, 'Google Sign-In Denied');
      expect(unknownResult.errorMessage, contains('not registered in the CRM backend'));
    });
  });

  group('LoginScreen Google Sign-In & Custom Company Mail Widget Flow Tests', () {
    testWidgets('Tapping Sign in with Google with matching company email syncs and logs in', (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool loginSuccessCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: LoginScreen(
              onLoginSuccess: () {
                loginSuccessCalled = true;
              },
              onLoginWithCredentials: (email, pass) async {
                return email == 'antorajan501@gmail.com';
              },
              onToggleTheme: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter employee email where company email and employee email match
      await tester.enterText(find.byType(TextField).first, 'antorajan501@gmail.com');
      await tester.pumpAndSettle();

      final googleSignInBtn = find.text('Sign in with Google');
      await tester.ensureVisible(googleSignInBtn);
      await tester.tap(googleSignInBtn);
      await tester.pumpAndSettle();

      // Dialog to setup fingerprint may appear if new, tap Not Now to complete login
      if (find.text('Setup Fingerprint Login').evaluate().isNotEmpty) {
        await tester.tap(find.text('Not Now'));
        await tester.pumpAndSettle();
      }

      expect(loginSuccessCalled, isTrue);
    });

    testWidgets('Custom company email assigned blocks Google Sign-In and redirects to Username/Password', (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: LoginScreen(
              onLoginSuccess: () {},
              onLoginWithCredentials: (email, pass) async => true,
              onToggleTheme: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter intern email that has custom company mail assigned
      await tester.enterText(find.byType(TextField).first, 'dp0345217@gmail.com');
      await tester.pumpAndSettle();

      final googleSignInBtn = find.text('Sign in with Google');
      await tester.ensureVisible(googleSignInBtn);
      await tester.tap(googleSignInBtn);
      await tester.pumpAndSettle();

      // Dialog explaining custom company mail must appear
      expect(find.text('Custom Company Mail Assigned'), findsOneWidget);
      expect(
        find.textContaining('A custom company email (danielpaul@enterprise-crm.com) is assigned to your account'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Corporate security policy requires logging in using your username and password'),
        findsOneWidget,
      );

      final loginBtn = find.text('Login with Username & Password');
      expect(loginBtn, findsOneWidget);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      // Email field should now be filled with the custom company email for password login
      final emailField = tester.widget<TextField>(find.byType(TextField).first);
      expect(emailField.controller?.text, 'danielpaul@enterprise-crm.com');
    });

    testWidgets('Unregistered Google account displays Google Sign-In Denied modal', (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
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

      await tester.enterText(find.byType(TextField).first, 'stranger.user@gmail.com');
      await tester.pumpAndSettle();

      final googleSignInBtn = find.text('Sign in with Google');
      await tester.ensureVisible(googleSignInBtn);
      await tester.tap(googleSignInBtn);
      await tester.pumpAndSettle();

      expect(find.text('Google Sign-In Denied'), findsOneWidget);
      expect(
        find.textContaining('Account "stranger.user@gmail.com" is not registered in the CRM backend'),
        findsOneWidget,
      );

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Google Sign-In Denied'), findsNothing);
    });
  });
}

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

  group('CRM Backend Fingerprint Access & Verification Tests', () {
    test('AppState.isEmployeeInCrmBackend returns true for registered CRM employees', () {
      expect(AppState.isEmployeeInCrmBackend('antorajan501@gmail.com'), isTrue);
      expect(AppState.isEmployeeInCrmBackend('admin@enterprise-crm.com'), isTrue);
      expect(AppState.isEmployeeInCrmBackend('paulrenine9487@gmail.com'), isTrue);
      expect(AppState.isEmployeeInCrmBackend('dp0345217@gmail.com'), isTrue);
      expect(AppState.isEmployeeInCrmBackend('IN-9002'), isTrue);
      expect(AppState.isEmployeeInCrmBackend('AD-0001'), isTrue);
    });

    test('AppState.isEmployeeInCrmBackend returns false for unknown accounts not added to CRM backend', () {
      expect(AppState.isEmployeeInCrmBackend('random.hacker@unknown.com'), isFalse);
      expect(AppState.isEmployeeInCrmBackend('outsider@gmail.com'), isFalse);
      expect(AppState.isEmployeeInCrmBackend('fake-employee-id'), isFalse);
    });

    test('TokenStorage fingerprint enrollment persists enabled status and active email', () async {
      final storage = TokenStorage();

      // Initially no fingerprint is enrolled
      expect(await storage.getFingerprintEnrolledEmail(), isNull);
      expect(await storage.isFingerprintEnabledFor('antorajan501@gmail.com'), isFalse);

      // Enroll employee
      await storage.setFingerprintEnabledFor(
        email: 'antorajan501@gmail.com',
        enabled: true,
        password: '123456',
      );

      expect(await storage.getFingerprintEnrolledEmail(), equals('antorajan501@gmail.com'));
      expect(await storage.isFingerprintEnabledFor('antorajan501@gmail.com'), isTrue);

      // Disable employee
      await storage.setFingerprintEnabledFor(
        email: 'antorajan501@gmail.com',
        enabled: false,
      );

      expect(await storage.isFingerprintEnabledFor('antorajan501@gmail.com'), isFalse);
      expect(await storage.getFingerprintEnrolledEmail(), isNull);
    });
  });

  group('LoginScreen Fingerprint Gating & Setup Flow Tests', () {
    testWidgets('Newer users without setup are informed credentials validation is required', (tester) async {
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

      final quickUnlockBtn = find.text('Fingerprint Quick Login');
      expect(quickUnlockBtn, findsOneWidget);
      await tester.ensureVisible(quickUnlockBtn);

      // Subtitle indicates credentials must be validated first
      expect(find.text('Login with credentials first to set up'), findsOneWidget);

      // Tap Quick Unlock button
      await tester.tap(quickUnlockBtn);
      await tester.pumpAndSettle();

      // Expect informative dialog indicating credentials validation is required first
      expect(find.text('Fingerprint Not Configured'), findsOneWidget);
      expect(
        find.textContaining('Newer users must first log in and validate their credentials with the CRM backend'),
        findsOneWidget,
      );

      // Dismiss dialog
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('Fingerprint Not Configured'), findsNothing);
    });

    testWidgets('Non-CRM account with enrolled fingerprint is blocked with Access Denied', (tester) async {
      tester.view.physicalSize = const Size(600, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final storage = TokenStorage();
      await storage.setFingerprintEnabledFor(
        email: 'unregistered.intruder@company.com',
        enabled: true,
        password: 'password123',
      );

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

      final quickUnlockBtn = find.text('Fingerprint Quick Login');
      expect(quickUnlockBtn, findsOneWidget);
      await tester.ensureVisible(quickUnlockBtn);

      // Tap quick unlock
      await tester.tap(quickUnlockBtn);
      await tester.pumpAndSettle();

      // Access Denied dialog must appear
      expect(find.text('Access Denied'), findsOneWidget);
      expect(
        find.textContaining('Only employees whose accounts are added to the CRM backend can access fingerprint authentication'),
        findsOneWidget,
      );

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Access Denied'), findsNothing);
    });

    testWidgets('Newer users are prompted to setup fingerprint after validating credentials', (tester) async {
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
                return email == 'antorajan501@gmail.com' && pass == '123456';
              },
              onToggleTheme: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter valid credentials
      await tester.enterText(find.byType(TextField).first, 'antorajan501@gmail.com');
      await tester.enterText(find.byType(TextField).at(1), '123456');
      await tester.pumpAndSettle();

      final signInBtn = find.text('Sign In to Workspace');
      await tester.ensureVisible(signInBtn);
      await tester.tap(signInBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Fingerprint setup prompt dialog should appear
      expect(find.text('Setup Fingerprint Login'), findsOneWidget);
      expect(find.textContaining('Credentials Validated Successfully'), findsOneWidget);
      expect(find.text('Setup Fingerprint'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);

      // Tap Setup Fingerprint
      await tester.tap(find.text('Setup Fingerprint'));
      await tester.pumpAndSettle();

      // Verify login success was called
      expect(loginSuccessCalled, isTrue);

      // Verify fingerprint is now enabled for this user in TokenStorage
      final storage = TokenStorage();
      expect(await storage.isFingerprintEnabledFor('antorajan501@gmail.com'), isTrue);
      expect(await storage.getFingerprintEnrolledEmail(), equals('antorajan501@gmail.com'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:innoveity_app/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TokenStorage Saved Accounts & Password Persistence Tests', () {
    test('Default enterprise accounts are available on initial launch', () async {
      final storage = TokenStorage();
      final accounts = await storage.readSavedAccounts();

      expect(accounts.isNotEmpty, isTrue);
      expect(accounts.any((a) => a.email == 'antorajan501@gmail.com'), isTrue);
      expect(accounts.any((a) => a.email == 'admin@enterprise-crm.com'), isTrue);
      expect(accounts.firstWhere((a) => a.email == 'antorajan501@gmail.com').password, '123456');
      expect(accounts.firstWhere((a) => a.email == 'admin@enterprise-crm.com').password, 'Admin123!');
    });

    test('Save new account and password persists across new TokenStorage instances (app restart)', () async {
      // First session: User saves custom account
      final storageSession1 = TokenStorage();
      await storageSession1.saveAccountCredential(
        email: 'employee.john@company.com',
        password: 'MySecretPassword99!',
        label: 'Lead Developer',
      );

      // Verify immediate read in session 1
      final accounts1 = await storageSession1.readSavedAccounts();
      expect(accounts1.first.email, 'employee.john@company.com');
      expect(accounts1.first.password, 'MySecretPassword99!');

      final lastLogin1 = await storageSession1.readSavedUserLogin();
      expect(lastLogin1, 'employee.john@company.com');

      // Simulate App Close & Reopen (Session 2 with fresh instance)
      final storageSession2 = TokenStorage();
      final accounts2 = await storageSession2.readSavedAccounts();
      expect(accounts2.any((a) => a.email == 'employee.john@company.com'), isTrue);
      final matched = accounts2.firstWhere((a) => a.email == 'employee.john@company.com');
      expect(matched.password, 'MySecretPassword99!');

      final lastLogin2 = await storageSession2.readSavedUserLogin();
      expect(lastLogin2, 'employee.john@company.com');
    });

    test('Updating password for an existing account updates it without duplicates', () async {
      final storage = TokenStorage();
      await storage.saveAccountCredential(
        email: 'testuser@innoveity.com',
        password: 'OldPassword123',
      );

      // Update password
      await storage.saveAccountCredential(
        email: 'testuser@innoveity.com',
        password: 'NewSuperPassword456!',
      );

      final accounts = await storage.readSavedAccounts();
      final matching = accounts.where((a) => a.email == 'testuser@innoveity.com').toList();
      expect(matching.length, 1);
      expect(matching.first.password, 'NewSuperPassword456!');
    });

    test('Deleting a saved account removes it from persistent storage', () async {
      final storage = TokenStorage();
      await storage.saveAccountCredential(
        email: 'to_be_deleted@company.com',
        password: 'Pass12345',
      );

      var accounts = await storage.readSavedAccounts();
      expect(accounts.any((a) => a.email == 'to_be_deleted@company.com'), isTrue);

      await storage.deleteSavedAccount('to_be_deleted@company.com');

      accounts = await storage.readSavedAccounts();
      expect(accounts.any((a) => a.email == 'to_be_deleted@company.com'), isFalse);
    });

    test('Calling clear() on logout clears ONLY session tokens and NEVER deletes saved accounts', () async {
      final storage = TokenStorage();
      await storage.save(accessToken: 'sample_jwt_token', refreshToken: 'sample_refresh_token');
      await storage.saveAccountCredential(
        email: 'stay_saved@company.com',
        password: 'SecurePass789!',
      );

      expect(await storage.readAccessToken(), 'sample_jwt_token');

      // Logout called: clear()
      await storage.clear();

      // Session tokens must be cleared
      expect(await storage.readAccessToken(), isNull);
      expect(await storage.readRefreshToken(), isNull);

      // BUT saved account credentials and passwords MUST remain intact!
      final accountsAfterLogout = await storage.readSavedAccounts();
      expect(accountsAfterLogout.any((a) => a.email == 'stay_saved@company.com'), isTrue);
      expect(
        accountsAfterLogout.firstWhere((a) => a.email == 'stay_saved@company.com').password,
        'SecurePass789!',
      );
    });
  });
}

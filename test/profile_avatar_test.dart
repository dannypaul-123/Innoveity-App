import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:innoveity_app/widgets/app_avatar.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Profile Picture (PFP) Upload & Avatar Persistence Tests', () {
    late AppState appState;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
    });

    test('getAvatarImageProvider handles null, URLs, and file paths gracefully', () {
      // Null or empty returns null (renders initials)
      expect(getAvatarImageProvider(null), isNull);
      expect(getAvatarImageProvider('   '), isNull);

      // Network URL returns NetworkImage
      final netProvider = getAvatarImageProvider('https://example.com/photo.png');
      expect(netProvider, isA<NetworkImage>());

      // Asset path returns AssetImage
      final assetProvider = getAvatarImageProvider('assets/icons/avatar.png');
      expect(assetProvider, isA<AssetImage>());
    });

    test('updateAvatar updates profile, syncs to directory, and persists across restarts', () async {
      await appState.loginWithCredentials('dp0345217@gmail.com', '123456');
      expect(appState.isLoggedIn, isTrue);

      const testPhotoPath = '/data/user/0/com.innoveity.app/cache/my_new_pfp.jpg';

      // 1. Update avatar
      await appState.updateAvatar(testPhotoPath);
      expect(appState.userProfile.avatar, testPhotoPath);

      // 2. Directory synchronized immediately
      final dirUser = AppState.userDirectory['dp0345217@gmail.com'];
      expect(dirUser?.avatar, testPhotoPath);

      // 3. Persisted in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final savedInPrefs = prefs.getString('user_avatar_dp0345217@gmail.com');
      expect(savedInPrefs, testPhotoPath);

      // 4. Logout and log back in (simulates app restart)
      appState.logout();
      await appState.loginWithCredentials('dp0345217@gmail.com', '123456');
      expect(appState.userProfile.avatar, testPhotoPath);

      // 5. Remove avatar restores initials badge
      await appState.updateAvatar(null);
      expect(appState.userProfile.avatar, isNull);
      expect(prefs.getString('user_avatar_dp0345217@gmail.com'), isNull);
    });

    testWidgets('buildUserAvatar renders initials when avatar is null and renders cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildUserAvatar(
              avatar: null,
              name: 'Daniel Paul',
              size: 60,
            ),
          ),
        ),
      );
      await tester.pump();

      // Initials 'D' displayed
      expect(find.text('D'), findsOneWidget);
    });
  });
}

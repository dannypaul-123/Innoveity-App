import 'package:flutter_test/flutter_test.dart';
import 'package:innoveity_app/models/app_models.dart';
import 'package:innoveity_app/services/geofence_service.dart';
import 'package:innoveity_app/providers/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GeofenceLocationProfile Model Tests', () {
    test('Serializes and deserializes correctly to/from JSON', () {
      final profile = GeofenceLocationProfile(
        id: 'prof-101',
        name: 'Tambaram Branch Campus',
        latitude: 12.920500,
        longitude: 80.121700,
        radiusMeters: 250.0,
        address: 'Tambaram Sanatorium, Chennai',
        isActive: true,
      );

      final jsonMap = profile.toJson();
      expect(jsonMap['id'], 'prof-101');
      expect(jsonMap['name'], 'Tambaram Branch Campus');
      expect(jsonMap['latitude'], 12.920500);
      expect(jsonMap['longitude'], 80.121700);
      expect(jsonMap['radiusMeters'], 250.0);
      expect(jsonMap['isActive'], true);

      final reconstructed = GeofenceLocationProfile.fromJson(jsonMap);
      expect(reconstructed.id, profile.id);
      expect(reconstructed.name, profile.name);
      expect(reconstructed.latitude, profile.latitude);
      expect(reconstructed.longitude, profile.longitude);
      expect(reconstructed.radiusMeters, profile.radiusMeters);
      expect(reconstructed.address, profile.address);
      expect(reconstructed.isActive, profile.isActive);
    });

    test('copyWith properly updates specific properties', () {
      final profile = GeofenceLocationProfile(
        id: 'prof-hq',
        name: 'HQ',
        latitude: 12.920466,
        longitude: 80.121639,
        radiusMeters: 200.0,
      );

      final updated = profile.copyWith(
        name: 'Updated HQ Campus',
        radiusMeters: 300.0,
      );

      expect(updated.id, 'prof-hq');
      expect(updated.name, 'Updated HQ Campus');
      expect(updated.radiusMeters, 300.0);
      expect(updated.latitude, 12.920466);
      expect(updated.longitude, 80.121639);
    });
  });

  group('GeofenceService Verification & Tolerance Tests', () {
    final hqProfile = GeofenceLocationProfile(
      id: 'LOC-HQ',
      name: 'INNOVEITY Workspace Headquarters',
      latitude: 12.920466,
      longitude: 80.121639,
      radiusMeters: 200.0,
    );

    final branchProfile = GeofenceLocationProfile(
      id: 'LOC-OMR',
      name: 'OMR Tech Park',
      latitude: 12.971598,
      longitude: 80.250000,
      radiusMeters: 150.0,
    );

    setUp(() {
      GeofenceService.officeLat = 12.920466;
      GeofenceService.officeLng = 80.121639;
      GeofenceService.officeName = 'INNOVEITY Workspace Headquarters';
      GeofenceService.geofenceRadiusMeters = 200.0;
      GeofenceService.activeProfileId = 'LOC-HQ';
      GeofenceService.locationProfiles = [hqProfile, branchProfile];
    });

    test('Accurately verifies location inside company HQ geofence', () {
      // Coordinates within 10 meters of office center
      final result = GeofenceService.verifyLocation(
        userLat: 12.920480,
        userLng: 80.121645,
        accuracyMeters: 5.0,
      );

      expect(result.isWithinRadius, isTrue);
      expect(result.hasLocation, isTrue);
      expect(result.distanceMeters, lessThan(20.0));
      expect(result.officeName, contains('Headquarters'));
    });

    test('Compensates for indoor GPS attenuation using accuracy radius', () {
      // Raw distance ~215 meters (slightly outside 200m circle due to indoor GPS drift)
      // With 25 meters accuracy tolerance, effective distance is 190m <= 200m
      final result = GeofenceService.verifyLocation(
        userLat: 12.922400,
        userLng: 80.121639,
        accuracyMeters: 25.0,
      );

      // Should be successfully verified within indoor tolerance
      expect(result.isWithinRadius, isTrue);
    });

    test('Rejects clock-in when genuinely outside premise beyond tolerance', () {
      // Point ~1.5 km away in Tambaram
      final result = GeofenceService.verifyLocation(
        userLat: 12.934000,
        userLng: 80.121639,
        accuracyMeters: 10.0,
      );

      expect(result.isWithinRadius, isFalse);
      expect(result.distanceMeters, greaterThan(1000.0));
    });

    test('Verifies employee located at any configured active profile location', () {
      // Employee is at the OMR branch location
      final result = GeofenceService.verifyLocation(
        userLat: 12.971600,
        userLng: 80.250010,
        accuracyMeters: 5.0,
      );

      expect(result.isWithinRadius, isTrue);
      expect(result.officeName, 'OMR Tech Park');
    });
  });

  group('AppState Geofence Profile Management Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default HQ profile and allows adding new profile', () async {
      final state = AppState();
      expect(state.locationProfiles.isNotEmpty, isTrue);
      expect(state.locationProfiles.any((p) => p.name.contains('Headquarters')), isTrue);

      final newProfile = GeofenceLocationProfile(
        id: 'velachery-hub',
        name: 'Velachery Co-working Hub',
        latitude: 12.981000,
        longitude: 80.218000,
        radiusMeters: 150.0,
      );

      state.addLocationProfile(newProfile);

      expect(state.locationProfiles.any((p) => p.id == 'velachery-hub'), isTrue);
      expect(state.activeLocationProfile.id, 'velachery-hub');
      expect(state.hqLatitude, 12.981000);
      expect(state.hqLongitude, 80.218000);
    });

    test('Updates existing location profile and syncs current geofence coordinates', () async {
      final state = AppState();
      final active = state.activeLocationProfile;

      final updatedProfile = active.copyWith(
        name: 'Custom HQ Campus',
        latitude: 12.921000,
        longitude: 80.122000,
        radiusMeters: 350.0,
      );

      state.updateLocationProfile(updatedProfile);

      final updated = state.locationProfiles.firstWhere((p) => p.id == active.id);
      expect(updated.name, 'Custom HQ Campus');
      expect(updated.radiusMeters, 350.0);
      expect(state.hqLatitude, 12.921000);
      expect(state.hqLongitude, 80.122000);
      expect(state.geofenceRadiusMeters, 350.0);
    });

    test('Switches active profile and maintains active fallback when deleting', () async {
      final state = AppState();
      final p2 = GeofenceLocationProfile(
        id: 'secondary-loc',
        name: 'Branch 2',
        latitude: 12.910000,
        longitude: 80.130000,
        radiusMeters: 200.0,
      );

      state.addLocationProfile(p2);
      expect(state.activeLocationProfileId, 'secondary-loc');

      // Delete the active profile, should fallback safely to remaining profile
      state.deleteLocationProfile('secondary-loc');
      expect(state.locationProfiles.any((p) => p.id == 'secondary-loc'), isFalse);
      expect(state.activeLocationProfileId, isNotEmpty);
      expect(state.activeLocationProfileId, isNot('secondary-loc'));
    });
  });
}

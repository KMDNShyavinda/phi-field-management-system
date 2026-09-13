import 'package:flutter_test/flutter_test.dart';
import 'package:phi_mobile/core/app_update_service.dart';

void main() {
  group('AppUpdateService.compareVersions', () {
    test('higher patch version is newer', () {
      expect(
        AppUpdateService.compareVersions(
          latestVersion: '0.1.1',
          currentVersion: '0.1.0',
        ),
        isTrue,
      );
    });

    test('higher minor version is newer', () {
      expect(
        AppUpdateService.compareVersions(
          latestVersion: '0.2.0',
          currentVersion: '0.1.9',
        ),
        isTrue,
      );
    });

    test('higher major version is newer', () {
      expect(
        AppUpdateService.compareVersions(
          latestVersion: '1.0.0',
          currentVersion: '0.9.9',
        ),
        isTrue,
      );
    });

    test('same version is not newer', () {
      expect(
        AppUpdateService.compareVersions(
          latestVersion: '0.1.0',
          currentVersion: '0.1.0',
        ),
        isFalse,
      );
    });

    test('lower version is not newer', () {
      expect(
        AppUpdateService.compareVersions(
          latestVersion: '0.0.9',
          currentVersion: '0.1.0',
        ),
        isFalse,
      );
    });

    test('higher build number with same semver is newer', () {
      expect(
        AppUpdateService.compareVersions(
          latestVersion: '0.1.0+2',
          currentVersion: '0.1.0',
          currentBuild: 1,
        ),
        isTrue,
      );
    });
  });
}

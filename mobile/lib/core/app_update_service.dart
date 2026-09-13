import 'dart:async';
import 'package:dio/dio.dart';
import 'package:ota_update/ota_update.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppUpdateInfo {
  final String currentVersion;
  final String latestVersion;
  final String releaseTitle;
  final String releaseNotes;
  final String downloadUrl;
  final String apkFileName;
  final int? apkSizeBytes;
  final String? publishedAt;

  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.downloadUrl,
    required this.apkFileName,
    this.apkSizeBytes,
    this.publishedAt,
  });
}

class AppUpdateService {
  static const String repoOwner = 'KMDNShyavinda';
  static const String repoName = 'phi-field-management-system';
  static const String latestReleaseUrl =
      'https://api.github.com/repos/$repoOwner/$repoName/releases/latest';

  final Dio _dio;

  AppUpdateService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'Accept': 'application/vnd.github.v3+json',
                  'User-Agent': 'PHI-Mobile-App',
                },
              ),
            );

  /// Checks if a newer version of the app is available on GitHub Releases.
  /// Returns [AppUpdateInfo] if an update is found, or null if up to date or offline.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "0.1.0"
      final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;

      final response = await _dio.get(latestReleaseUrl);
      if (response.statusCode != 200 || response.data == null) {
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      final rawTag = data['tag_name'] as String? ?? '';
      final latestVersion = rawTag.replaceAll(RegExp(r'^[vV]'), '').trim();

      if (latestVersion.isEmpty) return null;

      final isNewer = compareVersions(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        currentBuild: currentBuild,
      );

      if (!isNewer) return null;

      // Find APK asset
      final assets = (data['assets'] as List<dynamic>?) ?? [];
      Map<String, dynamic>? apkAsset;
      for (final asset in assets) {
        final name = (asset['name'] as String? ?? '').toLowerCase();
        if (name.endsWith('.apk')) {
          apkAsset = asset as Map<String, dynamic>;
          break;
        }
      }

      if (apkAsset == null) {
        // Release exists, but no APK has been attached
        return null;
      }

      final downloadUrl = apkAsset['browser_download_url'] as String;
      final fileName = apkAsset['name'] as String? ?? 'phi_update.apk';
      final size = apkAsset['size'] as int?;
      final releaseTitle = data['name'] as String? ?? 'v$latestVersion';
      final releaseNotes = data['body'] as String? ?? 'New version available with improvements and bug fixes.';
      final publishedAt = data['published_at'] as String?;

      return AppUpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        releaseTitle: releaseTitle,
        releaseNotes: releaseNotes,
        downloadUrl: downloadUrl,
        apkFileName: fileName,
        apkSizeBytes: size,
        publishedAt: publishedAt,
      );
    } catch (e) {
      // 404 (no releases), no internet, or timeout
      return null;
    }
  }

  /// Compares [latestVersion] with [currentVersion].
  /// Supports versions like "1.2.3" or "1.2.3+4".
  static bool compareVersions({
    required String latestVersion,
    required String currentVersion,
    int currentBuild = 0,
  }) {
    final latestClean = latestVersion.split('+').first;
    final currentClean = currentVersion.split('+').first;

    final latestParts = latestClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final currentParts = currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    // Pad with zeroes so both have at least 3 parts (major, minor, patch)
    while (latestParts.length < 3) {
      latestParts.add(0);
    }
    while (currentParts.length < 3) {
      currentParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }

    // If semver is identical, check build number if present in latestVersion (e.g. 1.0.0+2)
    if (latestVersion.contains('+')) {
      final latestBuildStr = latestVersion.split('+').last;
      final latestBuild = int.tryParse(latestBuildStr) ?? 0;
      return latestBuild > currentBuild;
    }

    return false;
  }

  /// Downloads the APK and starts the Android installation intent
  Stream<OtaEvent> startOtaUpdate(String downloadUrl, {String filename = 'phi_update.apk'}) {
    return OtaUpdate().execute(downloadUrl, destinationFilename: filename);
  }
}

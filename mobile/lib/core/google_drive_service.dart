import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope, // App Data folder (hidden from user)
      drive.DriveApi.driveFileScope,    // Specific files created by the app
    ],
  );

  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint("Error signing in: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<void> backupData(BuildContext context) async {
    final account = _googleSignIn.currentUser ?? await signIn();
    if (account == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google Sign-In failed or cancelled.')),
        );
      }
      return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating backup file...')),
      );
    }

    try {
      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // 1. Create a zip of the database and photos
      final zipFile = await _createBackupZip();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading to Google Drive...')),
        );
      }

      // 2. Upload to Drive
      final driveFile = drive.File()
        ..name = 'PHI_Backup_${DateTime.now().toIso8601String().replaceAll(':', '-')}.zip'
        ..parents = ['appDataFolder']; // Saves in hidden app data folder

      final media = drive.Media(zipFile.openRead(), zipFile.lengthSync());
      
      await driveApi.files.create(driveFile, uploadMedia: media);

      // Clean up local zip
      if (zipFile.existsSync()) {
        zipFile.deleteSync();
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup successful! 🎉'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Backup error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<File> _createBackupZip() async {
    final encoder = ZipFileEncoder();
    final tempDir = await getTemporaryDirectory();
    final zipPath = p.join(tempDir.path, 'phi_backup.zip');
    
    encoder.create(zipPath);

    // Add SQLite DB
    final dbPath = p.join(await getDatabasesPath(), 'phi.db');
    final dbFile = File(dbPath);
    if (dbFile.existsSync()) {
      encoder.addFile(dbFile);
    }

    // Add Photos
    final docDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(docDir.path, 'photos'));
    if (photosDir.existsSync()) {
      encoder.addDirectory(photosDir);
    }

    encoder.close();
    return File(zipPath);
  }
}

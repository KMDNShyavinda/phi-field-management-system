import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    // Since we use adb reverse for physical Android devices, 127.0.0.1 works for both emulator (if ADB reversed) and physical.
    // If not using adb reverse, Android emulators need 10.0.2.2.
    // We default to 127.0.0.1 to avoid timeouts on physical devices running normal 'flutter run'.
    return 'http://127.0.0.1:8000';
  }
}

class DemoAccounts {
  static const email = 'phi@moh.lk';
  static const password = 'phi12345';
}

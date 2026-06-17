// lib/Models/SettingsModel.dart (FINALIZED)

class SettingsModel {
  // --- Security Settings ---
  bool isBiometricsEnabled;
  bool isPasscodeSet;

  // --- Appearance Settings ---
  String currentTheme; // e.g., 'Light', 'Dark', 'System'

  // --- User Info (For Header) ---
  String userName;
  int accountsSecuredCount;

  // Constructor with default values matching the UI image and standard security practice
  SettingsModel({
    this.isBiometricsEnabled = false,
    this.isPasscodeSet = false,
    this.currentTheme =
        'Light', // Defaulting to 'Light' to match typical Flutter default
    this.userName = 'John Doe', // Matches the UI image
    this.accountsSecuredCount = 5, // Matches the UI image
  });

  // A factory constructor for loading from local storage (e.g., SharedPreferences)
  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      // Security Settings
      isBiometricsEnabled: json['isBiometricsEnabled'] as bool? ?? false,
      isPasscodeSet: json['isPasscodeSet'] as bool? ?? false,

      // Appearance Settings
      currentTheme: json['currentTheme'] as String? ?? 'Light',

      // User Info (Using defaults if data is missing)
      userName: json['userName'] as String? ?? 'John Doe',
      accountsSecuredCount: json['accountsSecuredCount'] as int? ?? 0,
    );
  }

  // Method for saving to local storage
  Map<String, dynamic> toJson() {
    return {
      // Security Settings
      'isBiometricsEnabled': isBiometricsEnabled,
      'isPasscodeSet': isPasscodeSet,

      // Appearance Settings
      'currentTheme': currentTheme,

      // User Info
      'userName': userName,
      'accountsSecuredCount': accountsSecuredCount,
    };
  }
}

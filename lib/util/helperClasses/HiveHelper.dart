import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';

// The key used to store the single instance of our helper class.
const String _hiveHelperKey = 'hive_helper';

class HiveHelper extends GetxService {
  late Box _appBox; // A generic box to store key-value pairs.

  // Private constructor to enforce the singleton pattern.
  HiveHelper._privateConstructor();

  // The singleton instance.
  static final HiveHelper _instance = HiveHelper._privateConstructor();

  // Static method to get the single instance.
  static HiveHelper get instance => _instance;

  // This method ensures the singleton is properly initialized by GetX.
  static Future<HiveHelper> init() async {
    // If GetX has already registered the instance, return it.
    if (Get.isRegistered<HiveHelper>()) {
      return Get.find<HiveHelper>();
    }

    // Initialize Hive database.
    await Hive.initFlutter();

    // Open the default box for the application.
    // It's good practice to have a primary box for general settings.
    _instance._appBox = await Hive.openBox('appBox');

    // Register the instance with GetX.
    Get.put<HiveHelper>(_instance, tag: _hiveHelperKey);
    return _instance;
  }

  /// Getters and Setters for various data types

  // Saves a boolean value to the app box.
  Future<void> saveBool(String key, bool value) async {
    await _appBox.put(key, value);
  }

  // Retrieves a boolean value from the app box.
  // Returns a default value if the key is not found.
  bool getBool(String key, {bool defaultValue = false}) {
    return _appBox.get(key, defaultValue: defaultValue);
  }

  // Saves a string value to the app box.
  Future<void> saveString(String key, String value) async {
    await _appBox.put(key, value);
  }

  // Retrieves a string value from the app box.
  String? getString(String key) {
    return _appBox.get(key);
  }

  // Saves an integer value to the app box.
  Future<void> saveInt(String key, int value) async {
    await _appBox.put(key, value);
  }

  // Retrieves an integer value from the app box.
  int? getInt(String key) {
    return _appBox.get(key);
  }

  // Saves a dynamic value (for any data type) to the app box.
  Future<void> save(String key, dynamic value) async {
    await _appBox.put(key, value);
  }

  // Retrieves a dynamic value from the app box.
  dynamic get(String key) {
    return _appBox.get(key);
  }

  /// Other utility methods

  // Deletes a key-value pair from the app box.
  Future<void> delete(String key) async {
    await _appBox.delete(key);
  }

  // Clears all data from the app box.
  Future<int> clear() async {
    return await _appBox.clear();
  }

  // Checks if a key exists in the app box.
  bool containsKey(String key) {
    return _appBox.containsKey(key);
  }

  // A method to open a new box for specific data, like user profiles.
  static Future<Box> openNewBox(String boxName) async {
    return await Hive.openBox(boxName);
  }
}

/// Repository interface for Application Settings.
abstract class ISettingsRepository {
  /// Retrieves the setting value for a given key. Returns null if not found.
  Future<String?> getSetting(String key);

  /// Saves or updates a setting key-value pair.
  Future<void> setSetting(String key, String value);

  /// Retrieves all settings as a key-value Map.
  Future<Map<String, String>> getAllSettings();

  /// Sets multiple settings at once inside a single database transaction.
  Future<void> setAllSettings(Map<String, String> settings);
}

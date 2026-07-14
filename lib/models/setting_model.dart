import 'package:gomaa_management/database/database_constants.dart';

/// Represents a single application setting as a key-value pair.
///
/// All keys are defined in [SettingsKeys] as constants.
/// The value is always stored as [String] in SQLite; typed getters
/// should live in [SettingsCubit].
class SettingModel {
  final String key;
  final String value;

  const SettingModel({required this.key, required this.value});

  // ── Serialization ─────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      SettingsColumns.key: key,
      SettingsColumns.value: value,
    };
  }

  factory SettingModel.fromMap(Map<String, dynamic> map) {
    return SettingModel(
      key: map[SettingsColumns.key] as String,
      value: map[SettingsColumns.value] as String,
    );
  }

  SettingModel copyWith({String? key, String? value}) {
    return SettingModel(
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  String toString() => 'SettingModel(key: $key, value: $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingModel &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}

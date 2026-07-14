import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:gomaa_management/repositories/interfaces/i_settings_repository.dart';

// States
abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}
class SettingsLoading extends SettingsState {}
class SettingsLoaded extends SettingsState {
  final Map<String, String> settings;
  const SettingsLoaded(this.settings);
  @override
  List<Object?> get props => [settings];
}
class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
  @override
  List<Object?> get props => [message];
}

// Cubit
class SettingsCubit extends Cubit<SettingsState> {
  final ISettingsRepository _settingsRepository;

  SettingsCubit(this._settingsRepository) : super(SettingsInitial());

  Future<void> loadSettings() async {
    emit(SettingsLoading());
    try {
      final settings = await _settingsRepository.getAllSettings();
      emit(SettingsLoaded(settings));
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> updateSetting(String key, String value) async {
    try {
      await _settingsRepository.setSetting(key, value);
      await loadSettings();
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }

  Future<void> updateAllSettings(Map<String, String> newSettings) async {
    try {
      await _settingsRepository.setAllSettings(newSettings);
      await loadSettings();
    } catch (e) {
      emit(SettingsError(e.toString()));
    }
  }
}

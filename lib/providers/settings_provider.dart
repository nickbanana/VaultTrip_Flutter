import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vault_trip/states/settings_state.dart';

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());
  static const String _vaultPathKey = 'vault_path';
  static const String itineraryTemplatePathKey = 'itinerary_template_path';
  static const String itineraryDayTemplatePathKey =
      'itinerary_day_template_path';
  static const String locationListTemplatePathKey =
      'location_list_template_path';
  static const String locationTemplatePathKey = 'location_template_path';

  Future<void> loadSettings() async {
    if (!state.isLoading) return;
    final prefs = SharedPreferencesAsync();
    final savedVaultPath = await prefs.getString(_vaultPathKey);
    final savedItineraryTemplatePath = await prefs.getString(
      itineraryTemplatePathKey,
    );
    final savedItineraryDayTemplatePath = await prefs.getString(
      itineraryDayTemplatePathKey,
    );
    final savedLocationListTemplatePath = await prefs.getString(
      locationListTemplatePathKey,
    );
    final savedLocationTemplatePath = await prefs.getString(
      locationTemplatePathKey,
    );
    state = SettingsState(
      vaultPath: savedVaultPath,
      itineraryTemplatePath: savedItineraryTemplatePath,
      itineraryDayTemplatePath: savedItineraryDayTemplatePath,
      locationListTemplatePath: savedLocationListTemplatePath,
      locationTemplatePath: savedLocationTemplatePath,
      isLoading: false,
    );
  }

  Future<void> selectAndSaveVaultPath() async {
    final path = await pickFolder();
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_vaultPathKey, path);
    state = SettingsState(vaultPath: path);
  }

  Future<void> SaveTemplatePath(String key, String relatedPath) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(key, relatedPath);
    _updateStateWithNewPath(key, relatedPath);
  }

  void _updateStateWithNewPath(String key, String relatedPath) {
    switch (key) {
      case itineraryTemplatePathKey:
        state = state.copyWith(itineraryTemplatePath: relatedPath);
      case itineraryDayTemplatePathKey:
        state = state.copyWith(itineraryDayTemplatePath: relatedPath);
      case locationListTemplatePathKey:
        state = state.copyWith(locationListTemplatePath: relatedPath);
      case locationTemplatePathKey:
        state = state.copyWith(locationTemplatePath: relatedPath);
    }
  }

  Future<String> pickFolder() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: '選擇資料夾',
      lockParentWindow: true,
    );

    if (selectedDirectory != null) {
      return selectedDirectory;
    }

    return '';
  }

  Future<void> _selectAndSaveFilePath(
    String key,
    Function(String path) onSave,
  ) async {
    FilePickerResult? selectedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      initialDirectory: state.vaultPath,
      allowedExtensions: ['md'],
      dialogTitle: '選擇檔案',
      lockParentWindow: true,
    );
    if (selectedFile != null && selectedFile.files.single.path != null) {
      final path = selectedFile.files.single.path!;
      final prefs = SharedPreferencesAsync();
      await prefs.setString(key, path);
      onSave(path);
    }
  }

  Future<void> clearVaultPath() async {
    state = SettingsState(isLoading: true);
    final prefs = SharedPreferencesAsync();
    await prefs.remove(_vaultPathKey);
    state = SettingsState(vaultPath: null, isLoading: false);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    return SettingsNotifier()..loadSettings();
  },
);

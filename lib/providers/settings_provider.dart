import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vault_trip/states/settings_state.dart';

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  static const String _vaultPathKey = 'vault_path';
  static const String itineraryTemplatePathKey = 'itinerary_template_path';
  static const String itineraryDayTemplatePathKey = 'itinerary_day_template_path';
  static const String locationListTemplatePathKey = 'location_list_template_path';
  static const String locationItemTemplatePathKey = 'location_item_template_path';

  @override
  Future<SettingsState> build() async {
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
      locationItemTemplatePathKey,
    );

    return SettingsState(
      vaultPath: savedVaultPath,
      itineraryTemplatePath: savedItineraryTemplatePath,
      itineraryDayTemplatePath: savedItineraryDayTemplatePath,
      locationListTemplatePath: savedLocationListTemplatePath,
      locationItemTemplatePath: savedLocationTemplatePath,
      isLoading: false,
    );
  }
  
  Future<void> selectAndSaveVaultPath() async {
    final path = await pickFolder();
    final prefs = SharedPreferencesAsync();
    await prefs.setString(_vaultPathKey, path);
    state = AsyncValue.data(state.value!.copyWith(vaultPath: path));
  }

  Future<void> saveTemplatePath(String key, String relatedPath) async {
    final prefs = SharedPreferencesAsync();
    await prefs.setString(key, relatedPath);
    _updateStateWithNewPath(key, relatedPath);
  }

  void _updateStateWithNewPath(String key, String relatedPath) {
    switch (key) {
      case itineraryTemplatePathKey:
        state = AsyncValue.data(state.value!.copyWith(itineraryTemplatePath: relatedPath));
      case itineraryDayTemplatePathKey:
        state = AsyncValue.data(state.value!.copyWith(itineraryDayTemplatePath: relatedPath));
      case locationListTemplatePathKey:
        state = AsyncValue.data(state.value!.copyWith(locationListTemplatePath: relatedPath));
      case locationItemTemplatePathKey:
        state = AsyncValue.data(state.value!.copyWith(locationItemTemplatePath: relatedPath));
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

  Future<void> clearVaultPath() async {
    state = AsyncValue.data(state.value!.copyWith(isLoading: true));
    final prefs = SharedPreferencesAsync();
    await prefs.remove(_vaultPathKey);
    await prefs.remove(itineraryTemplatePathKey);
    await prefs.remove(itineraryDayTemplatePathKey);
    await prefs.remove(locationListTemplatePathKey);
    await prefs.remove(locationItemTemplatePathKey);
    state = AsyncValue.data(SettingsState(isLoading: false));
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

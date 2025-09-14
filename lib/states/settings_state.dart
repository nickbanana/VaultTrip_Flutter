class SettingsState {
  final bool isLoading;
  final String? vaultPath;
  final String? itineraryTemplatePath;
  final String? itineraryDayTemplatePath;
  final String? locationListTemplatePath;
  final String? locationTemplatePath;
  const SettingsState({
    this.isLoading = true,
    this.vaultPath,
    this.itineraryTemplatePath,
    this.itineraryDayTemplatePath,
    this.locationListTemplatePath,
    this.locationTemplatePath,
  });

  SettingsState copyWith({
    bool? isLoading,
    String? vaultPath,
    String? itineraryTemplatePath,
    String? itineraryDayTemplatePath,
    String? locationListTemplatePath,
    String? locationTemplatePath,
  }) {
    return SettingsState(
      isLoading: isLoading ?? this.isLoading,
      vaultPath: vaultPath ?? this.vaultPath,
      itineraryTemplatePath: itineraryTemplatePath ?? this.itineraryTemplatePath,
      itineraryDayTemplatePath: itineraryDayTemplatePath ?? this.itineraryDayTemplatePath,
      locationListTemplatePath: locationListTemplatePath ?? this.locationListTemplatePath,
      locationTemplatePath: locationTemplatePath ?? this.locationTemplatePath,
    );
  }
}
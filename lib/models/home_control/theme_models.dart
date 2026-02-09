
enum ThemeType { basic, animated, dynamicTime, dynamicWeather }
enum TimeOfDay { sunrise, morning, afternoon, sunset, night }
enum WeatherCondition { sunny, cloudy, rainy, thunderstorm, snowy, foggy, partlyCloudy }

class ThemeSettings {
  final ThemeType themeType;
  final bool isDarkMode;
  final TimeOfDay currentTimeOfDay;
  final WeatherCondition currentWeather;
  
  // These were missing and causing your errors:
  final bool autoSwitchByTime;
  final bool autoSwitchByWeather;
  final String? weatherApiKey;

  const ThemeSettings({
    this.themeType = ThemeType.basic,
    this.isDarkMode = false,
    this.currentTimeOfDay = TimeOfDay.morning,
    this.currentWeather = WeatherCondition.sunny,
    this.autoSwitchByTime = false,
    this.autoSwitchByWeather = false,
    this.weatherApiKey,
  });

  ThemeSettings copyWith({
    ThemeType? themeType,
    bool? isDarkMode,
    TimeOfDay? currentTimeOfDay,
    WeatherCondition? currentWeather,
    bool? autoSwitchByTime,
    bool? autoSwitchByWeather,
    String? weatherApiKey,
  }) {
    return ThemeSettings(
      themeType: themeType ?? this.themeType,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      currentTimeOfDay: currentTimeOfDay ?? this.currentTimeOfDay,
      currentWeather: currentWeather ?? this.currentWeather,
      autoSwitchByTime: autoSwitchByTime ?? this.autoSwitchByTime,
      autoSwitchByWeather: autoSwitchByWeather ?? this.autoSwitchByWeather,
      weatherApiKey: weatherApiKey ?? this.weatherApiKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeType': themeType.index,
      'isDarkMode': isDarkMode,
      'currentTimeOfDay': currentTimeOfDay.index,
      'currentWeather': currentWeather.index,
      'autoSwitchByTime': autoSwitchByTime,
      'autoSwitchByWeather': autoSwitchByWeather,
      'weatherApiKey': weatherApiKey,
    };
  }

  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeType: ThemeType.values[json['themeType'] ?? 0],
      isDarkMode: json['isDarkMode'] ?? false,
      currentTimeOfDay: TimeOfDay.values[json['currentTimeOfDay'] ?? 1],
      currentWeather: WeatherCondition.values[json['currentWeather'] ?? 0],
      autoSwitchByTime: json['autoSwitchByTime'] ?? false,
      autoSwitchByWeather: json['autoSwitchByWeather'] ?? false,
      weatherApiKey: json['weatherApiKey'],
    );
  }
}
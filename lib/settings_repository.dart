import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static var _prefsKeys = _SettingsPrefsKeys();

  Future<Settings> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return Settings(
      temperatureUnit: prefs.getBool(_prefsKeys.temperature) ?? true,
      gender: prefs.getBool(_prefsKeys.gender) ?? true,
      birthDate: prefs.getString(_prefsKeys.birthDate) ?? DateTime.now().toIso8601String(),
      city: prefs.getString(_prefsKeys.city) ?? 'Не выбран',
    );
  }

  Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setBool(_prefsKeys.temperature, settings.temperatureUnit),
      prefs.setBool(_prefsKeys.gender, settings.gender),
      prefs.setString(_prefsKeys.birthDate, settings.birthDate),
      prefs.setString(_prefsKeys.city, settings.city),
    ]);
  }
}

class _SettingsPrefsKeys {
  final temperature = 'temperature';
  final gender = 'gender';
  final birthDate = 'birthDate';
  final city = 'city';
}

class Settings {
  final bool temperatureUnit;
  final bool gender;
  final String birthDate;
  final String city;

  Settings({
    required this.temperatureUnit,
    required this.gender,
    required this.birthDate,
    required this.city,
  });

  String get formattedBirthDate => birthDate.split('T')[0];

  Settings copyWith({
    bool? temperatureUnit,
    bool? gender,
    String? birthDate,
    String? city,
  }) {
    return Settings(
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      city: city ?? this.city,
    );
  }
}
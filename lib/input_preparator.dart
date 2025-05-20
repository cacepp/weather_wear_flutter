const List<String> weatherTypes = [
  'Thunderstorm', 'Drizzle', 'Rain', 'Snow', 'Mist',
  'Smoke', 'Haze', 'Dust', 'Fog', 'Sand',
  'Ash', 'Squall', 'Tornado', 'Clear', 'Clouds'
];

/// Определение сезона по Unix-времени
String getSeason(int timestamp) {
  final month = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).month;
  if (month >= 3 && month <= 5) return 'spring';
  if (month >= 6 && month <= 8) return 'summer';
  if (month >= 9 && month <= 11) return 'autumn';
  return 'winter';
}

/// Получение возраста на основе даты рождения
int calculateAge(DateTime birthDate, DateTime now) {
  int age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age.clamp(6, 90);
}

/// Преобразует входные данные в нормализованный формат для TFLite модели
List<double> prepareInput({
  required Map<String, dynamic> apiResponse,
  required DateTime birthDate,
  required String gender, // 'male' or 'female'
}) {
  final now = DateTime.now();
  final int age = calculateAge(birthDate, now);

  final double temp = (apiResponse['main']['temp'] as num).toDouble();
  final double humidity = (apiResponse['main']['humidity'] as num).toDouble();
  final double windSpeed = (apiResponse['wind']['speed'] as num).toDouble();
  final String weather = apiResponse['weather'][0]['main'] ?? 'Clear';
  final int dt = (apiResponse['dt'] as num).toInt();
  final String season = getSeason(dt);

  // Нормализованные числовые признаки
  final normalized = <double>[
    age / 90.0,                          // age_norm
    (temp + 20) / 60.0,                  // temp_norm
    humidity / 100.0,                   // humidity_norm
    windSpeed / 50.0                    // wind_speed_norm
  ];

  // Пол: one-hot
  final genderEncoded = gender == 'male' ? [1.0, 0.0] : [0.0, 1.0];

  // Сезон: one-hot
  final seasonEncoded = <double>[
    season == 'winter' ? 1.0 : 0.0,
    season == 'spring' ? 1.0 : 0.0,
    season == 'summer' ? 1.0 : 0.0,
    season == 'autumn' ? 1.0 : 0.0,
  ];

  // Погода: one-hot
  final weatherEncoded = weatherTypes.map<double>((type) => type == weather ? 1.0 : 0.0).toList();

  return <double>[
    ...normalized,
    ...genderEncoded,
    ...seasonEncoded,
    ...weatherEncoded,
  ];
}
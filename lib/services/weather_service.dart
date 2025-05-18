import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Модель для текущей погоды
class WeatherData {
  final double temperature;
  final String description;
  final double windSpeed;
  final int windDegree;
  final int humidity;
  final String precipitation;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.windSpeed,
    required this.windDegree,
    required this.humidity,
    required this.precipitation,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    var main = json['main'];
    var wind = json['wind'];
    var weatherDescriptionData = json['weather'][0];

    double temperature = (main['temp'] is num) ? main['temp'].toDouble() : 0.0;
    double windSpeed = (wind['speed'] is num) ? wind['speed'].toDouble() : 0.0;
    int windDegree = (wind['deg'] is num) ? wind['deg'].toInt() : 0;
    int humidity = (main['humidity'] is num) ? main['humidity'].toInt() : 0;
    String description = weatherDescriptionData['description'] ?? 'No description';

    // Обработка осадков
    String precipitation = 'No precipitation';
    if (json.containsKey('snow') && json['snow'] is Map<String, dynamic>) {
      var snow = json['snow'];
      double snowAmount = (snow['3h'] is num) ? snow['3h'].toDouble() : 0.0;
      precipitation = 'Snow: $snowAmount mm';
    } else if (json.containsKey('rain') && json['rain'] is Map<String, dynamic>) {
      var rain = json['rain'];
      double rainAmount = (rain['3h'] is num) ? rain['3h'].toDouble() : 0.0;
      precipitation = 'Rain: $rainAmount mm';
    }

    return WeatherData(
      temperature: temperature,
      description: description,
      windSpeed: windSpeed,
      windDegree: windDegree,
      humidity: humidity,
      precipitation: precipitation,
    );
  }
}

// Модель для прогноза погоды
class WeatherForecast {
  final String date;
  final double temperature;
  final String description;
  final double windSpeed;
  final int windDegree;
  final int humidity;

  WeatherForecast({
    required this.date,
    required this.temperature,
    required this.description,
    required this.windSpeed,
    required this.windDegree,
    required this.humidity,
  });

  factory WeatherForecast.fromJson(Map<String, dynamic> json) {
    var main = json['main'];
    var wind = json['wind'];
    var weatherDescriptionData = json['weather'][0];

    return WeatherForecast(
      date: json['dt_txt'],
      temperature: (main['temp'] is num) ? main['temp'].toDouble() : 0.0,
      description: weatherDescriptionData['description'] ?? 'No description',
      windSpeed: (wind['speed'] is num) ? wind['speed'].toDouble() : 0.0,
      windDegree: (wind['deg'] is num) ? wind['deg'].toInt() : 0,
      humidity: (main['humidity'] is num) ? main['humidity'].toInt() : 0,
    );
  }
}

class WeatherService {
  final String currentWeatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  // Получение текущей погоды
  Future<WeatherData> fetchCurrentWeather(String city) async {
    try {
      // Достаем API_KEY из .env
      final apiKey = dotenv.env['API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API_KEY is not defined in .env');
      }

      final response = await http.get(Uri.parse(
          '$currentWeatherUrl?q=$city&units=metric&appid=$apiKey&lang=ru'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Возвращаем объект WeatherData, созданный из JSON
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load current weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching current weather: $e');
    }
  }

  // Получение прогноза на 5 дней
  Future<List<WeatherForecast>> fetchWeatherForecast(String city) async {
    try {
      // Достаем API_KEY из .env
      final apiKey = dotenv.env['API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API_KEY is not defined in .env');
      }

      final response = await http.get(Uri.parse(
          '$forecastUrl?q=$city&units=metric&appid=$apiKey&lang=ru'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Проверяем, что список прогнозов существует
        if (data['list'] == null) {
          throw Exception('Invalid API response: No "list" field found');
        }

        List<WeatherForecast> weatherList = [];

        for (var item in data['list']) {
          // Добавляем только прогнозы на 12:00:00
          if (item['dt_txt'] != null && item['dt_txt'].endsWith('12:00:00')) {
            weatherList.add(WeatherForecast.fromJson(item));
          }
        }

        return weatherList; // Возвращаем список объектов WeatherForecast
      } else {
        throw Exception('Failed to load weather forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather forecast: $e');
    }
  }
}

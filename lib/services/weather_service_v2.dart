import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherServiceV2 {
  final String currentWeatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';
  final apiKey = dotenv.env['API_KEY'];

  Future<dynamic> fetchCurrentWeather(String city) async {
    try {
      if (apiKey == null || apiKey!.isEmpty) {
        throw Exception('API_KEY is not defined in .env');
      }

      final response = await http.get(Uri.parse(
          '$currentWeatherUrl?q=$city&units=metric&appid=$apiKey&lang=ru'));

      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      throw Exception('Error fetching current weather: $e');
    }
  }

  Future<dynamic> fetchWeatherForecast(String city) async {
    try {
      if (apiKey == null || apiKey!.isEmpty) {
        throw Exception('API_KEY is not defined in .env');
      }

      final response = await http.get(Uri.parse(
          '$forecastUrl?q=$city&units=metric&appid=$apiKey&lang=ru'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['list'] == null) {
          throw Exception('Invalid API response: No "list" field found');
        }

        List<dynamic> weatherList = [];

        for (var item in data['list']) {
          // Только прогнозы на 12:00:00
          if (item['dt_txt'] != null && item['dt_txt'].endsWith('12:00:00')) {
            weatherList.add(item);
          }
        }

        return weatherList;
      }
    } catch (e) {
      throw Exception('Error fetching weather forecast: $e');
    }
  }
}
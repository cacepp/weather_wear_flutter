import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Импортируем flutter_dotenv

class WeatherService {
  final String currentWeatherUrl = 'https://api.openweathermap.org/data/2.5/weather';
  final String forecastUrl = 'https://api.openweathermap.org/data/2.5/forecast';

  // Получение текущей погоды
  Future<String> fetchCurrentWeather(String city) async {
    try {
      // Достаем API_KEY из .env
      final apiKey = dotenv.env['API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API_KEY is not defined in .env');
      }

      final response = await http.get(Uri.parse(
          '$currentWeatherUrl?q=$city&units=metric&appid=$apiKey'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = data['main']['temp'];
        final description = data['weather'][0]['description'];
        return 'Current Temp: $temp°C\nDescription: $description';
      } else {
        throw Exception('Failed to load current weather: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching current weather: $e');
    }
  }

  // Получение прогноза на 5 дней
  Future<List<String>> fetchWeatherForecast(String city) async {
    try {
      // Достаем API_KEY из .env
      final apiKey = dotenv.env['API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API_KEY is not defined in .env');
      }

      final response = await http.get(Uri.parse(
          '$forecastUrl?q=$city&units=metric&appid=$apiKey'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['list'] == null) {
          throw Exception('Invalid API response: No "list" field found');
        }

        List<String> weatherList = [];

        for (var item in data['list']) {
          // Фильтруем только прогнозы на 12:00:00
          if (item['dt_txt'] != null && item['dt_txt'].endsWith('12:00:00')) {
            var dateTime = item['dt_txt'];
            var temp = item['main']['temp'];
            var description = item['weather'][0]['description'];

            weatherList.add(
                'Date: $dateTime\nTemp: $temp°C\nDescription: $description\n');
          }
        }

        return weatherList;
      } else {
        throw Exception(
            'Failed to load weather forecast: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching weather forecast: $e');
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'services/weather_service.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: WeatherScreen(),
    );
  }
}

class WeatherScreen extends StatefulWidget {
  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _controller = TextEditingController();
  String _city = '';
  String _currentWeather = '';
  List<String> _weatherForecast = [];
  final WeatherService _weatherService = WeatherService();

  Future<void> fetchWeatherData() async {
    try {
      // Получаем текущую погоду
      final currentWeather = await _weatherService.fetchCurrentWeather(_city);
      // Получаем прогноз на 5 дней
      final forecast = await _weatherService.fetchWeatherForecast(_city);

      setState(() {
        _currentWeather = currentWeather;
        _weatherForecast = forecast;
      });
    } catch (e) {
      setState(() {
        _currentWeather = 'Error: $e';
        _weatherForecast = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Weather Forecast')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ввод названия города
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter City',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _city = value;
                });
              },
            ),
            SizedBox(height: 16),
            // Кнопка для запроса данных
            ElevatedButton(
              onPressed: () {
                if (_city.isNotEmpty) {
                  fetchWeatherData();
                }
              },
              child: Text('Get Weather'),
            ),
            SizedBox(height: 16),
            // Кнопка для закрытия приложения
            ElevatedButton(
              onPressed: () {
                exit(0); // Завершает процесс приложения
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Цвет кнопки
              ),
              child: Text('Exit App'),
            ),
            SizedBox(height: 16),
            // Отображение текущей погоды
            if (_currentWeather.isNotEmpty) ...[
              Text(
                'Current Weather:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(_currentWeather),
            ],
            SizedBox(height: 16),
            // Отображение прогноза погоды на 5 дней
            if (_weatherForecast.isNotEmpty) ...[
              Text(
                '5-Day Forecast:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              for (var weather in _weatherForecast)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(weather),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

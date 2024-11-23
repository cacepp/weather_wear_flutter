import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Для работы с .env
import 'services/weather_service.dart'; // Импорт вашего WeatherService

void main() async {
  // Загружаем .env перед запуском приложения
  await dotenv.load(fileName: "env/.env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => WeatherAppState(),
      child: MaterialApp(
        title: 'Weather App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color.fromRGBO(171, 221, 240, 1),
          ),
        ),
        home: WeatherHomePage(),
      ),
    );
  }
}

class WeatherAppState extends ChangeNotifier {
  String city = '';
  String currentWeather = '';
  List<String> weatherForecast = [];
  final WeatherService weatherService = WeatherService();

  // Обновляем город
  void updateCity(String newCity) {
    city = newCity;
    notifyListeners();
  }

  // Получаем текущую погоду
  Future<void> fetchCurrentWeather() async {
    try {
      final weather = await weatherService.fetchCurrentWeather(city);
      currentWeather = weather;
      notifyListeners();
    } catch (e) {
      currentWeather = 'Error: $e';
      notifyListeners();
    }
  }

  // Получаем прогноз на 5 дней
  Future<void> fetchWeatherForecast() async {
    try {
      final forecast = await weatherService.fetchWeatherForecast(city);
      weatherForecast = forecast;
      notifyListeners();
    } catch (e) {
      weatherForecast = ['Error: $e'];
      notifyListeners();
    }
  }
}

class WeatherHomePage extends StatefulWidget {
  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<WeatherAppState>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Weather App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Поле ввода города
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter City',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                appState.updateCity(value);
              },
            ),
            SizedBox(height: 16),
            // Кнопка для получения текущей погоды
            ElevatedButton(
              onPressed: () {
                if (appState.city.isNotEmpty) {
                  appState.fetchCurrentWeather();
                  appState.fetchWeatherForecast();
                }
              },
              child: Text('Get Weather'),
            ),
            SizedBox(height: 16),
            // Отображение текущей погоды
            if (appState.currentWeather.isNotEmpty) ...[
              Text(
                'Current Weather:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(appState.currentWeather),
            ],
            SizedBox(height: 16),
            // Отображение прогноза на 5 дней
            if (appState.weatherForecast.isNotEmpty) ...[
              Text(
                '5-Day Forecast:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              for (var forecast in appState.weatherForecast)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(forecast),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

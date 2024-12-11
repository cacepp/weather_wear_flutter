import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:weather_wear_flutter/pages/city_picker_page.dart';
import 'package:weather_wear_flutter/pages/date_picker_page.dart';
import 'package:intl/intl.dart';

import 'services/weather_service.dart';

void main() async {
  await dotenv.load(fileName: "env/.env");
  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(),
      child: MaterialApp(
        title: 'Weather Wear',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Color.fromRGBO(171, 221, 240, 1)),
        ),
        home: HomePage(),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  String city = '';
  WeatherData? weatherData; // This will store the weather data
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

      // Сохраняем полученные данные в weatherData
      weatherData = weather;
      notifyListeners();
    } catch (e) {
      print('Error fetching weather data: $e');
    }
  }

  // Получаем прогноз на 5 дней
  Future<void> fetchWeatherForecast() async {
    try {
      final forecast = await weatherService.fetchWeatherForecast(city);
      var weatherForecast = forecast.cast<String>();
      notifyListeners();
    } catch (e) {
      var weatherForecast = ['Error: $e'];
      notifyListeners();
    }
  }
}

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _selectedIndex = 1;
  var _selectedPageName = 'Погода';

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (_selectedIndex) {
      case 0:
        page = HistoryPage();
        _selectedPageName = 'История';
        break;
      case 1:
        page = WeatherPage();
        _selectedPageName = 'Погода';
        break;
      case 2:
        page = SettingsPage();
        _selectedPageName = 'Настройки';
        break;
      default:
        throw UnimplementedError('no widget for $_selectedIndex');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedPageName,
          style: TextStyle(fontSize: 40.0),
        ),
        foregroundColor: Color.fromRGBO(42, 58, 74, 1),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ),
          SafeArea(
            child: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'История',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.cloud),
                  label: 'Погода',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Настройки',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: (value) {
                setState(() {
                  _selectedIndex = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  TextEditingController cityController = TextEditingController();  // Controller for the city input

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Поле ввода города
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextField(
            controller: cityController,
            decoration: InputDecoration(
              labelText: 'Enter city',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (value) {
              // Обновляем город в состоянии
              appState.updateCity(value);
              // Загружаем погоду для нового города
              appState.fetchCurrentWeather();
            },
          ),
        ),
        SizedBox(height: 20),

        // Заголовок с городом
        Text(
          'Current Weather for ${appState.city}',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 20),

        // Показать прогресс-бар, если данные еще не загружены
        appState.weatherData == null
            ? CircularProgressIndicator()
            : WeatherDetails(weather: appState.weatherData!),  // Отображаем детали погоды

        SizedBox(height: 20),

        // Кнопка для обновления погоды
        ElevatedButton(
          onPressed: () async {
            // Загружаем погоду для текущего города
            await appState.fetchCurrentWeather();
          },
          child: Text('Refresh Weather'),
        ),
      ],
    );
  }
}

class WeatherDetails extends StatelessWidget {
  final WeatherData weather; // Now we directly use WeatherData

  // Конструктор для получения данных погоды
  WeatherDetails({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Температура
        Text(
          'Temperature: ${weather.temperature}°C',
          style: TextStyle(fontSize: 18),
        ),
        // Скорость ветра
        Text(
          'Wind Speed: ${weather.windSpeed} m/s',
          style: TextStyle(fontSize: 18),
        ),
        // Направление ветра
        Text(
          'Wind Direction: ${weather.windDegree}°',
          style: TextStyle(fontSize: 18),
        ),
        // Влажность
        Text(
          'Humidity: ${weather.humidity}%',
          style: TextStyle(fontSize: 18),
        ),
        // Описание погоды
        Text(
          'Description: ${weather.description}',
          style: TextStyle(fontSize: 18),
        ),
        // Осадки
        Text(
          'Precipitation: ${weather.precipitation}',
          style: TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('History Page'),
    );
  }
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Settings Page'),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_wear_flutter/pages/history_page.dart';

import 'package:weather_wear_flutter/pages/recommendation_page.dart';
import 'package:weather_wear_flutter/pages/settings_page.dart';

import 'services/api_service.dart';
import 'services/weather_service.dart';
import 'db.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "env/.env");


  String path = '${await getDatabasesPath()}${Platform.pathSeparator}"recom.db"';

  Database db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        var batch = db.batch();
        createTableHistory(batch);
        await batch.commit();
      },
      onDowngrade: onDatabaseDowngradeDelete
  );

  // Срабатывает при запуске приложения (в проде убрать)
  // await populateDatabase(db);

  runApp(App(db: db));
}

class App extends StatelessWidget {
  final Database db;

  const App({super.key, required this.db});

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
        home: HomePage(db: db),
      ),
    );
  }
}

class AppState extends ChangeNotifier {
  String city = '';
  WeatherData? weatherData;
  List<WeatherForecast> weatherForecast = [];  // 5-day weather forecast
  String recommendation = '';

  final WeatherService weatherService = WeatherService();
  final ApiService apiService = ApiService();

  void updateCity(String newCity) {
    city = newCity;
    notifyListeners();
  }

  Future<void> fetchCurrentWeather() async {
    try {
      final weather = await weatherService.fetchCurrentWeather(city);
      weatherData = weather;
      notifyListeners();
    } catch (e) {
      print('Error fetching current weather: $e');
    }
  }

  Future<void> sendPromptToApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // final bool temperatureUnit = prefs.getBool('temperature') ?? true; // true: Цельсий, false: Фаренгейт
      final bool gender = prefs.getBool('gender') ?? true; // true: male, false: female
      final String birthDate = prefs.getString('birthDate') ?? DateTime.now().toIso8601String();
      final String city = prefs.getString('city') ?? 'Не выбран';

      final int userAge = DateTime.now().year - DateTime.parse(birthDate).year;

      if (city == 'Не выбран') {
        throw Exception('Город не выбран. Выберите город в настройках.');
      }

      final temperature = weatherData?.temperature ?? 0.0;
      final windSpeed = weatherData?.windSpeed ?? 0.0;
      final precipitation = weatherData!.precipitation.contains('Rain') || weatherData!.precipitation.contains('Snow')
          ? double.tryParse(weatherData!.precipitation.split(':')[1].split(' ')[0]) ?? 0.0
          : 0.0;

      final String sex = gender ? 'male' : 'female';

      final response = await apiService.getRecommendations(
        temperature: temperature,
        windSpeed: windSpeed,
        precipitation: precipitation,
        sex: sex,
        age: userAge,
      );

      if (response['success']) {
        final result = utf8.decode(response['recommendation'].codeUnits);
        recommendation = result;
      } else {
        final String error = response['error'];
        print('Ошибка: $error');
      }
    } catch (e) {
      print('Ошибка при отправке запроса: $e');
    } finally {
      notifyListeners();
    }
  }

  // Fetch 5-day weather forecast
  Future<void> fetchWeatherForecast() async {
    try {
      final forecast = await weatherService.fetchWeatherForecast(city);
      weatherForecast = forecast;
      notifyListeners();
    } catch (e) {
      print('Error fetching weather forecast: $e');
    }
  }
}

class HomePage extends StatefulWidget {
  final Database db;

  const HomePage({super.key, required this.db});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var _selectedIndex = 1;
  var _selectedPageName = 'Погода';

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    Widget page;
    switch (_selectedIndex) {
      case 0:
        page = HistoryPage(db: widget.db);
        _selectedPageName = 'История';
      case 1:
        page = WeatherPage(db: widget.db);
        _selectedPageName = 'Погода';
      case 2:
        page = SettingsPage();
        _selectedPageName = 'Настройки';
      case 3:
        if (appState.weatherData != null) {
          page = RecommendationPage(
            weatherData: appState.weatherData!,
            recommendation: appState.recommendation,
            db: widget.db,
          );
          _selectedPageName = 'Рекомендация';
        } else {
          page = Placeholder();
          _selectedPageName = 'Рекомендация (Ошибка)';
        }
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
  final Database db;

  const WeatherPage({super.key, required this.db});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  TextEditingController cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCityFromPreferences();
    _loadTemperatureUnit();
  }

  Future<void> _loadCityFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedCity = prefs.getString('city'); // Получение сохраненного города
    if (savedCity != null && savedCity.isNotEmpty) {
      cityController.text = savedCity; // Установка значения в контроллер

      // Программное нажатие кнопки Refresh Weather
      final appState = Provider.of<AppState>(context, listen: false);
      appState.updateCity(savedCity);
      await appState.fetchCurrentWeather();
      await appState.fetchWeatherForecast();
    }
  }

  var _temperatureUnit = true;

  Future<void> _loadTemperatureUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // true: Цельсий, false: Фаренгейт
      _temperatureUnit = prefs.getBool('temperature') ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Padding(
          //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
          //   child: TextField(
          //     controller: cityController,
          //     decoration: InputDecoration(
          //       labelText: 'Город',
          //       border: OutlineInputBorder(),
          //     ),
          //     onSubmitted: (value) {
          //       appState.updateCity(value);
          //       appState.fetchCurrentWeather();
          //       appState.fetchWeatherForecast();
          //     },
          //   ),
          // ),
          SizedBox(height: 20),

          // City and current weather display
          Text(
            appState.city,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          SizedBox(height: 20),

          appState.weatherData == null
              ? CircularProgressIndicator()
              : WeatherDetails(weather: appState.weatherData!), // Show current weather details

          SizedBox(height: 20),

          // Vertical slider for weather forecast
          appState.weatherForecast.isEmpty
              ? CircularProgressIndicator()
              : CarouselSlider.builder(
            itemCount: appState.weatherForecast.length,
            itemBuilder: (context, index, realIndex) {
              var forecast = appState.weatherForecast[index];
              double displayTemperature = _temperatureUnit
                  ? forecast.temperature
                  : (forecast.temperature * 1.8) + 32;

              String temperatureUnitLabel = _temperatureUnit ? "°C" : "°F";

              return Container(
                padding: EdgeInsets.all(10),
                margin: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Column(
                  children: [
                    Text(forecast.date, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.thermostat, size: 24, color: Colors.orange),
                        Text(
                          'Температура: ${displayTemperature.ceil()}$temperatureUnitLabel',
                          style: TextStyle(fontSize: 20),
                        )
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud, size: 24, color: Colors.blue[200]),
                        SizedBox(width: 8),
                        Text(forecast.description, style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.air, size: 24, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Text('Ветер: ${forecast.windSpeed.ceil()} m/s', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Text(getWindDirection(forecast.windDegree.toDouble()), style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop, size: 24, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Влажность: ${forecast.humidity}%', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              );
            },
            options: CarouselOptions(
              height: 256,
              enlargeCenterPage: true,
              scrollDirection: Axis.horizontal,
              enableInfiniteScroll: false,
            ),
          ),

          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await appState.sendPromptToApi();

              if (appState.weatherData != null) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecommendationPage(
                      weatherData: appState.weatherData!,
                      recommendation: appState.recommendation,
                      db: widget.db
                    ),
                  ),
                );
              }
            },
            child: Text('Получить рекомендацию'),
          ),
        ],
      ),
    );
  }

  String getWindDirection(double windDegree) {
    List<String> directions = [
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'
    ];

    int index = ((windDegree % 360) / 22.5).round() % 16;
    return directions[index];
  }
}

class WeatherDetails extends StatefulWidget {
  final WeatherData weather;

  WeatherDetails({required this.weather});

  @override
  State<WeatherDetails> createState() => _WeatherDetailsState();
}

class _WeatherDetailsState extends State<WeatherDetails> {
  var _temperatureUnit = true;

  Future<void> _loadTemperatureUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // true: Цельсий, false: Фаренгейт
      _temperatureUnit = prefs.getBool('temperature') ?? true;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadTemperatureUnit();
  }

  @override
  Widget build(BuildContext context) {
    double displayTemperature = _temperatureUnit
        ? widget.weather.temperature
        : (widget.weather.temperature * 1.8) + 32;

    String temperatureUnitLabel = _temperatureUnit ? "°C" : "°F";

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, size: 24, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Температура: ${displayTemperature.ceil()}$temperatureUnitLabel',
                style: TextStyle(fontSize: 18),
              )
            ],
          ),
          Row(
            children: [
              Icon(Icons.cloud, size: 24, color: Colors.blue),
              SizedBox(width: 8),
              Text('Погода: ${widget.weather.description}', style: TextStyle(fontSize: 16)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.air, size: 24, color: Colors.grey),
              SizedBox(width: 8),
              Text('Скорость ветра: ${widget.weather.windSpeed.ceil()} m/s', style: TextStyle(fontSize: 16)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.water_drop, size: 24, color: Colors.blue),
              SizedBox(width: 8),
              Text('Влажность: ${widget.weather.humidity}%', style: TextStyle(fontSize: 16)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.cloudy_snowing, size: 24),
              SizedBox(width: 8),
              Text('Осадки: ${widget.weather.precipitation}', style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

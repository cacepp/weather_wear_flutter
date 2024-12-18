import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import 'package:weather_wear_flutter/pages/city_picker_page.dart';
import 'package:weather_wear_flutter/pages/date_picker_page.dart';

import 'services/api_service.dart';
import 'services/weather_service.dart';
import 'db.dart';

void main() async {
  await dotenv.load(fileName: "env/.env");

  WidgetsFlutterBinding.ensureInitialized();

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
  await populateDatabase(db);

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
        page = WeatherPage();
        _selectedPageName = 'Погода';
      case 2:
        page = SettingsPage();
        _selectedPageName = 'Настройки';
      case 3:
        if (appState.weatherData != null) {
          page = RecommendationPage(
            weatherData: appState.weatherData!,
            recommendation: appState.recommendation,
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
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  TextEditingController cityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCityFromPreferences();
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
                        Text('${forecast.temperature.ceil()}°C', style: TextStyle(fontSize: 20)),
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
                      ),
                    ),
                  );
                }
              },
              child: Text('Получить рекомендацию'),
            )
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

class WeatherDetails extends StatelessWidget {
  final WeatherData weather;

  WeatherDetails({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.thermostat, size: 24, color: Colors.orange),
              SizedBox(width: 8),
              Text('Температура: ${weather.temperature.ceil()}°C', style: TextStyle(fontSize: 18)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.cloud, size: 24, color: Colors.blue),
              SizedBox(width: 8),
              Text('Погода: ${weather.description}', style: TextStyle(fontSize: 16)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.air, size: 24, color: Colors.grey),
              SizedBox(width: 8),
              Text('Скорость ветра: ${weather.windSpeed.ceil()} m/s', style: TextStyle(fontSize: 16)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.water_drop, size: 24, color: Colors.blue),
              SizedBox(width: 8),
              Text('Влажность: ${weather.humidity}%', style: TextStyle(fontSize: 16)),
            ],
          ),
          Row(
            children: [
              Icon(Icons.cloud, size: 24),
              SizedBox(width: 8),
              Text('Осадки: ${weather.precipitation}', style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  final Database db;

  HistoryPage({required this.db});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> historyData = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    try {
      List<Map<String, dynamic>> data = await getHistory(widget.db);
      setState(() {
        historyData = data;
      });
    } catch (e) {
      print("Error loading history data: $e");
    }
  }

  Future<void> _deleteHistory() async {
    try {
      await widget.db.rawDelete('DELETE FROM tbl_history');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Success'),
            content: Text('История успешно удалена.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Ошибка при удалении всех записей: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(
            height: 650,
            child: historyData.isNotEmpty
                ? ListView.builder(
              itemCount: historyData.length,
              itemBuilder: (context, index) {
                final item = historyData[index];
                return _buildWeatherHistoryCard(item);
              },
            )
                : Center(child: Text('Нет запросов.')),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _deleteHistory();
              print('History deleted');
              _loadHistoryData();
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Удалить историю'),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherHistoryCard(Map<String, dynamic> weather) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с датой
          Text(
            weather['Date'],
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Иконка погоды и осадки
              Column(
                children: [
                  Icon(
                    weather['Precipitation'] == 'Rain'
                        ? Icons.cloud_queue
                        : Icons.wb_sunny, // Иконка зависит от осадков
                    size: 50,
                    color: weather['Precipitation'] == 'Rain'
                        ? Colors.blueGrey
                        : Colors.orangeAccent,
                  ),
                  Text(
                    weather['Precipitation'],
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Температуры и влажность
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temperature: ${weather['Temperature']}°C',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    'Feels like: ${weather['FeelingTemperature']}°C',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.water_drop, size: 18, color: Colors.blue),
                      const SizedBox(width: 5),
                      Text('${weather['Wet']} %'),
                      const SizedBox(width: 15),
                      Icon(Icons.air, size: 18, color: Colors.grey),
                      const SizedBox(width: 5),
                      Text(
                          '${weather['WindSpeed']} m/s ${weather['WindDirection']}'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Текст рекомендации
          Text(
            weather['RecommendationText'],
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          // Оценка пользователя
          Row(
            children: [
              const Text(
                'User Rating:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 5),
              for (int i = 0; i < weather['UserRating']; i++)
                const Icon(Icons.star, color: Colors.amber, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _temperatureUnit = false;
  bool _notifications = false;
  bool _gender = false;
  String _birthDate = '';
  String _city = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temperatureUnit = prefs.getBool('temperature') ?? true;
      _notifications = prefs.getBool('notifications') ?? false;
      _gender = prefs.getBool('gender') ?? true;
      _birthDate = prefs.getString('birthDate') ??
          DateTime.now().toIso8601String();
      _city = prefs.getString('city') ?? 'Не выбран';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool('temperature', _temperatureUnit);
      prefs.setBool('notifications', _notifications);
      prefs.setBool('gender', _gender);
      prefs.setString('birthDate', _birthDate);
      prefs.setString('city', _city);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Единица измерения\n температуры', style: TextStyle(fontSize: 20)),
                FlutterSwitch(
                  value: _temperatureUnit,
                  width: 104.0,
                  height: 47.0,
                  borderRadius: 50.0,
                  valueFontSize: 25.0,
                  switchBorder: Border(
                    top: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                    right: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                    bottom: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                    left: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                  ),
                  activeText: "°С",
                  activeTextColor: Color.fromRGBO(255, 255, 255, 1),
                  activeColor: Color.fromRGBO(0, 114, 188, 1),
                  inactiveText: "°F",
                  inactiveTextColor: Color.fromRGBO(0, 114, 188, 1),
                  inactiveColor: Color.fromRGBO(255, 255, 255, 1),
                  inactiveToggleColor: Color.fromRGBO(0, 114, 188, 1),
                  showOnOff: true,
                  toggleSize: 37.0,
                  onToggle: (val) {
                    setState(() {
                      _temperatureUnit = val;
                      print(_temperatureUnit);
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            SizedBox(height: 24,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Город\n$_city', style: TextStyle(fontSize: 20)),
                ElevatedButton(
                    onPressed: () async {
                      String? selectedCity = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CityPickerPage()),
                      );
                      if (selectedCity != null) {
                        setState(() {
                          _city = selectedCity;
                        });
                        _saveSettings();
                      }
                    },
                    child: Text('Изменить')
                )
              ],
            ),
            SizedBox(height: 24,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Уведомления', style: TextStyle(fontSize: 20)),
                FlutterSwitch(
                  value: _notifications,
                  width: 104.0,
                  height: 47.0,
                  borderRadius: 50.0,
                  valueFontSize: 25.0,
                  switchBorder: Border(
                    top: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                    right: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                    bottom: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                    left: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                  ),
                  activeText: "ON",
                  activeTextColor: Color.fromRGBO(255, 255, 255, 1),
                  activeColor: Color.fromRGBO(0, 114, 188, 1),
                  inactiveText: "OFF",
                  inactiveTextColor: Color.fromRGBO(0, 114, 188, 1),
                  inactiveColor: Color.fromRGBO(255, 255, 255, 1),
                  inactiveToggleColor: Color.fromRGBO(0, 114, 188, 1),
                  showOnOff: true,
                  toggleSize: 37.0,
                  onToggle: (val) {
                    setState(() {
                      _notifications = val;
                      print(_notifications);
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            SizedBox(height: 24,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Пол', style: TextStyle(fontSize: 20)),
                FlutterSwitch(
                  value: _gender,
                  width: 104.0,
                  height: 47.0,
                  borderRadius: 50.0,
                  valueFontSize: 25.0,
                  switchBorder: Border(
                    top: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                    right: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                    bottom: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                    left: BorderSide(color: Color.fromRGBO(54, 78, 101, 1), width: 2),
                  ),
                  activeText: "М",
                  activeTextColor: Color.fromRGBO(255, 255, 255, 1),
                  activeColor: Color.fromRGBO(0, 114, 188, 1),
                  inactiveText: "Ж",
                  inactiveTextColor: Color.fromRGBO(0, 114, 188, 1),
                  inactiveColor: Color.fromRGBO(255, 255, 255, 1),
                  inactiveToggleColor: Color.fromRGBO(0, 114, 188, 1),
                  showOnOff: true,
                  toggleSize: 37.0,
                  onToggle: (val) {
                    setState(() {
                      _gender = val;
                      print(_gender);
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            SizedBox(height: 24,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    'Дата рождения\n${_birthDate.split('T')[0]}',
                    style: TextStyle(fontSize: 20)
                ),
                ElevatedButton(
                    onPressed: () async {
                      String? selectedDate = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => DatePickerPage()),
                      );
                      if (selectedDate != null) {
                        setState(() {
                          _birthDate = selectedDate;
                        });
                        _saveSettings();
                      }
                    },
                    child: Text('Изменить')
                )
              ],
            ),
            SizedBox(height: 24,),

          ],
        ),
      ),
    );
  }
}

class RecommendationPage extends StatelessWidget {
  final WeatherData weatherData;
  final String recommendation;

  const RecommendationPage({
    super.key,
    required this.weatherData,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat('dd MMMM').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Рекомендация'),
        centerTitle: true,
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              color: Colors.lightBlue.shade100,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Сегодня - $todayDate',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.cloud, size: 50, color: Colors.blueGrey),
                          Text(weatherData.description),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('На улице: ${weatherData.temperature}°C'),
                          Text('По ощущениям: ${weatherData.temperature - 3}°C'),
                          Text('Влажность: ${weatherData.humidity}%'),
                          Text('Ветер: ${weatherData.windSpeed} м/с'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                recommendation,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:weather_wear_flutter/pages/city_picker_page.dart';
import 'package:weather_wear_flutter/pages/date_picker_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

import 'services/weather_service.dart';
import 'services/db.dart';

Future<Database> initDatabase() async {
  try {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'recom.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE tbl_history ('
            'id INTEGER PRIMARY KEY AUTOINCREMENT, '
            'Temperature REAL, '
            'Wet REAL, '
            'WindDirection TEXT, '
            'WindSpeed REAL, '
            'Precipitation TEXT, '
            'FeelingTemperature REAL, '
            'Date TEXT, '
            'RecommendationText TEXT, '
            'UserRating INTEGER'
          ')',
        );
      },
    );
  } catch (e) {
    print('Error initializing database: $e');
    rethrow;
  }
}

void main() async {
  await dotenv.load(fileName: "env/.env");

  WidgetsFlutterBinding.ensureInitialized();

  final db = await initDatabase();


  // ПОТОМ УБРАТЬ
  await populateDatabase(db);



  runApp(App(database: db,));
}

class App extends StatelessWidget {
  final Database database;

  const App({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppState(database),
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
  final Database db;

  AppState(this.db);
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

  //TODO: вынести состояние страницы настроек в глобальное (т.е. сюда)
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
      case 1:
        page = WeatherPage();
        _selectedPageName = 'Погода';
      case 2:
        page = SettingsPage();
        _selectedPageName = 'Настройки';
      default:
        throw UnimplementedError('no widget for $_selectedIndex');
    }

    return Scaffold(
      appBar: AppBar(

        title: Text(
          _selectedPageName,
          style: TextStyle(
            fontSize: 40.0,
          ),
        ),
        foregroundColor: Color.fromRGBO(42, 58, 74, 1),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              child:
              Container(
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
                  label: 'Погода'
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
      )
    );
  }
}

class WeatherPage extends StatefulWidget {
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  @override
  Widget build(BuildContext context) {
    //TODO: сделать слайдер
    var appState = context.watch<AppState>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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

class HistoryPage extends StatefulWidget {
  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // late Future<List<Recommendation>> recommendations;
  //
  // @override
  // void initState() {
  //   super.initState();
  //
  //   // TODO: Исправить ошибку
  //   // Initialize recommendations using the AppState provider
  //   final db = Provider.of<AppState>(context, listen: false).db;
  //   recommendations = getHistory(db);
  // }

  @override
  Widget build(BuildContext context) {
    return Placeholder();
    // return FutureBuilder<List<Recommendation>>(
    //   future: recommendations,
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return Center(child: CircularProgressIndicator());
    //     } else if (snapshot.hasError) {
    //       return Center(child: Text('Error: ${snapshot.error}'));
    //     } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
    //       return Center(child: Text('No history available.'));
    //     }
    //
    //     final data = snapshot.data!;
    //     return ListView.builder(
    //       itemCount: data.length,
    //       itemBuilder: (context, index) {
    //         final recommendation = data[index];
    //         return ListTile(
    //           title: Text(recommendation.RecommendationText),
    //           subtitle: Text(
    //             'Date: ${recommendation.Date} | Temp: ${recommendation.Temperature}°C',
    //           ),
    //           trailing: Text('Rating: ${recommendation.UserRating}/5'),
    //         );
    //       },
    //     );
    //   },
    // );
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

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:weather_wear_flutter/pages/city_picker_page.dart';
import 'package:weather_wear_flutter/pages/date_picker_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:intl/intl.dart';

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
  String city = '';  // City name
  WeatherData? weatherData;  // Current weather data
  List<WeatherForecast> weatherForecast = [];  // 5-day weather forecast

  final WeatherService weatherService = WeatherService();

  // Update city
  void updateCity(String newCity) {
    city = newCity;
    notifyListeners();
  }

  // Fetch current weather
  Future<void> fetchCurrentWeather() async {
    try {
      final weather = await weatherService.fetchCurrentWeather(city);
      weatherData = weather;
      notifyListeners();
    } catch (e) {
      print('Error fetching current weather: $e');
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
  TextEditingController cityController = TextEditingController(); // Controller for city input

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
          // City input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: cityController,
              decoration: InputDecoration(
                labelText: 'Enter city',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                appState.updateCity(value);
                appState.fetchCurrentWeather();
                appState.fetchWeatherForecast(); // Fetch forecast for the city
              },
            ),
          ),
          SizedBox(height: 20),

          // City and current weather display
          Text(
            'Current Weather for ${appState.city}',
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
                  color: Colors.grey[200], // Background color
                  borderRadius: BorderRadius.circular(10), // Rounded corners
                ),
                child: Column(
                  children: [
                    Text(forecast.date, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('${forecast.temperature}°C', style: TextStyle(fontSize: 20)),
                    Text(forecast.description, style: TextStyle(fontSize: 14)),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.air, size: 24), // Icon for wind
                        SizedBox(width: 8),
                        Text('Wind: ${forecast.windSpeed} m/s', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Text(_getWindDirection(forecast.windDegree), style: TextStyle(fontSize: 14)), // Text for wind direction
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.water_drop, size: 24), // Icon for humidity
                        SizedBox(width: 8),
                        Text('Humidity: ${forecast.humidity}%', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     Icon(Icons.cloud, size: 24), // Icon for precipitation
                    //     SizedBox(width: 8),
                    //     Text('Precipitation: ${forecast.precipitation}', style: TextStyle(fontSize: 14)),
                    //   ],
                    // ),
                  ],
                ),
              );
            },
            options: CarouselOptions(
              height: 400,
              enlargeCenterPage: true,
              scrollDirection: Axis.vertical, // Vertical scroll
              enableInfiniteScroll: false,
            ),
          ),

          SizedBox(height: 20),

          // Refresh button for weather data
          ElevatedButton(
            onPressed: () async {
              final appState = Provider.of<AppState>(context, listen: false);
              await appState.fetchCurrentWeather();
              await appState.fetchWeatherForecast();
            },
            child: Text('Refresh Weather'),
          ),
        ],
      ),
    );
  }

  // Function to get wind direction as text
  String _getWindDirection(int windDegree) {
    if (windDegree >= 0 && windDegree < 22.5) {
      return 'N';  // Север
    } else if (windDegree >= 22.5 && windDegree < 45) {
      return 'NNE'; // Северо-северо-восток
    } else if (windDegree >= 45 && windDegree < 67.5) {
      return 'NE';  // Северо-восток
    } else if (windDegree >= 67.5 && windDegree < 90) {
      return 'ENE'; // Восточно-северо-восток
    } else if (windDegree >= 90 && windDegree < 112.5) {
      return 'E';   // Восток
    } else if (windDegree >= 112.5 && windDegree < 135) {
      return 'ESE'; // Восточно-юго-восток
    } else if (windDegree >= 135 && windDegree < 157.5) {
      return 'SE';  // Юго-восток
    } else if (windDegree >= 157.5 && windDegree < 180) {
      return 'SSE'; // Южно-юго-восток
    } else if (windDegree >= 180 && windDegree < 202.5) {
      return 'S';   // Южный
    } else if (windDegree >= 202.5 && windDegree < 225) {
      return 'SSW'; // Южно-северо-запад
    } else if (windDegree >= 225 && windDegree < 247.5) {
      return 'SW';  // Южно-запад
    } else if (windDegree >= 247.5 && windDegree < 270) {
      return 'WSW'; // Западно-юго-запад
    } else if (windDegree >= 270 && windDegree < 292.5) {
      return 'W';   // Запад
    } else if (windDegree >= 292.5 && windDegree < 315) {
      return 'WNW'; // Западно-северо-запад
    } else if (windDegree >= 315 && windDegree < 337.5) {
      return 'NW';  // Северо-запад
    } else {
      return 'NNW'; // Северо-северо-запад (для случая, когда градус 337.5)
    }
  }
}

class WeatherDetails extends StatelessWidget {
  final WeatherData weather;

  WeatherDetails({required this.weather});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(Icons.thermostat, size: 24),  // Icon for temperature
            SizedBox(width: 8),
            Text('Temperature: ${weather.temperature}°C', style: TextStyle(fontSize: 18)),
          ],
        ),
        Row(
          children: [
            Icon(Icons.cloud, size: 24),  // Icon for weather description
            SizedBox(width: 8),
            Text('Description: ${weather.description}', style: TextStyle(fontSize: 16)),
          ],
        ),
        Row(
          children: [
            Icon(Icons.air, size: 24),  // Icon for wind speed
            SizedBox(width: 8),
            Text('Wind Speed: ${weather.windSpeed} m/s', style: TextStyle(fontSize: 16)),
          ],
        ),
        Row(
          children: [
            Icon(Icons.water_drop, size: 24),  // Icon for humidity
            SizedBox(width: 8),
            Text('Humidity: ${weather.humidity}%', style: TextStyle(fontSize: 16)),
          ],
        ),
        Row(
          children: [
            Icon(Icons.cloud, size: 24),  // Icon for precipitation
            SizedBox(width: 8),
            Text('Precipitation: ${weather.precipitation}', style: TextStyle(fontSize: 16)),
          ],
        ),
      ],
    );
  }
}

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //TODO: сделать страницу с историей запросов
    return Placeholder();
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
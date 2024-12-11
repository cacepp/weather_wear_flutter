import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
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
                        Text('Wind: ${forecast.windSpeed} m/s', style: TextStyle(fontSize: 14)),
                        SizedBox(width: 8),
                        Text(_getWindDirection(forecast.windDegree), style: TextStyle(fontSize: 14)), // Text for wind direction
                      ],
                    ),
                    Text('Humidity: ${forecast.humidity}%', style: TextStyle(fontSize: 14)),
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
              await appState.fetchCurrentWeather();
              await appState.fetchWeatherForecast(); // Refresh weather data
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
      return 'SSW'; // Южно-юго-запад
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
        Text('Temperature: ${weather.temperature}°C', style: TextStyle(fontSize: 18)),
        Text('Description: ${weather.description}', style: TextStyle(fontSize: 16)),
        Text('Wind Speed: ${weather.windSpeed} m/s', style: TextStyle(fontSize: 16)),
        Text('Humidity: ${weather.humidity}%', style: TextStyle(fontSize: 16)),
        Text('Precipitation: ${weather.precipitation}', style: TextStyle(fontSize: 16)),
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

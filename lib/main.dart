import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:weather_wear_flutter/pages/city_picker_page.dart';
import 'package:weather_wear_flutter/pages/date_picker_page.dart';

void main() {
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

class WeatherPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //TODO: сделать страницу с погодой (слайдер)
    return Placeholder();
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

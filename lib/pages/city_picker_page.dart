import 'package:flutter/material.dart';

class CityPickerPage extends StatefulWidget {
  @override
  State<CityPickerPage> createState() => _CityPickerPageState();
}

class _CityPickerPageState extends State<CityPickerPage> {
  String? _selectedCity;


  //TODO: Реализовать fetch для городов
  final List<String> cities = [
    'Москва',
    'Санкт-Петербург',
    'Новосибирск',
    'Екатеринбург',
    'Нижний Новгород',
    'Казань',
    'Челябинск',
    'Омск',
    'Самара',
    'Ростов-на-Дону',
    'Петрозаводск',
    'Мурманск',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Выбор города'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: _selectedCity,
              hint: Text('Выберите город'),
              onChanged: (newValue) {
                setState(() {
                  _selectedCity = newValue;
                });
              },
              items: cities.map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                print('Город выбран: $_selectedCity');
                Navigator.pop(context, _selectedCity);
              },
              child: Text('Подтвердить'),
            ),
          ],
        ),
      ),
    );
  }
}

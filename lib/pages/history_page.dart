import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../db.dart';

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
    _loadTemperatureUnit();
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
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              _deleteHistory();
              print('История удалена');
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
    double displayTemperature = _temperatureUnit
        ? weather['Temperature'].toDouble()
        : (weather['Temperature'].toDouble() * 1.8) + 32;

    String temperatureUnitLabel = _temperatureUnit ? "°C" : "°F";

    double displayTemperatureFeeling = _temperatureUnit
        ? weather['Temperature'].toDouble()
        : ((weather['Temperature'].toDouble() - 3) * 1.8) + 32;

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${displayTemperature.ceil()} $temperatureUnitLabel',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
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
          Text(
            weather['RecommendationText'],
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Оценка:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 5),
              for (int i = 0; i < weather['UserRating']; i++)
                const Icon(Icons.star, color: Colors.amber, size: 16),
              if (weather['UserRating'] < 5)
                for (int i = 0; i < 5 - weather['UserRating']; i++)
                  const Icon(Icons.star, color: Colors.black12, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

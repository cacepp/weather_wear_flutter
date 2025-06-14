import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../services/weather_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../db.dart';

class RecommendationPage extends StatefulWidget {
  final WeatherData weatherData;
  final String recommendation;
  final Database db;

  RecommendationPage({
    required this.weatherData,
    required this.recommendation,
    required this.db,
  });

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  var _rating = 0;

  void _saveRecommendation() async {
    final Recommendation record = Recommendation(
      Temperature: widget.weatherData.temperature,
      Wet: widget.weatherData.humidity.toDouble(),
      WindDirection: widget.weatherData.windDegree.toString(),
      WindSpeed: widget.weatherData.windSpeed,
      Precipitation: widget.weatherData.precipitation,
      FeelingTemperature: widget.weatherData.temperature,
      Date: DateTime.now().toIso8601String(),
      RecommendationText: widget.recommendation,
      UserRating: _rating,
    );

    await addRecord(record, widget.db);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Рекомендация сохранена")),
    );
  }

  var _temperatureUnit = true;

  Future<void> _loadTemperatureUnit() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // true: Цельсий, false: Фаренгейт
      _temperatureUnit = prefs.getBool('temperature') ?? true;
    });
  }

  Future<void> _shareToTG() async {
    final String todayDate = DateFormat('dd MMMM').format(DateTime.now());

    // Форматируем текст для публикации
    double displayTemperature = _temperatureUnit
        ? widget.weatherData.temperature
        : (widget.weatherData.temperature * 1.8) + 32;

    String temperatureUnitLabel = _temperatureUnit ? "°C" : "°F";

    final String textToShare = '''
Текущая погода на $todayDate:
Погода: ${widget.weatherData.description}
Температура: ${displayTemperature.toStringAsFixed(1)}$temperatureUnitLabel
Влажность: ${widget.weatherData.humidity.toStringAsFixed(0)}%
Скорость ветра: ${widget.weatherData.windSpeed.toStringAsFixed(1)} м/с

Рекомендация: ${widget.recommendation}
    ''';

    // Кодируем текст
    final String encodedText = Uri.encodeComponent(textToShare);

    // Формируем ссылку для Telegram
    final Uri telegramUrl =
    Uri.parse('https://t.me/share/url?text=$encodedText');

    // Открываем ссылку
    if (await canLaunchUrl(telegramUrl)) {
      await launchUrl(telegramUrl, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть Telegram')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTemperatureUnit();
  }

  @override
  Widget build(BuildContext context) {
    final String todayDate = DateFormat('dd MMMM').format(DateTime.now());

    double displayTemperature = _temperatureUnit
        ? widget.weatherData.temperature
        : (widget.weatherData.temperature * 1.8) + 32;

    String temperatureUnitLabel = _temperatureUnit ? "°C" : "°F";


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
                          Text(widget.weatherData.description),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Температура: ${displayTemperature.toStringAsFixed(1)}$temperatureUnitLabel'),
                          Text('Влажность: ${widget.weatherData.humidity.toStringAsFixed(0)}%'),
                          Text('Ветер: ${widget.weatherData.windSpeed.toStringAsFixed(1)} м/с'),
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
                widget.recommendation,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            RatingBar.builder(
              initialRating: 0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 5,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                setState(() {
                  _rating = rating.toInt();
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () {
              _saveRecommendation();
              print('Сохранено');
            },
              child: Text("Сохранить"),
            ),
            ElevatedButton(
              onPressed: _shareToTG,
              child: Text("Поделиться в TG"),
            ),
          ],
        ),
      ),
    );
  }
}

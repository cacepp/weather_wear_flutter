import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../services/weather_service.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
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
                          Text(widget.weatherData.description),
                        ],
                      ),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('На улице: ${widget.weatherData.temperature}°C'),
                          Text('По ощущениям: ${widget.weatherData.temperature - 3}°C'),
                          Text('Влажность: ${widget.weatherData.humidity}%'),
                          Text('Ветер: ${widget.weatherData.windSpeed} м/с'),
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
            ElevatedButton(
              onPressed: () {
                _saveRecommendation();
                print('saved');
              },
              child: Text("Сохранить"),
            ),
          ],
        ),
      ),
    );
  }
}

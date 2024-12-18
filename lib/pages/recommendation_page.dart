// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // Для форматирования даты
// import '../services/weather_service.dart'; // Подключение сервиса погоды
// import '../services/api_service.dart'; // Подключение API сервиса
//
// class RecommendationPage extends StatelessWidget {
//   final WeatherData weatherData;
//   final String recommendation;
//
//   const RecommendationPage({
//     super.key,
//     required this.weatherData,
//     required this.recommendation,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     final String todayDate = DateFormat('dd MMMM').format(DateTime.now());
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Рекомендация'),
//         centerTitle: true,
//         backgroundColor: Colors.lightBlueAccent,
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Container(
//               color: Colors.lightBlue.shade100,
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 children: [
//                   Text(
//                     'Сегодня - $todayDate',
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Column(
//                         children: [
//                           Icon(Icons.cloud, size: 50, color: Colors.blueGrey),
//                           Text(weatherData.description),
//                         ],
//                       ),
//                       const SizedBox(width: 20),
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('На улице: ${weatherData.temperature}°C'),
//                           Text('По ощущениям: ${weatherData.temperature - 3}°C'),
//                           Text('Влажность: ${weatherData.humidity}%'),
//                           Text('Ветер: ${weatherData.windSpeed} м/с'),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(16.0),
//               child: Text(
//                 recommendation,
//                 style: const TextStyle(fontSize: 18),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import '../services/weather_service.dart';

class RecommendationPage extends StatefulWidget {
  final WeatherData weatherData;
  final String recommendation;

  RecommendationPage({
    required this.weatherData,
    required this.recommendation,
  });

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Рекомендация'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.recommendation)
          ],
        ),
      ),
    );
  }
}
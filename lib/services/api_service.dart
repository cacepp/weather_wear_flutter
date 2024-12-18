import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL API
  static const String baseUrl = 'http://195.133.13.249:8000/predict';

  Future<Map<String, dynamic>> getRecommendations({
    required double temperature,
    required double windSpeed,
    required double precipitation,
    required String sex,
    required int age,
  }) async {
    final Map<String, dynamic> requestBody = {
      "Temperature": temperature,
      "Wind_Speed": windSpeed,
      "Precipitation": precipitation,
      "Sex": sex,
      "Age": age,
    };

    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        return {
          "error": "Error: ${response.statusCode}, ${response.body}",
          "success": false,
        };
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      return {
        "recommendation": data['recommendation'],
        "success": true,
      };
    } catch (e) {
      return {
        "error": "Connection error: $e",
        "success": false,
      };
    }
  }
}

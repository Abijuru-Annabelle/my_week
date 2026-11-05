import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather.dart';

// REPOSITORY: the only class that talks to the weather server.
class WeatherRepository {
  Future<Weather> fetchKigali() async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=-1.9441&longitude=30.0619'
      '&current=temperature_2m,weather_code'
      '&timezone=Africa%2FKigali',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('The weather server answered ${response.statusCode}');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return Weather.fromJson(data['current'] as Map<String, dynamic>);
  }
}

// MODEL: says what a weather report is.
class Weather {
  Weather({required this.temperature, required this.code});

  final double temperature;
  final int code;

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      code: (json['weather_code'] as num).toInt(),
    );
  }
}

String describe(int code) {
  if (code == 0) return 'Clear sky';
  if (code <= 2) return 'Partly cloudy';
  if (code == 3) return 'Cloudy';
  if (code == 45 || code == 48) return 'Fog';
  if (code >= 51 && code <= 57) return 'Drizzle';
  if (code >= 61 && code <= 67) return 'Rain';
  if (code >= 80 && code <= 82) return 'Rain showers';
  if (code >= 95) return 'Thunderstorm';
  return 'Unknown';
}

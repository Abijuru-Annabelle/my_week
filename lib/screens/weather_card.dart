import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../repositories/weather_repository.dart';

// Only this card cares about the weather, so it is ephemeral state:
// it stays inside this widget, changed with setState.
class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final _repo = WeatherRepository();
  Weather? _weather;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await _repo.fetchKigali();
      if (!mounted) return;
      setState(() {
        _weather = result;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the weather. Check your internet connection.';
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.wifi_off),
              const SizedBox(width: 12),
              Expanded(child: Text(_error!)),
              FilledButton(onPressed: _retry, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    return Card(
      child: ListTile(
        leading: const Icon(Icons.cloud, color: Colors.teal),
        title: Text('Kigali now: ${_weather!.temperature.round()}°C'),
        subtitle: Text(describe(_weather!.code)),
      ),
    );
  }
}

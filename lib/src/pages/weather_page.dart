import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridingpartner_flutter/src/provider/weather_provider.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  @override
  Widget build(BuildContext context) {
    Provider.of<WeatherProvider>(context).getWeather();
    var weather = Provider.of<WeatherProvider>(context).weather;
    var loadingStatus = Provider.of<WeatherProvider>(context).loadingStatus;
    var message = Provider.of<WeatherProvider>(context).message;

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(weather.skyType ?? 'Loading...'),
            Text(weather.temperature ?? '온도'),
            Text(weather.humidity ?? '습도'),
            Text(weather.rainType ?? '비'),
            Text(message),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Go back!'),
            ),
          ],
        ),
      ),
    );
  }
}

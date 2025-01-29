import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:intl/intl.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        textTheme: CupertinoTextThemeData(
          textStyle: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 18,
            color: CupertinoColors.black,
          ),
        ),
      ),
      home: ClockPage(),
    );
  }
}

class ClockPage extends StatefulWidget {
  @override
  _ClockPageState createState() => _ClockPageState();
}

class _ClockPageState extends State<ClockPage> {
  late String _currentTime;
  late String _currentDate;
  late Timer _timer;
  String _temperature = "--°C";
  String _weatherCondition = "Loading...";
  String _location = "Fetching location...";

  @override
  void initState() {
    super.initState();
    _updateTime();
    _getLocationAndWeather();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _updateTime();
      });
    });

    Timer.periodic(Duration(minutes: 10), (timer) {
      _getLocationAndWeather();
    });
  }

  void _updateTime() {
    _currentTime = DateFormat('hh:mm:ss a').format(DateTime.now());
    _currentDate = DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());
  }

  Future<void> _getLocationAndWeather() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _location = "Location disabled";
        _weatherCondition = "Cannot fetch weather";
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _location = "Permission denied";
          _weatherCondition = "Cannot fetch weather";
        });
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _location = "Lat: ${position.latitude}, Lon: ${position.longitude}";
    });

    _fetchWeather(position.latitude, position.longitude);
  }

  Future<void> _fetchWeather(double lat, double lon) async {
    final apiKey =
        "8e8b91972447e6527d3ff5da24cc63d1"; // Replace with OpenWeather API key
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _temperature = "${data['main']['temp'].toStringAsFixed(1)}°C";
          _weatherCondition = data['weather'][0]['description'];
        });
      } else {
        setState(() {
          _weatherCondition = "Error fetching weather";
        });
      }
    } catch (e) {
      setState(() {
        _weatherCondition = "No Internet";
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Clock & Weather',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentDate,
              style: TextStyle(
                fontSize: 22,
                color: CupertinoColors.systemGrey,
              ),
            ),
            SizedBox(height: 10),
            Text(
              _currentTime,
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.activeBlue,
              ),
            ),
            SizedBox(height: 20),
            CupertinoActivityIndicator(),
            SizedBox(height: 10),
            Text(
              _temperature,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.systemGrey,
              ),
            ),
            Text(
              _weatherCondition,
              style:
                  TextStyle(fontSize: 20, color: CupertinoColors.systemGrey2),
            ),
            SizedBox(height: 20),
            Text(
              _location,
              style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
            ),
          ],
        ),
      ),
    );
  }
}

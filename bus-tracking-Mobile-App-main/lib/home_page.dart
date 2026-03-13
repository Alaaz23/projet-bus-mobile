import 'dart:async';
import 'package:bus_tracking/api.dart';
import 'package:bus_tracking/my_app_bar.dart';
import 'package:bus_tracking/my_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:quickalert/quickalert.dart';

class HomePage extends StatefulWidget {
  final String matricule;
  final String nom;
  final String prenom;
  final int id;
  final int id_st;
  final int id_b;
  final String password;

  const HomePage({
    Key? key,
    required this.matricule,
    required this.nom,
    required this.prenom,
    required this.id,
    required this.id_st,
    required this.id_b,
    required this.password,
  }) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> stations = [];
  bool _isLoading = true;
  List listOfPoints = [];
  List<Marker> mapMarkers = [];
  LatLng? busPosition; // Variable to store bus position

  List<LatLng> points = [];
  LatLng? salarieStation;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    fetchStations();
    fetchStationSalarie();
    fetchBusPosition();
    // Start the timer when the widget is initialized
    _timer = Timer.periodic(Duration(seconds: 30), (Timer timer) {
      fetchBusPosition();
    });
  }

  @override
  void dispose() {
    super.dispose();
    // Cancel the timer when the widget is disposed
    _timer?.cancel();
  }

  getCoordinates(List<Marker> markers) async {
    try {
      for (int i = 0; i < markers.length - 1; i++) {
        Marker marker1 = markers[i];
        double latitude1 = marker1.point.latitude;
        double longitude1 = marker1.point.longitude;
        Marker marker2 = markers[i + 1];
        double latitude2 = marker2.point.latitude;
        double longitude2 = marker2.point.longitude;

        debugPrint('Fetching route for markers $i and ${i + 1}...');

        var response = await http.get(getRouteUrl(
          '$longitude1,$latitude1',
          '$longitude2,$latitude2',
        ));

        debugPrint('Response for markers $i and ${i + 1}: ${response.body}');

        setState(() {
          if (response.statusCode == 200) {
            var data = jsonDecode(response.body);
            List<dynamic> listOfPoints =
                data['features'][0]['geometry']['coordinates'];
            List<LatLng> newPoints = listOfPoints
                .map((p) => LatLng(p[1].toDouble(), p[0].toDouble()))
                .toList();
            points.addAll(newPoints);
          }
        });

        debugPrint('Latitude: $latitude1, Longitude: $longitude1');
        debugPrint('Latitude: $latitude2, Longitude: $longitude2');
      }
    } catch (e) {
      debugPrint('Error fetching route data: $e');
    }
  }

  getDistance(LatLng? busPosition, LatLng? salarieStation) async {
    double latitude1 = busPosition!.latitude;
    double longitude1 = busPosition.longitude;
    double latitude2 = salarieStation!.latitude;
    double longitude2 = salarieStation.longitude;
    double distance = 0;
    double duration = 0;
    var response = await http.get(getRouteUrl(
      '$longitude1,$latitude1',
      '$longitude2,$latitude2',
    ));
    setState(() {
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        distance = (data['features'][0]['properties']['summary']['distance']
                .toDouble()) /
            1000;
        int m = (distance % 1 * 60).round();
        duration = (data['features'][0]['properties']['summary']['duration']
                .toDouble()) /
            60;
        int r = (duration % 1 * 60).round();
        print('Total distance: $distance meters');
        if (distance < 5) {
          // Show quick alert if distance is shorter than 5000 meters
          QuickAlert.show(
            context: context,
            type: QuickAlertType.info,
            text:
                'Total distance is shorter than ${distance.toInt()} km and $m meters and ${duration.toInt()} minutes and $r seconds',
          );
        }
      }
    });
  }

  Future<void> fetchStationSalarie() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8081/Bus-tracking/stations/${widget.id_st}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double latitude = data['latitude'];
        double longitude = data['longitude'];
        setState(() {
          salarieStation = LatLng(latitude, longitude);
          print(salarieStation);
        });
      } else {
        print('Failed to fetch salarie`s station: ${response.statusCode}');
      }
    } catch (e) {
      print('An error occurred while fetching salarie`s station: $e');
    }
  }

  Future<void> fetchBusPosition() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8081/Bus-tracking/buses/${widget.id_b}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        double latitude = data['latitude'];
        double longitude = data['longitude'];
        setState(() {
          busPosition = LatLng(latitude, longitude);
          getDistance(busPosition, salarieStation);
        });
      } else {
        print('Failed to fetch bus position: ${response.statusCode}');
      }
    } catch (e) {
      print('An error occurred while fetching bus position: $e');
    }
  }

  Future<void> fetchStations() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://10.0.2.2:8081/Bus-tracking/tragets/stations/${widget.id_st}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          stations = data;
          _isLoading = false;

          mapMarkers = stations
              .map((station) => Marker(
                    width: 30.0,
                    height: 30.0,
                    point: LatLng(station['latitude'], station['longitude']),
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                    ),
                  ))
              .toList();

          // Call getCoordinates here
          getCoordinates(mapMarkers);
        });
      } else {
        print('Failed to fetch stations: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('An error occurred while fetching stations: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: 'Bus Tracking',
      ),
      drawer: MyDrawer(
          nom: widget.nom,
          prenom: widget.prenom,
          id: widget.id,
          password: widget.password,
          matricule: widget.matricule),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: stations.isNotEmpty
                      ? FlutterMap(
                          options: MapOptions(
                            center: LatLng(stations.first['latitude'],
                                stations.first['longitude']),
                            zoom: 12.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.app',
                            ),
                            PolylineLayer(
                              polylines: [
                                Polyline(
                                  points: points,
                                  color: Colors.red,
                                  strokeWidth: 3.0,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                ...mapMarkers, // Add existing markers
                                if (busPosition != null)
                                  Marker(
                                    width: 30.0,
                                    height: 30.0,
                                    point: busPosition!,
                                    // You can customize the bus marker icon here
                                    child: Icon(
                                      Icons.directions_bus,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        )
                      : Center(
                          child: Text('No stations available.'),
                        ),
                ),
              ],
            ),
    );
  }
}

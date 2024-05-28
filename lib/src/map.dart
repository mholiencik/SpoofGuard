import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'data_logger.dart';
import 'kalman_filter.dart';
import 'sensor_handler.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  late MapController mapController;
  StreamSubscription<Position>? positionStream;

  DataLogger dataLogger = DataLogger();
  SensorHandler sensorHandler = SensorHandler();

  KalmanFilter kalmanFilter = KalmanFilter();
  bool isFiltering = true;

  LatLng? gpsPosition;
  bool isFollowing = true;


  @override
  void initState() {
    super.initState();
    mapController = MapController();

    checkPermission().then((bool hasPermission) {
      if (!hasPermission) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Denied'),
            content: const Text('Please grant location permission.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      if (hasPermission) {
        checkServiceEnabled().then((bool serviceEnabled) {
          if (!serviceEnabled) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Location Service Disabled'),
                content: const Text('Please enable location services.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        });
      }
    });

    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        //timeLimit: Duration.zero,
      ),
    ).listen((Position position){
      LatLng? predictedPosition;
      setState(() {
        if (isFiltering){
          LatLng filteredPosition = kalmanFilter.process(position);
          position = Position(
            latitude: filteredPosition.latitude,
            longitude: filteredPosition.longitude,
            timestamp: position.timestamp,
            accuracy: position.accuracy,
            altitude: position.altitude,
            altitudeAccuracy: position.altitudeAccuracy,
            heading: position.heading,
            headingAccuracy: position.headingAccuracy,
            speed: position.speed,
            speedAccuracy: position.speedAccuracy,
            floor: position.floor, // unnecessary
            isMocked: position.isMocked, // unnecessary
          );
        }

        gpsPosition = LatLng(position.latitude, position.longitude);
        predictedPosition = sensorHandler.ahrsFusion.iterate(position);

        if (!sensorHandler.ahrsFusion.isAnomaly){
          locationMarkers = [
            generateMarker(gpsPosition!, const Color(0xff38789a)),
          ];
          safeWalk.add(gpsPosition!);
          if (spoofedWalks.last.isNotEmpty){
            spoofedWalks.last.add(gpsPosition!);
            spoofedWalks.add(List.empty(growable: true));
          }
        } else {
          locationMarkers = [
            generateMarker(predictedPosition!, const Color(0xff38789a)),
            generateMarker(gpsPosition!, const Color(0x66cc3421))
          ];
          if (spoofedWalks.last.isEmpty){
            spoofedWalks.last.add(safeWalk.last);
          }
          spoofedWalks.last.add(gpsPosition!);
          safeWalk.add(predictedPosition!);
        }

        if (isFollowing) {
          mapController.move(gpsPosition!, 18.0);
        }
      });
      if (sensorHandler.sensorData != null && gpsPosition != null){
        dataLogger.logSensorData(
            position.timestamp,
            sensorHandler.sensorData!,
            gpsPosition!,
            predictedPosition!,
            sensorHandler.ahrsFusion.distance,
            sensorHandler.ahrsFusion.bearingDifference,
            sensorHandler.ahrsFusion.isAnomaly
        );
      }
    });
  }

  @override
  void dispose() {
    positionStream?.cancel(); // Cancel the subscription when not in use
    sensorHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(48.153, 17.074),
                initialZoom: 14,
                interactionOptions:
                const InteractionOptions(flags: ~InteractiveFlag.doubleTapZoom),
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    setState(() {
                      isFollowing = false;
                    });
                  }
                },
              ),
              mapController: mapController,
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'dev.fleaflet.flutter_map.example',
                ),
                PolylineLayer(
                  polylines: generatePolylines(),
                ),
                MarkerLayer(
                  markers: locationMarkers,
                ),
              ],
            ),
          Positioned(
            top: 50,
            left: 20,
            child: sensorHandler.ahrsFusion.isAnomaly ? Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
              color: const Color(0xffe6b400),
              borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.error, color: Colors.black),
            ) : Container(),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: switchFiltering,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff38789a),
              child: Icon(isFiltering ? Icons.filter_alt : Icons.filter_alt_off),
            ),
            const SizedBox(
                height: 10
            ),
            FloatingActionButton(
              onPressed: resetFollowing,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff38789a),
              child: Icon(isFollowing ? Icons.gps_fixed : Icons.gps_not_fixed),
            ),
            const SizedBox(
                height: 10
            ),
            FloatingActionButton(
              onPressed: clearRoute,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xff38789a),
              child: const Icon(Icons.refresh), //delete_forever
            ),
          ],
        ),
      ),
    );
  }

  Future<void> switchFiltering() async {
    setState(() {
      isFiltering = !isFiltering;
      if (isFiltering) {
        kalmanFilter = KalmanFilter();
      }
    });
  }

  Future<void> resetFollowing() async {
    setState(() {
      isFollowing = true;
      mapController.rotate(0);
      mapController.move(gpsPosition!, 18.0);
    });
  }

  Future<void> clearRoute() async {
    dataLogger.dispose();
    dataLogger = DataLogger();
    sensorHandler = SensorHandler();
    kalmanFilter = KalmanFilter();

    // Clear routes.
    safeWalk.clear();
    spoofedWalks.clear();
    spoofedWalks.add(List.empty(growable: true));

    // Add the current location to the route.
    safeWalk.add(gpsPosition!);
  }

  generatePolylines(){
    List<Polyline> polylines = [];
    polylines.add(
      Polyline(
        points: safeWalk,
        strokeWidth: 3,
        color: const Color(0xff38789a),
      ),
    );
    for (List<LatLng> walk in spoofedWalks) {
      polylines.add(
        Polyline(
          points: walk,
          strokeWidth: 3,
          color: const Color(0x66cc3421),
        ),
      );
    }
    return polylines;
  }

  Marker generateMarker(LatLng point, Color color){
    return Marker(
      width: 80,
      height: 80,
      point: point,
      child: Icon(
        Icons.radio_button_checked,
        color: color,
      ),
    );
  }
}

List<Marker> locationMarkers = List.empty(growable: true);

final List<LatLng> safeWalk = List.empty(growable: true);

final List<List<LatLng>> spoofedWalks = [List.empty(growable: true)];

Future<bool> checkPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      return false;
    }
  }
  return true;
}

Future<bool> checkServiceEnabled() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return false;
  }
  return true;
}
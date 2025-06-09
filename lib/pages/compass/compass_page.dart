import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

class CompassPage extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationName;

  const CompassPage({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationName,
  });

  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> {
  double? _userHeading = 0.0;
  double? _bearingToDestination;
  double? _distance;

  @override
  void initState() {
    super.initState();
    FlutterCompass.events?.listen((CompassEvent event) {
      if (mounted) {
        setState(() {
          _userHeading = event.heading;
        });
      }
    });
    Geolocator.getPositionStream().listen((Position position) {
      if (mounted) {
        _calculateMetrics(position);
      }
    });
  }

  void _calculateMetrics(Position userPosition) {
    final distance = Geolocator.distanceBetween(
      userPosition.latitude,
      userPosition.longitude,
      widget.destinationLat,
      widget.destinationLng,
    );

    final bearing = Geolocator.bearingBetween(
      userPosition.latitude,
      userPosition.longitude,
      widget.destinationLat,
      widget.destinationLng,
    );

    setState(() {
      _distance = distance;
      _bearingToDestination = (bearing < 0) ? bearing + 360 : bearing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Arah ke ${widget.destinationName}')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Arahkan bagian atas ponsel ke tujuan', textAlign: TextAlign.center),
            const SizedBox(height: 30),
            _buildCompass(),
            const SizedBox(height: 30),
            Text(
              _distance == null ? 'Menghitung jarak...' : 'Jarak: ${(_distance! / 1000).toStringAsFixed(2)} km',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompass() {
    if (_userHeading == null || _bearingToDestination == null) {
      return const CircularProgressIndicator();
    }
    final angle = (_bearingToDestination! - _userHeading!) * (math.pi / 180) * -1;

    return Transform.rotate(
      angle: angle,
      child: const Icon(
        Icons.navigation_rounded,
        size: 200,
        color: Colors.deepPurpleAccent,
      ),
    );
  }
}
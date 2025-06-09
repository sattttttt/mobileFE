import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:acara_kita/api/api_service.dart';
import 'package:acara_kita/services/auth_service.dart';
import 'package:acara_kita/services/notification_service.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Completer<GoogleMapController> _controller = Completer();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  Set<Marker> _markers = {};
  bool _isLoadingPlaces = false;

  // ID unik untuk marker manual kita agar bisa dihapus & diganti
  final MarkerId _customMarkerId = const MarkerId('customMarker');

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-7.7956, 110.3695),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layanan lokasi tidak aktif.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak permanen.')));
      return;
    } 

    Position position = await Geolocator.getCurrentPosition();
    
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: LatLng(position.latitude, position.longitude), zoom: 12),
    ));
    _findNearbyPlaces(position.latitude, position.longitude);
  }

  void _findNearbyPlaces(double lat, double lng) async {
    if (mounted) setState(() => _isLoadingPlaces = true);

    try {
      final List<dynamic> placesResult = await _apiService.getNearbyPlaces(lat, lng);
      
      var newMarkers = <Marker>{};
      for (var place in placesResult) {
        final placeLat = place['geometry']['location']['lat'];
        final placeLng = place['geometry']['location']['lng'];
        final placeName = place['name'];

        newMarkers.add(
          Marker(
            markerId: MarkerId(placeName),
            position: LatLng(placeLat, placeLng),
            onTap: () {
              _showAddScheduleDialog(initialTitle: placeName);
            },
            infoWindow: InfoWindow(
              title: placeName,
              snippet: 'Tambahkan ke jadwal?',
            ),
          ),
        );
      }
      
      if (mounted) setState(() => _markers = newMarkers);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error mencari tempat: $e')));
    } finally {
      if (mounted) setState(() => _isLoadingPlaces = false);
    }
  }
  
  void _showAddScheduleDialog({String initialTitle = ''}) {
    final titleController = TextEditingController(text: initialTitle);
    final descController = TextEditingController();
    DateTime? startTime;
    DateTime? endTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Jadwal Baru'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Nama Acara/Tempat', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
                    const SizedBox(height: 20),
                    Text(startTime == null ? 'Pilih Waktu Mulai' : 'Mulai: ${DateFormat('dd MMM kk, HH:mm', 'id_ID').format(startTime!)}'),
                    ElevatedButton(child: const Text('Pilih Waktu Mulai'),
                      onPressed: () async {
                        DateTime? picked = await _pickDateTime();
                        if (picked != null) setDialogState(() => startTime = picked);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(endTime == null ? 'Pilih Waktu Selesai' : 'Selesai: ${DateFormat('dd MMM kk, HH:mm', 'id_ID').format(endTime!)}'),
                    ElevatedButton(child: const Text('Pilih Waktu Selesai'),
                      onPressed: () async {
                        DateTime? picked = await _pickDateTime();
                        if (picked != null) setDialogState(() => endTime = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () => _saveSchedule(
                    title: titleController.text,
                    description: descController.text,
                    startTime: startTime,
                    endTime: endTime,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _pickDateTime() async {
    final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2030));
    if (date == null) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _saveSchedule({required String title, required String description, required DateTime? startTime, required DateTime? endTime}) async {
    if (title.isEmpty || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua field!')));
      return;
    }
    if (endTime.isBefore(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waktu selesai tidak boleh sebelum waktu mulai!')));
      return;
    }
    final userId = await _authService.getUserId();
    if (userId != null) {
        try {
          final scheduleData = await _apiService.createSchedule(
            userId: userId,
            title: title,
            description: description,
            startTime: startTime.toUtc().toIso8601String(),
            endTime: endTime.toUtc().toIso8601String(),
          );
          await NotificationService().scheduleNotification(
            id: scheduleData['schedule']['id'],
            title: 'Pengingat: $title',
            body: 'Acara Anda akan dimulai dalam 15 menit!',
            scheduledTime: startTime,
          );
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"$title" berhasil ditambahkan! Cek di tab Jadwal.')));
          }
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Peta Wisata Terdekat"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _determinePosition,
            tooltip: 'Cari Lokasi Saya',
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) _controller.complete(controller);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            // --- PENAMBAHAN FITUR BARU DI SINI ---
            onTap: (LatLng position) {
              setState(() {
                // Hapus marker manual sebelumnya (jika ada) agar hanya ada satu
                _markers.removeWhere((marker) => marker.markerId == _customMarkerId);

                // Buat marker baru di lokasi yang diketuk
                final newMarker = Marker(
                  markerId: _customMarkerId,
                  position: position,
                  // Beri warna berbeda (biru) agar bisa dibedakan
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  onTap: () {
                    _showAddScheduleDialog(initialTitle: 'Jadwal di Lokasi Pilihan');
                  },
                );

                // Tambahkan marker baru ke dalam set
                _markers.add(newMarker);
              });
            },
          ),
          
          if (_isLoadingPlaces)
            IgnorePointer(
              ignoring: true,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Mencari tempat terdekat...", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
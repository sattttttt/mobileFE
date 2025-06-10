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
  final Completer<GoogleMapController> _mapController = Completer();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  Set<Marker> _markers = {};
  bool _isLoadingPlaces = false;
  final MarkerId _customMarkerId = const MarkerId('customMarker');

  // State untuk menampilkan kartu informasi di bawah
  Marker? _selectedMarker; 
  String _selectedMarkerLocationName = '';
  String _selectedMarkerLocationAddress = '';

  static const CameraPosition _initialPosition = CameraPosition(target: LatLng(-7.7956, 110.3695), zoom: 12);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _moveCamera(LatLng target) async {
    final GoogleMapController controller = await _mapController.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(target, 15));
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layanan lokasi tidak aktif.')));
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak.')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Izin lokasi ditolak permanen.')));
      return;
    } 
    Position position = await Geolocator.getCurrentPosition();
    _moveCamera(LatLng(position.latitude, position.longitude));
    _findNearbyPlaces(position.latitude, position.longitude);
  }

  void _findNearbyPlaces(double lat, double lng) async {
    if (mounted) setState(() { _isLoadingPlaces = true; _selectedMarker = null; _markers.clear(); });
    try {
      final List<dynamic> placesResult = await _apiService.getNearbyPlaces(lat, lng);
      var newMarkers = <Marker>{};
      for (var place in placesResult) {
        final placeLat = place['geometry']['location']['lat'];
        final placeLng = place['geometry']['location']['lng'];
        final placeName = place['name'];
        final placeAddress = place['vicinity'];

        newMarkers.add(
          Marker(
            markerId: MarkerId(placeName),
            position: LatLng(placeLat, placeLng),
            infoWindow: InfoWindow(title: placeName, snippet: placeAddress),
            onTap: () {
              setState(() {
                _selectedMarkerLocationName = placeName;
                _selectedMarkerLocationAddress = placeAddress;
                _selectedMarker = newMarkers.firstWhere((m) => m.markerId.value == placeName);
              });
            },
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

  void _handleSearch() async {
    final result = await showSearch<Map<String, dynamic>?>(context: context, delegate: PlaceSearchDelegate(_apiService));
    if (result != null && result.containsKey('place_id')) {
      try {
        final details = await _apiService.getPlaceDetails(result['place_id']);
        final locationData = details['geometry']['location'];
        final lat = locationData['lat'];
        final lng = locationData['lng'];
        final name = details['name'];
        final address = details['formatted_address'] ?? name;
        
        _moveCamera(LatLng(lat, lng));
        
        setState(() {
          _markers.clear();
          final searchMarker = Marker(
            markerId: MarkerId(name),
            position: LatLng(lat, lng),
            onTap: () {
              setState(() {
                _selectedMarkerLocationName = name;
                _selectedMarkerLocationAddress = address;
                _selectedMarker = Marker(markerId: MarkerId(name), position: LatLng(lat,lng));
              });
            },
          );
          _markers.add(searchMarker);
          _selectedMarkerLocationName = name;
          _selectedMarkerLocationAddress = address;
          _selectedMarker = searchMarker;
        });
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mendapatkan detail lokasi: $e')));
      }
    }
  }

  void _showAddScheduleDialog({String initialTitle = '', String initialLocation = '', double? lat, double? lng}) {
    final titleController = TextEditingController(text: initialTitle);
    final locationController = TextEditingController(text: initialLocation);
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
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Nama Acara', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on))),
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
                    location: locationController.text,
                    description: descController.text,
                    latitude: lat,
                    longitude: lng,
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

  void _saveSchedule({required String title, String? location, required String description, double? latitude, double? longitude, required DateTime? startTime, required DateTime? endTime}) async {
    if (title.isEmpty || startTime == null || endTime == null) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi semua field!')));
      return;
    }
    if (endTime.isBefore(startTime)) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waktu selesai tidak boleh sebelum waktu mulai!')));
      return;
    }
    final userId = await _authService.getUserId();
    if (userId != null) {
        try {
          final scheduleData = await _apiService.createSchedule(
            userId: userId,
            title: title,
            location: location,
            latitude: latitude,
            longitude: longitude,
            description: description,
            startTime: startTime.toUtc().toIso8601String(),
            endTime: endTime.toUtc().toIso8601String(),
          );
          await NotificationService().scheduleNotification(
            id: scheduleData['schedule']['id'],
            title: 'Pengingat: $title',
            body: 'Acara Anda di ${location ?? ''} akan dimulai dalam 15 menit!',
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
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              if (!_mapController.isCompleted) _mapController.complete(controller);
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onTap: (LatLng position) {
              setState(() {
                _selectedMarker = null; // Sembunyikan kartu info saat peta diketuk
                _markers.removeWhere((marker) => marker.markerId == _customMarkerId);
                final newMarker = Marker(
                  markerId: _customMarkerId,
                  position: position,
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                  onTap: () {
                    setState(() {
                       _selectedMarkerLocationName = 'Lokasi Pilihan';
                       _selectedMarkerLocationAddress = 'Koordinat: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
                       _selectedMarker = Marker(markerId: _customMarkerId, position: position);
                    });
                  },
                );
                _markers.add(newMarker);
              });
            },
          ),
          Positioned(
            top: 50.0,
            left: 15.0,
            right: 15.0,
            child: GestureDetector(
              onTap: _handleSearch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(30.0),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400]),
                    const SizedBox(width: 10),
                    Text('Cari tempat atau alamat...', style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: _selectedMarker == null ? 20.0 : 170.0, // Posisi naik jika kartu muncul
            right: 15.0,
            child: FloatingActionButton(
              heroTag: 'my_location_button',
              onPressed: _determinePosition,
              child: const Icon(Icons.my_location),
            ),
          ),
          if (_isLoadingPlaces)
            IgnorePointer(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _selectedMarker == null ? -200 : 20, // Muncul dari bawah
            left: 15,
            right: 15,
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_selectedMarkerLocationName, style: Theme.of(context).textTheme.titleLarge),
                    if (_selectedMarkerLocationAddress.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(_selectedMarkerLocationAddress, style: Theme.of(context).textTheme.bodySmall),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        _showAddScheduleDialog(
                          initialTitle: _selectedMarkerLocationName,
                          initialLocation: _selectedMarkerLocationAddress,
                          lat: _selectedMarker!.position.latitude,
                          lng: _selectedMarker!.position.longitude,
                        );
                      },
                      child: const Text('Tambahkan ke Jadwal'),
                    )
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

class PlaceSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final ApiService apiService;
  PlaceSearchDelegate(this.apiService);

  @override
  String get searchFieldLabel => 'Cari tempat...';

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  
  @override
  Widget? buildLeading(BuildContext context) => IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => buildSuggestions(context);
  
  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Ketik nama tempat atau alamat.'));
    }
    return FutureBuilder<List<dynamic>>(
      future: apiService.fetchPlaceAutocomplete(query),
      builder: (context, snapshot) {
        if (query.isEmpty) return const SizedBox.shrink();
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Tidak ada hasil ditemukan.'));

        final predictions = snapshot.data!;
        return ListView.builder(
          itemCount: predictions.length,
          itemBuilder: (context, index) {
            final prediction = predictions[index];
            return ListTile(
              leading: const Icon(Icons.location_on),
              title: Text(prediction['description']),
              onTap: () => close(context, prediction),
            );
          },
        );
      },
    );
  }
}
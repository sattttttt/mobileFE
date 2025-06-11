import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  final String _baseUrl =
      "https://travel-assistent-1071529598982.us-central1.run.app/api";

  // Ambil key dari environment, bukan hard-coded lagi
  final String _googleApiKey =
      dotenv.env['GOOGLE_API_KEY'] ?? 'API_KEY_NOT_FOUND';

  // --- FUNGSI USER & SCHEDULE ---
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/login'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal login: ${json.decode(response.body)['message']}');
    }
  }

   // --- FUNGSI BARU UNTUK UPDATE JADWAL ---
  Future<Map<String, dynamic>> updateSchedule({
    required int scheduleId,
    required String title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    required String startTime,
    required String endTime,
  }) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/schedules/$scheduleId'), // Menggunakan rute PUT
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'title': title,
        'description': description ?? '',
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'start_time': startTime,
        'end_time': endTime,
      }),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal memperbarui jadwal: ${response.body}');
    }
  }
  
  Future<Map<String, dynamic>> registerUser(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(
        'Gagal registrasi: ${json.decode(response.body)['message']}',
      );
    }
  }

  Future<List<dynamic>> getSchedulesForUser(int userId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/users/$userId/schedules'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>> createSchedule({
    required int userId,
    required String title,
    String? description,
    String? location,
    double? latitude,
    double? longitude,
    required String startTime,
    required String endTime,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/$userId/schedules'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'title': title,
        'description': description ?? '',
        'location': location ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'start_time': startTime,
        'end_time': endTime,
      }),
    );
    if (response.statusCode == 201) return json.decode(response.body);
    throw Exception('Gagal membuat jadwal: ${response.body}');
  }

  Future<void> deleteSchedule(int scheduleId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/schedules/$scheduleId'),
    );
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus jadwal');
    }
  }

  Future<List<dynamic>> fetchPlaceAutocomplete(String query) async {
    if (query.isEmpty) return [];
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleApiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') return data['predictions'] as List<dynamic>;
    }
    throw Exception('Gagal mencari tempat');
  }

  Future<List<dynamic>> getNearbyPlaces(double lat, double lng) async {
    const String type = 'tourist_attraction';
    const int radius = 50000;

    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=$radius&type=$type&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['results'] as List<dynamic>;
        } else {
          throw Exception(
            'Google Places API Error: ${data['error_message'] ?? data['status']}',
          );
        }
      } else {
        throw Exception('Gagal memuat data tempat wisata');
      }
    } catch (e) {
      print("Error di getNearbyPlaces: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=name,geometry/location&key=$_googleApiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') return data['result'] as Map<String, dynamic>;
    }
    throw Exception('Gagal mendapatkan detail tempat');
  }
}

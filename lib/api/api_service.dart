import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // URL untuk backend Anda
  final String _baseUrl = "https://travel-assistent-1071529598982.us-central1.run.app/api";
  
  // SANGAT PENTING: Masukkan Google Maps API Key Anda di sini
  final String _googleApiKey = "API KEY 2";

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

  Future<Map<String, dynamic>> registerUser(String username, String email, String password) async {
     final response = await http.post(
      Uri.parse('$_baseUrl/users'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal registrasi: ${json.decode(response.body)['message']}');
    }
  }

  Future<List<dynamic>> getSchedulesForUser(int userId) async {
    final response = await http.get(Uri.parse('$_baseUrl/users/$userId/schedules'));
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
    required String startTime,
    required String endTime,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/users/$userId/schedules'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'title': title,
        'description': description ?? '',
        'start_time': startTime,
        'end_time': endTime,
      }),
    );
     if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Gagal membuat jadwal: ${response.body}');
    }
  }

   Future<void> deleteSchedule(int scheduleId) async {
    final response = await http.delete(Uri.parse('$_baseUrl/schedules/$scheduleId'));
    if (response.statusCode != 200) {
      throw Exception('Gagal menghapus jadwal');
    }
  }

  // --- FUNGSI UNTUK GOOGLE PLACES API ---
  Future<List<dynamic>> getNearbyPlaces(double lat, double lng) async {
    const String type = 'tourist_attraction'; 
    const int radius = 50000; 

    final String url = 'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=$radius&type=$type&key=$_googleApiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['results'] as List<dynamic>;
        } else {
          throw Exception('Google Places API Error: ${data['error_message'] ?? data['status']}');
        }
      } else {
        throw Exception('Gagal memuat data tempat wisata');
      }
    } catch (e) {
      print("Error di getNearbyPlaces: $e");
      return []; 
    }
  }
}
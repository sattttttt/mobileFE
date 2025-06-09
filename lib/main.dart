import 'package:flutter/material.dart';
import 'package:acara_kita/pages/auth/login_page.dart';
import 'package:acara_kita/pages/main_wrapper.dart';
import 'package:acara_kita/services/auth_service.dart';
import 'package:acara_kita/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Pastikan semua binding siap sebelum menjalankan aplikasi
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi service notifikasi (termasuk meminta izin)
  await NotificationService().init();
  
  // --- MODIFIKASI ADA DI SINI ---
  // Menjadwalkan notifikasi harian saat aplikasi pertama kali dibuka
  await NotificationService().scheduleDailyReminderNotification();
  // ------------------------------

  // Inisialisasi data format untuk locale Indonesia
  await initializeDateFormatting('id_ID', null);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AcaraKita',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.deepPurple,
        hintColor: Colors.deepPurpleAccent,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F1F1F),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});
  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final AuthService _authService = AuthService();
  late Future<bool> _loginCheckFuture;

  @override
  void initState() {
    super.initState();
    _loginCheckFuture = _authService.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _loginCheckFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == true) {
          return const MainWrapper();
        }
        return const LoginPage();
      },
    );
  }
}
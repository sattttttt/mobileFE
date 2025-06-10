import 'package:flutter/material.dart';
import 'package:acara_kita/services/auth_service.dart';
import 'package:acara_kita/pages/auth/login_page.dart';
import 'package:acara_kita/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  void _loadUsername() async {
    final username = await _authService.getUsername();
    if (mounted) {
      setState(() {
        _username = username;
      });
    }
  }

  void _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _showTestNotification() {
    NotificationService().flutterLocalNotificationsPlugin.show(
          99,
          'Tes Notifikasi Instan',
          'Jika Anda bisa melihat ini, maka notifikasi berfungsi!',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'acara_kita_channel_id',
              'AcaraKita Channel',
              channelDescription: 'Channel untuk notifikasi pengingat acara',
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
  }

  void _showSaranKesanDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kirim Saran & Kesan'),
          content: const TextField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tulis masukan Anda di sini...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terima kasih atas masukan Anda!')));
                  Navigator.pop(context);
                },
                child: const Text('Kirim')),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  _username?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(fontSize: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _username ?? 'Memuat...',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Mahasiswa Teknologi & Pemrograman Mobile',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildProfileMenu(
            context,
            title: 'Saran dan Kesan',
            icon: Icons.feedback_outlined,
            onTap: _showSaranKesanDialog,
          ),
          _buildProfileMenu(
            context,
            title: 'Tes Notifikasi Instan',
            icon: Icons.notifications_active_outlined,
            iconColor: Colors.amber,
            onTap: _showTestNotification,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileMenu(BuildContext context,
      {required String title,
      required IconData icon,
      Color? iconColor,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Theme.of(context).hintColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
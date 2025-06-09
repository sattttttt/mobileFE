import 'package:flutter/material.dart';
import 'package:acara_kita/services/auth_service.dart';
import 'package:acara_kita/pages/auth/login_page.dart';

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

  void _showSaranKesanDialog() {
    showDialog(context: context, builder: (context) {
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
          TextButton(onPressed: ()=> Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(onPressed: (){
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terima kasih atas masukan Anda!')));
            Navigator.pop(context);
          }, child: const Text('Kirim')),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
            const SizedBox(height: 16),
            Text(
              _username ?? 'Memuat...',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Mahasiswa Teknologi & Pemrograman Mobile',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Divider(height: 40),
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: const Text('Saran dan Kesan'),
              onTap: _showSaranKesanDialog,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                minimumSize: const Size(double.infinity, 50)
              ),
            ),
          ],
        ),
      ),
    );
  }
}
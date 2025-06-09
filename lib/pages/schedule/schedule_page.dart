import 'package:flutter/material.dart';
import 'package:acara_kita/api/api_service.dart';
import 'package:acara_kita/models/schedule.dart';
import 'package:acara_kita/pages/compass/compass_page.dart';
import 'package:acara_kita/pages/schedule/schedule_detail_page.dart';
import 'package:acara_kita/services/auth_service.dart';
import 'package:acara_kita/services/notification_service.dart';
import 'package:intl/intl.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});
  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();
  Future<List<dynamic>>? _schedulesFuture;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  void _loadSchedules() async {
    final userId = await _authService.getUserId();
    if (userId != null && mounted) {
      setState(() {
        _schedulesFuture = _apiService.getSchedulesForUser(userId);
      });
    }
  }

  void _showAddScheduleDialog() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    final descController = TextEditingController();
    DateTime? startTime;
    DateTime? endTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Jadwal Manual'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Nama Acara', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Lokasi (Opsional)', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
                    const SizedBox(height: 20),
                    Text(startTime == null ? 'Pilih Waktu Mulai' : 'Mulai: ${DateFormat('dd MMM kk, HH:mm', 'id_ID').format(startTime!)}'),
                    ElevatedButton(
                      child: const Text('Pilih Waktu Mulai'),
                      onPressed: () async {
                        DateTime? picked = await _pickDateTime();
                        if (picked != null) setDialogState(() => startTime = picked);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(endTime == null ? 'Pilih Waktu Selesai' : 'Selesai: ${DateFormat('dd MMM kk, HH:mm', 'id_ID').format(endTime!)}'),
                    ElevatedButton(
                      child: const Text('Pilih Waktu Selesai'),
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

  void _saveSchedule({required String title, String? location, required String description, required DateTime? startTime, required DateTime? endTime}) async {
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
            location: location,
            description: description,
            latitude: null, 
            longitude: null,
            startTime: startTime.toUtc().toIso8601String(),
            endTime: endTime.toUtc().toIso8601String(),
          );
          await NotificationService().scheduleNotification(
            id: scheduleData['schedule']['id'],
            title: 'Pengingat: $title',
            body: 'Acara Anda akan dimulai dalam 15 menit!',
            scheduledTime: startTime,
          );
          if (mounted) Navigator.pop(context);
          _loadSchedules();
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jadwal Saya"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSchedules)],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadSchedules(),
        child: FutureBuilder<List<dynamic>>(
          future: _schedulesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Belum ada jadwal. Tekan tombol + untuk menambah.'));
            }

            final schedules = snapshot.data!.reversed.toList();
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = Schedule.fromJson(schedules[index]);
                final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(schedule.startTime);
                final formattedStartTime = DateFormat('HH:mm').format(schedule.startTime);
                final formattedEndTime = DateFormat('HH:mm').format(schedule.endTime);

                return InkWell(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ScheduleDetailPage(schedule: schedule),
                    ));
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(DateFormat('dd').format(schedule.startTime))),
                      title: Text(schedule.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (schedule.location != null && schedule.location!.isNotEmpty)
                            Text(schedule.location!, style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(formattedDate),
                          Text('Waktu: $formattedStartTime - $formattedEndTime WIB'),
                        ],
                      ),
                      isThreeLine: schedule.location != null && schedule.location!.isNotEmpty,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (schedule.latitude != null && schedule.longitude != null)
                            IconButton(
                              icon: Icon(Icons.explore_outlined, color: Theme.of(context).hintColor),
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (context) => CompassPage(
                                    destinationLat: schedule.latitude!,
                                    destinationLng: schedule.longitude!,
                                    destinationName: schedule.title,
                                  )
                                ));
                              },
                              tooltip: 'Arahkan Kompas',
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () async {
                              try {
                                await _apiService.deleteSchedule(schedule.id);
                                if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal dihapus!')));
                                _loadSchedules();
                              } catch (e) {
                                if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScheduleDialog(),
        tooltip: 'Tambah Jadwal Manual',
        child: const Icon(Icons.add),
      ),
    );
  }
}
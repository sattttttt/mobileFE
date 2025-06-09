import 'package:flutter/material.dart';
import 'package:acara_kita/api/api_service.dart';
import 'package:acara_kita/models/schedule.dart';
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

  void _showAddScheduleDialog({String initialTitle = ''}) {
    final titleController = TextEditingController(text: initialTitle);
    final descController = TextEditingController();
    DateTime? _startTime;
    DateTime? _endTime;

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
                    TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                            labelText: 'Nama Acara/Tempat',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                            labelText: 'Deskripsi',
                            border: OutlineInputBorder())),
                    const SizedBox(height: 20),
                    Text(
                      _startTime == null
                          ? 'Waktu Mulai Belum Dipilih'
                          : 'Mulai: ${DateFormat('dd MMM kk, HH:mm', 'id_ID').format(_startTime!)}',
                      textAlign: TextAlign.center,
                    ),
                    ElevatedButton(
                      child: const Text('Pilih Waktu Mulai'),
                      onPressed: () async {
                        DateTime? picked = await _pickDateTime();
                        if (picked != null) {
                          setDialogState(() => _startTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _endTime == null
                          ? 'Waktu Selesai Belum Dipilih'
                          : 'Selesai: ${DateFormat('dd MMM kk, HH:mm', 'id_ID').format(_endTime!)}',
                      textAlign: TextAlign.center,
                    ),
                    ElevatedButton(
                      child: const Text('Pilih Waktu Selesai'),
                      onPressed: () async {
                        DateTime? picked = await _pickDateTime();
                        if (picked != null) {
                          setDialogState(() => _endTime = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () => _saveSchedule(
                    title: titleController.text,
                    description: descController.text,
                    startTime: _startTime,
                    endTime: _endTime,
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
    final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2030));
    if (date == null) return null;

    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _saveSchedule({
    required String title,
    required String description,
    required DateTime? startTime,
    required DateTime? endTime,
  }) async {
    if (title.isEmpty || startTime == null || endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap lengkapi semua field!')));
      return;
    }

    if (endTime.isBefore(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Waktu selesai tidak boleh sebelum waktu mulai!')));
      return;
    }

    final userId = await _authService.getUserId();
    if (userId != null) {
      try {
        final scheduleData = await _apiService.createSchedule(
          userId: userId,
          title: title,
          description: description,
          // PERBAIKAN ZONA WAKTU
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
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jadwal Saya"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSchedules,
          ),
        ],
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
              return const Center(
                  child: Text('Belum ada jadwal. Tekan tombol + untuk menambah.'));
            }

            final schedules = snapshot.data!;
            return ListView.builder(
              itemCount: schedules.length,
              itemBuilder: (context, index) {
                final schedule = Schedule.fromJson(schedules[index]);
                final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(schedule.startTime);
                final formattedStartTime = DateFormat('HH:mm').format(schedule.startTime);
                final formattedEndTime = DateFormat('HH:mm').format(schedule.endTime);

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleDetailPage(schedule: schedule),
                      ),
                    );
                  },
                  child: Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(DateFormat('dd').format(schedule.startTime)),
                      ),
                      title: Text(schedule.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(formattedDate),
                          Text('Mulai: $formattedStartTime - Selesai: $formattedEndTime WIB'),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          try {
                            await _apiService.deleteSchedule(schedule.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Jadwal dihapus!')));
                            }
                            _loadSchedules();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Gagal hapus: $e')));
                            }
                          }
                        },
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
        tooltip: 'Tambah Jadwal',
        child: const Icon(Icons.add),
      ),
    );
  }
}
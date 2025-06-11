import 'package:flutter/material.dart';
import 'package:acara_kita/models/schedule.dart';
import 'package:acara_kita/api/api_service.dart';
import 'package:intl/intl.dart';

class ScheduleDetailPage extends StatefulWidget {
  final Schedule schedule;

  const ScheduleDetailPage({super.key, required this.schedule});

  @override
  State<ScheduleDetailPage> createState() => _ScheduleDetailPageState();
}

class _ScheduleDetailPageState extends State<ScheduleDetailPage> {
  late Schedule _currentSchedule;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _currentSchedule = widget.schedule;
  }

  void _showEditScheduleDialog() {
    // Isi controller dengan data jadwal yang ada saat ini
    final titleController = TextEditingController(text: _currentSchedule.title);
    final locationController = TextEditingController(text: _currentSchedule.location);
    final descController = TextEditingController(text: _currentSchedule.description);
    DateTime startTime = _currentSchedule.startTime;
    DateTime endTime = _currentSchedule.endTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Jadwal'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Nama Acara', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Lokasi', border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder())),
                    const SizedBox(height: 20),
                    Text('Mulai: ${DateFormat('dd MMM kk, HH:mm', 'id_ID').format(startTime)}'),
                    ElevatedButton(
                      child: const Text('Ubah Waktu Mulai'),
                      onPressed: () async {
                        DateTime? picked = await _pickDateTime(startTime);
                        if (picked != null) setDialogState(() => startTime = picked);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text('Selesai: ${DateFormat('dd MMM kk, HH:mm', 'id_ID').format(endTime)}'),
                    ElevatedButton(
                      child: const Text('Ubah Waktu Selesai'),
                      onPressed: () async {
                        DateTime? picked = await _pickDateTime(endTime);
                        if (picked != null) setDialogState(() => endTime = picked);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () => _updateSchedule(
                    title: titleController.text,
                    location: locationController.text,
                    description: descController.text,
                    startTime: startTime,
                    endTime: endTime,
                  ),
                  child: const Text('Simpan Perubahan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _pickDateTime(DateTime initialDate) async {
    final date = await showDatePicker(context: context, initialDate: initialDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (date == null) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initialDate));
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  void _updateSchedule({required String title, String? location, required String description, required DateTime startTime, required DateTime endTime}) async {
    if (endTime.isBefore(startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Waktu selesai tidak boleh sebelum waktu mulai!')));
      return;
    }
    
    try {
      final result = await _apiService.updateSchedule(
        scheduleId: _currentSchedule.id,
        title: title,
        location: location,
        description: description,
        latitude: _currentSchedule.latitude, // Lat/Lng tidak diubah di sini
        longitude: _currentSchedule.longitude,
        startTime: startTime.toUtc().toIso8601String(),
        endTime: endTime.toUtc().toIso8601String(),
      );
      
      if (mounted) {
        setState(() {
          _currentSchedule = Schedule.fromJson(result['schedule']);
        });
        Navigator.pop(context); // Tutup dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jadwal berhasil diperbarui!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_currentSchedule.startTime);
    final formattedStartTime = DateFormat('HH:mm').format(_currentSchedule.startTime);
    final formattedEndTime = DateFormat('HH:mm').format(_currentSchedule.endTime);

    return Scaffold(
      appBar: AppBar(
        title: Text("Detail Jadwal"),
        // Tombol Edit di AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _showEditScheduleDialog,
            tooltip: 'Edit Jadwal',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailCard(context, icon: Icons.event_note, title: 'Acara', content: _currentSchedule.title),
            if (_currentSchedule.location != null && _currentSchedule.location!.isNotEmpty)
              _buildDetailCard(context, icon: Icons.location_on_outlined, title: 'Lokasi', content: _currentSchedule.location!),
            if (_currentSchedule.description != null && _currentSchedule.description!.isNotEmpty)
              _buildDetailCard(context, icon: Icons.description_outlined, title: 'Deskripsi', content: _currentSchedule.description!),
            _buildDetailCard(context, icon: Icons.calendar_month, title: 'Tanggal', content: formattedDate),
            _buildDetailCard(context, icon: Icons.access_time_filled, title: 'Waktu', content: 'Mulai: $formattedStartTime WIB\nSelesai: $formattedEndTime WIB'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, {required IconData icon, required String title, required String content}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: Theme.of(context).hintColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey[400])),
                  const SizedBox(height: 4),
                  Text(content, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
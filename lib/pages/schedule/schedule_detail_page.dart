import 'package:flutter/material.dart';
import 'package:acara_kita/models/schedule.dart';
import 'package:intl/intl.dart';

class ScheduleDetailPage extends StatelessWidget {
  final Schedule schedule;

  const ScheduleDetailPage({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(schedule.startTime);
    final formattedStartTime = DateFormat('HH:mm').format(schedule.startTime);
    final formattedEndTime = DateFormat('HH:mm').format(schedule.endTime);

    return Scaffold(
      appBar: AppBar(
        title: Text("Detail Jadwal"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailCard(
              context,
              icon: Icons.event_note,
              title: 'Acara',
              content: schedule.title,
            ),
             if (schedule.location != null && schedule.location!.isNotEmpty)
              _buildDetailCard(
                context,
                icon: Icons.location_on_outlined,
                title: 'Lokasi',
                content: schedule.location!,
              ),
            if (schedule.description != null && schedule.description!.isNotEmpty)
              _buildDetailCard(
                context,
                icon: Icons.description_outlined,
                title: 'Deskripsi',
                content: schedule.description!,
              ),
            _buildDetailCard(
              context,
              icon: Icons.calendar_month,
              title: 'Tanggal',
              content: formattedDate,
            ),
            _buildDetailCard(
              context,
              icon: Icons.access_time_filled,
              title: 'Waktu',
              content: 'Mulai: $formattedStartTime WIB\nSelesai: $formattedEndTime WIB',
            ),
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
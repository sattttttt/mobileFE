import 'package:acara_kita/models/schedule.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ScheduleDetailPage extends StatelessWidget {
  final Schedule schedule;

  const ScheduleDetailPage({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(schedule.startTime);
    final formattedTime = DateFormat('HH:mm').format(schedule.startTime);

    return Scaffold(
      appBar: AppBar(title: Text(schedule.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(schedule.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                Text(formattedDate),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.access_time, size: 16),
                const SizedBox(width: 8),
                Text("Pukul: $formattedTime WIB"),
              ],
            ),
            const Divider(height: 32),
            Text("Deskripsi", style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(schedule.description ?? 'Tidak ada deskripsi.'),
          ],
        ),
      ),
    );
  }
}
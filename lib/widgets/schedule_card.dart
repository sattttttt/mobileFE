import 'package:flutter/material.dart';
import 'package:acara_kita/models/schedule.dart';
import 'package:intl/intl.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM', 'id_ID').format(schedule.startTime);
    final formattedTime = DateFormat('HH:mm').format(schedule.startTime);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          child: Text(formattedDate),
        ),
        title: Text(schedule.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Pukul $formattedTime - ${schedule.description ?? ''}"),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
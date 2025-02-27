import 'package:flutter/material.dart';
import 'package:laundry_app/components/my_calendar.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar"),
        centerTitle: true,
      ),
      body: const MyCalendar(),
    );
  }
}

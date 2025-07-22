import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:uuid/uuid.dart';

class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({super.key});

  @override
  State<BookingCalendarPage> createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  late String userId;
  String? linkedUuid;
  late CalendarController _controller;

  Future<void> _loadLinkedUuid() async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists && doc.data()!.containsKey('linked_uuid')) {
      linkedUuid = doc['linked_uuid'];
      setState(() {});
    } else {
      // Optionally log or handle the missing linked_uuid
      print("⚠️ linked_uuid missing for user $userId");
      // You may choose to show an error or fallback behavior here
    }
  }

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    _controller = CalendarController();
    _loadLinkedUuid();
  }

  Stream<List<Appointment>> _getAppointments() {
    if (linkedUuid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('linked_uuid', isEqualTo: linkedUuid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return Appointment(
          id: doc.id,
          startTime: (data['start'] as Timestamp).toDate(),
          endTime: (data['end'] as Timestamp).toDate(),
          subject: 'Washer ${data['machine']}\nUser: ${data['email'] ?? ''}',
          color: data['user_id'] == userId ? Colors.green : Colors.grey,
          resourceIds: [data['machine'].toString()],
          notes: data['user_id'],
        );
      }).toList();
    });
  }

  void _bookSlot(CalendarTapDetails details) async {
    if (linkedUuid == null) return;

    final DateTime start = details.date!;
    final DateTime end = start.add(const Duration(hours: 1));

    final existing = await FirebaseFirestore.instance
        .collection('bookings')
        .where('linked_uuid', isEqualTo: linkedUuid)
        .where('start', isEqualTo: Timestamp.fromDate(start))
        .get();

    if (existing.docs.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("All 3 machines are booked at this time.")));
      return;
    }

    final machine = [1, 2, 3].firstWhere(
      (id) => !existing.docs.any((doc) => doc['machine'] == id),
      orElse: () => 0,
    );

    if (machine == 0) return;

    await FirebaseFirestore.instance.collection('bookings').add({
      'user_id': userId,
      'email': FirebaseAuth.instance.currentUser!.email,
      'linked_uuid': linkedUuid,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
      'machine': machine,
    });
  }

  void _deleteBooking(String id) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    if (linkedUuid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Laundry Booking Calendar')),
      body: StreamBuilder<List<Appointment>>(
        stream: _getAppointments(),
        builder: (context, snapshot) {
          return SfCalendar(
            controller: _controller,
            view: CalendarView.week,
            cellBorderColor: Colors.red,
            dataSource: AppointmentDataSource(snapshot.data ?? []),
            monthViewSettings: MonthViewSettings(
                appointmentDisplayMode:
                    MonthAppointmentDisplayMode.appointment),
            onTap: (details) {
              if (details.appointments != null &&
                  details.appointments!.isNotEmpty &&
                  (details.appointments!.first.notes == userId)) {
                _deleteBooking(details.appointments!.first.id);
              } else if (details.targetElement ==
                  CalendarElement.calendarCell) {
                _bookSlot(details);
              }
            },
          );
        },
      ),
    );
  }
}

class AppointmentDataSource extends CalendarDataSource {
  AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}

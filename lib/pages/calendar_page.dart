import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ─── Slot definitions ─────────────────────────────────────────────────────────

enum _Slot { morning, afternoon }

extension _SlotExt on _Slot {
  String get label => this == _Slot.morning ? 'Morning' : 'Afternoon';
  String get timeRange =>
      this == _Slot.morning ? '08:00 – 12:00' : '12:00 – 22:00';
  int get startHour => this == _Slot.morning ? 8 : 12;
  int get endHour => this == _Slot.morning ? 12 : 22;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class BookingCalendarPage extends StatefulWidget {
  const BookingCalendarPage({super.key});

  @override
  State<BookingCalendarPage> createState() => _BookingCalendarPageState();
}

class _BookingCalendarPageState extends State<BookingCalendarPage> {
  DateTime _selectedDate = _today();
  final String _userId = FirebaseAuth.instance.currentUser!.uid;
  String? _linkedUuid;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _loadLinkedUuid();
  }

  Future<void> _loadLinkedUuid() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .get();
    if (mounted &&
        doc.exists &&
        (doc.data()?.containsKey('linked_uuid') ?? false)) {
      setState(() => _linkedUuid = doc['linked_uuid']);
    }
  }

  // Requires a composite Firestore index on (linked_uuid, date).
  Stream<List<Map<String, dynamic>>> _bookingsStream() {
    if (_linkedUuid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('linked_uuid', isEqualTo: _linkedUuid)
        .where('date', isEqualTo: _dateKey(_selectedDate))
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Stream<Map<int, String>> _machinesStream() {
    if (_linkedUuid == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('buildings')
        .doc(_linkedUuid)
        .snapshots()
        .map((s) {
      final raw =
          Map<String, dynamic>.from(s.data()?['machines'] as Map? ?? {});
      return raw.map((k, v) => MapEntry(int.parse(k), v as String));
    });
  }

  Future<void> _book(int machine, _Slot slot) async {
    if (_linkedUuid == null) return;
    final d = _selectedDate;
    await FirebaseFirestore.instance.collection('bookings').add({
      'user_id': _userId,
      'email': FirebaseAuth.instance.currentUser!.email,
      'linked_uuid': _linkedUuid,
      'date': _dateKey(d),
      'slot': slot.name,
      'machine': machine,
      'start': Timestamp.fromDate(
          DateTime(d.year, d.month, d.day, slot.startHour)),
      'end': Timestamp.fromDate(
          DateTime(d.year, d.month, d.day, slot.endHour)),
    });
  }

  Future<void> _cancel(String id) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).delete();
  }

  bool _isSlotPast(_Slot slot) {
    final today = _today();
    if (_selectedDate.isBefore(today)) return true;
    if (_selectedDate.isAfter(today)) return false;
    final slotEnd = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, slot.endHour);
    return DateTime.now().isAfter(slotEnd);
  }

  String _formatDate(DateTime d) {
    const wd = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const mo = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final today = _today();
    if (d == today) return 'Today, ${d.day} ${mo[d.month - 1]}';
    if (d == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${d.day} ${mo[d.month - 1]}';
    }
    return '${wd[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    if (_linkedUuid == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isToday = _selectedDate == _today();

    return Scaffold(
      body: StreamBuilder<Map<int, String>>(
        stream: _machinesStream(),
        builder: (context, machinesSnap) {
          final machineStatuses = machinesSnap.data ?? {};

          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _bookingsStream(),
            builder: (context, snapshot) {
              final bookings = snapshot.data ?? [];

              final myTodayBookings = isToday
                  ? (bookings
                        .where((b) => b['user_id'] == _userId)
                        .toList()
                      ..sort((a, b) => (a['start'] as Timestamp)
                          .toDate()
                          .compareTo((b['start'] as Timestamp).toDate())))
                  : <Map<String, dynamic>>[];

              return CustomScrollView(
                slivers: [
                  const SliverAppBar(
                    floating: true,
                    automaticallyImplyLeading: false,
                    title: Text('Laundry'),
                    centerTitle: false,
                  ),

                  // Date navigation
                  SliverToBoxAdapter(
                    child: _DateNav(
                      label: _formatDate(_selectedDate),
                      isToday: isToday,
                      onPrev: () => setState(() => _selectedDate =
                          _selectedDate.subtract(const Duration(days: 1))),
                      onNext: () => setState(() => _selectedDate =
                          _selectedDate.add(const Duration(days: 1))),
                      onToday: () =>
                          setState(() => _selectedDate = _today()),
                    ),
                  ),

                  // Hero banner — only shown on today when user has a booking
                  if (myTodayBookings.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: _BookingBanner(booking: myTodayBookings.first),
                      ),
                    ),

                  // Machine cards
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final machine = i + 1;
                          final mb = bookings
                              .where((b) => b['machine'] == machine)
                              .toList();
                          final inMaintenance =
                              machineStatuses[machine] == 'maintenance';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MachineCard(
                              machine: machine,
                              bookings: mb,
                              userId: _userId,
                              isSlotPast: _isSlotPast,
                              onBook: (slot) => _book(machine, slot),
                              onCancel: _cancel,
                              inMaintenance: inMaintenance,
                            ),
                          );
                        },
                        childCount: 3,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Date navigation bar ──────────────────────────────────────────────────────

class _DateNav extends StatelessWidget {
  final String label;
  final bool isToday;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  const _DateNav({
    required this.label,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Expanded(
            child: Center(
              child: Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          if (!isToday)
            TextButton(onPressed: onToday, child: const Text('Today'))
          else
            const SizedBox(width: 64),
          IconButton(
              icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

// ─── Hero banner ──────────────────────────────────────────────────────────────

class _BookingBanner extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingBanner({required this.booking});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final slot = booking['slot'] as String;
    final machine = booking['machine'] as int;
    final timeRange = slot == 'morning' ? '08:00 – 12:00' : '12:00 – 22:00';
    final slotLabel = '${slot[0].toUpperCase()}${slot.substring(1)}';

    return Card(
      elevation: 0,
      color: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.local_laundry_service,
                color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your booking today',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70)),
                Text('Machine $machine · $slotLabel',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text(timeRange,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Machine card ─────────────────────────────────────────────────────────────

class _MachineCard extends StatelessWidget {
  final int machine;
  final List<Map<String, dynamic>> bookings;
  final String userId;
  final bool Function(_Slot) isSlotPast;
  final void Function(_Slot) onBook;
  final void Function(String) onCancel;
  final bool inMaintenance;

  const _MachineCard({
    required this.machine,
    required this.bookings,
    required this.userId,
    required this.isSlotPast,
    required this.onBook,
    required this.onCancel,
    required this.inMaintenance,
  });

  Map<String, dynamic>? _bookingFor(_Slot slot) =>
      bookings.where((b) => b['slot'] == slot.name).firstOrNull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.local_laundry_service,
                    color: inMaintenance
                        ? Colors.orange
                        : theme.colorScheme.primary,
                    size: 20),
                const SizedBox(width: 8),
                Text('Machine $machine',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                if (inMaintenance) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 12, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text('Maintenance',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          if (inMaintenance)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(Icons.build_outlined,
                      size: 18, color: Colors.orange.shade400),
                  const SizedBox(width: 10),
                  Text(
                    'This machine is temporarily out of service.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.orange.shade700),
                  ),
                ],
              ),
            )
          else ...[
            _SlotRow(
              slot: _Slot.morning,
              booking: _bookingFor(_Slot.morning),
              userId: userId,
              isPast: isSlotPast(_Slot.morning),
              onBook: () => onBook(_Slot.morning),
              onCancel: onCancel,
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _SlotRow(
              slot: _Slot.afternoon,
              booking: _bookingFor(_Slot.afternoon),
              userId: userId,
              isPast: isSlotPast(_Slot.afternoon),
              onBook: () => onBook(_Slot.afternoon),
              onCancel: onCancel,
            ),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

// ─── Slot row ─────────────────────────────────────────────────────────────────

class _SlotRow extends StatelessWidget {
  final _Slot slot;
  final Map<String, dynamic>? booking;
  final String userId;
  final bool isPast;
  final VoidCallback onBook;
  final void Function(String) onCancel;

  const _SlotRow({
    required this.slot,
    required this.booking,
    required this.userId,
    required this.isPast,
    required this.onBook,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMine = booking != null && booking!['user_id'] == userId;
    final isTaken = booking != null && !isMine;

    final (dotColor, statusText) = switch ((isMine, isTaken, isPast)) {
      (true, _, _) => (Colors.blue, 'Your booking'),
      (_, true, _) => (Colors.red, 'Taken'),
      (_, _, true) => (Colors.grey, 'Passed'),
      _ => (Colors.green, 'Available'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Label + time range
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(slot.label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w500)),
                Text(slot.timeRange,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey.shade600)),
              ],
            ),
          ),
          // Status indicator
          Row(
            children: [
              Icon(Icons.circle, color: dotColor, size: 8),
              const SizedBox(width: 4),
              Text(statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: dotColor, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(width: 12),
          // Action button — fixed width to keep layout stable
          SizedBox(
            width: 80,
            child: isMine
                ? FilledButton.tonal(
                    onPressed: () => onCancel(booking!['id']),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Cancel'),
                  )
                : (!isTaken && !isPast)
                    ? FilledButton(
                        onPressed: onBook,
                        style: FilledButton.styleFrom(
                            visualDensity: VisualDensity.compact),
                        child: const Text('Book'),
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

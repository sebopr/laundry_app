import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/services/notifications/notification_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
  String? _displayName;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

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
    if (!mounted) return;
    final data = doc.data();
    setState(() {
      _displayName = data?['displayName'] as String?;
      if (data?.containsKey('linked_uuid') ?? false) {
        _linkedUuid = data!['linked_uuid'];
      }
    });
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
      final data = s.data();
      if (data == null || data['machines'] is! Map) return <int, String>{};
      final raw = Map<String, dynamic>.from(data['machines'] as Map);
      final result = <int, String>{};
      for (final e in raw.entries) {
        final num = int.tryParse(e.key);
        if (num == null) continue;
        final v = e.value;
        result[num] = v is String
            ? v
            : (v is Map && v['status'] is String
                ? v['status'] as String
                : 'active');
      }
      return result;
    });
  }

  Future<void> _book(int machine, _Slot slot) async {
    if (_linkedUuid == null) return;
    final d = _selectedDate;
    final start = DateTime(d.year, d.month, d.day, slot.startHour);
    final end = DateTime(d.year, d.month, d.day, slot.endHour);
    final doc = await FirebaseFirestore.instance.collection('bookings').add({
      'user_id': _userId,
      'email': FirebaseAuth.instance.currentUser!.email,
      'linked_uuid': _linkedUuid,
      'date': _dateKey(d),
      'slot': slot.name,
      'machine': machine,
      'start': Timestamp.fromDate(start),
      'end': Timestamp.fromDate(end),
    });
    await NotificationService.instance.scheduleBookingReminders(
      bookingId: doc.id,
      machine: machine,
      slotLabel: slot.label,
      start: start,
      end: end,
    );
  }

  Future<void> _cancel(String id) async {
    await NotificationService.instance.cancelBookingReminders(id);
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

  void _showCalendar() {
    if (_linkedUuid == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CalendarSheet(
        linkedUuid: _linkedUuid!,
        selectedDate: _selectedDate,
        machinesStream: _machinesStream(),
        onDateSelected: (d) => setState(() => _selectedDate = d),
      ),
    );
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
                  SliverAppBar(
                    floating: true,
                    automaticallyImplyLeading: false,
                    titleSpacing: 16,
                    title: _GreetingHeader(
                      greeting: _greeting(),
                      name: _displayName,
                    ),
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
                      onTapDate: _showCalendar,
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

                  // Machine cards — list is driven by Firestore data.
                  // Fall back to [1, 2, 3] only while the stream hasn't emitted.
                  Builder(builder: (context) {
                    final machineNums = machineStatuses.isEmpty
                        ? [1, 2, 3]
                        : (machineStatuses.keys.toList()..sort());
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final machine = machineNums[i];
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
                          childCount: machineNums.length,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Greeting header ──────────────────────────────────────────────────────────

class _GreetingHeader extends StatelessWidget {
  final String greeting;
  final String? name;

  const _GreetingHeader({required this.greeting, this.name});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(LucideIcons.washingMachine,
              color: theme.colorScheme.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(greeting,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade500, fontSize: 11)),
            Text(
              (name != null && name!.isNotEmpty) ? name! : 'Lavaplan',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
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
  final VoidCallback onTapDate;

  const _DateNav({
    required this.label,
    required this.isToday,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
    required this.onTapDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
              icon: const Icon(LucideIcons.chevronLeft), onPressed: onPrev),
          Expanded(
            child: Center(
              child: InkWell(
                onTap: onTapDate,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Icon(LucideIcons.calendar,
                          size: 16,
                          color: theme.colorScheme.primary),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!isToday)
            TextButton(onPressed: onToday, child: const Text('Today'))
          else
            const SizedBox(width: 64),
          IconButton(
              icon: const Icon(LucideIcons.chevronRight), onPressed: onNext),
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

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF22C6C6), Color(0xFF0C7378)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF12A3A8).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    Colors.white,
                    Colors.white,
                    Colors.white.withValues(alpha: 0.28),
                  ],
                  stops: const [0, 0.7, 0.7],
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF12A3A8),
                ),
                child: const Icon(LucideIcons.washingMachine,
                    color: Colors.white, size: 20),
              ),
            ),
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

  (Color, String) get _status {
    if (inMaintenance) return (Colors.grey.shade400, 'Maintenance');
    if (bookings.isEmpty) return (const Color(0xFF34A853), 'Open');
    if (bookings.length >= _Slot.values.length) {
      return (const Color(0xFFE15B5B), 'Full');
    }
    return (const Color(0xFFE8963C), 'Partly booked');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final (statusColor, statusLabel) = _status;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? const Color(0xFF2B3542) : const Color(0xFFE7EEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: statusColor),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.secondary,
                    ),
                    child: Icon(LucideIcons.washingMachine,
                        color: theme.colorScheme.onSurface, size: 15),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Machine $machine',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(statusLabel,
                      style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w700)),
                ),
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
                  Icon(LucideIcons.wrench,
                      size: 18, color: Colors.grey.shade500),
                  const SizedBox(width: 10),
                  Text(
                    'This machine is temporarily out of service.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
              ),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 84),
                child: Text(statusText,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: dotColor, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: isMine
                ? FilledButton.tonal(
                    onPressed: () => onCancel(booking!['id']),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Cancel',
                        style: TextStyle(fontSize: 13)),
                  )
                : (!isTaken && !isPast)
                    ? FilledButton(
                        onPressed: onBook,
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(0, 32),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Book'),
                      )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ─── Calendar bottom sheet ────────────────────────────────────────────────────

class _CalendarSheet extends StatefulWidget {
  final String linkedUuid;
  final DateTime selectedDate;
  final Stream<Map<int, String>> machinesStream;
  final ValueChanged<DateTime> onDateSelected;

  const _CalendarSheet({
    required this.linkedUuid,
    required this.selectedDate,
    required this.machinesStream,
    required this.onDateSelected,
  });

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late DateTime _month;
  late DateTime _selected;
  // Single persistent stream — created once, reused across month navigations.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _bookingsStream;

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.selectedDate.year, widget.selectedDate.month);
    _selected = widget.selectedDate;
    _bookingsStream = FirebaseFirestore.instance
        .collection('bookings')
        .where('linked_uuid', isEqualTo: widget.linkedUuid)
        .snapshots();
  }

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _nextMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));

  static Color? _dotColor(int count, int activeMachineCount) {
    if (count == 0) return Colors.green;
    if (activeMachineCount > 0 && count >= activeMachineCount * 2) {
      return Colors.red.shade400;
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = _today();
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final startPad = _month.weekday - 1; // Mon=0

    return StreamBuilder<Map<int, String>>(
      stream: widget.machinesStream,
      builder: (context, machinesSnap) {
        final activeMachineCount = (machinesSnap.data ?? {})
            .values
            .where((v) => v == 'active')
            .length;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _bookingsStream,
          builder: (context, bookingsSnap) {
            // Build per-day booking counts for the visible month.
            final start = _dateKey(_month);
            final end = _dateKey(DateTime(_month.year, _month.month + 1, 0));
            final counts = <String, int>{};

            // Also collect every unique machine number ever booked in this
            // building — used as fallback when the machines stream is empty.
            final bookedMachineNums = <int>{};

            for (final doc in bookingsSnap.data?.docs ?? []) {
              final data = doc.data();
              final date = data['date'] as String? ?? '';
              if (date.compareTo(start) >= 0 && date.compareTo(end) <= 0) {
                counts[date] = (counts[date] ?? 0) + 1;
              }
              final m = data['machine'];
              if (m is int) bookedMachineNums.add(m);
            }

            // If the machines stream hasn't emitted (e.g. permission error or
            // wrong data format), infer the count from bookings instead.
            final effectiveMachineCount = activeMachineCount > 0
                ? activeMachineCount
                : bookedMachineNums.length;

            final loading = !bookingsSnap.hasData;

            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 40, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Month navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.chevronLeft),
                            onPressed: _prevMonth,
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '${_monthNames[_month.month - 1]} ${_month.year}',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.chevronRight),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                    ),

                    // Day-of-week labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: _dayLabels
                            .map((d) => Expanded(
                                  child: Center(
                                    child: Text(d,
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w600,
                                        )),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Day grid
                    loading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(),
                          )
                        : Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: startPad + daysInMonth,
                              itemBuilder: (context, i) {
                                if (i < startPad) {
                                  return const SizedBox.shrink();
                                }
                                final day = i - startPad + 1;
                                final date = DateTime(
                                    _month.year, _month.month, day);
                                final isSelected = date == _selected;
                                final isToday = date == today;
                                final isPast = date.isBefore(today);
                                final dot = isPast
                                    ? null
                                    : _dotColor(
                                        counts[_dateKey(date)] ?? 0,
                                        effectiveMachineCount,
                                      );

                                return GestureDetector(
                                  onTap: isPast
                                      ? null
                                      : () {
                                          widget.onDateSelected(date);
                                          Navigator.pop(context);
                                        },
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 34,
                                        height: 34,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : null,
                                          border: isToday && !isSelected
                                              ? Border.all(
                                                  color: theme
                                                      .colorScheme.primary,
                                                  width: 1.5)
                                              : null,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$day',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: isSelected
                                                  ? Colors.white
                                                  : isPast
                                                      ? Colors.grey.shade400
                                                      : null,
                                              fontWeight:
                                                  isSelected || isToday
                                                      ? FontWeight.bold
                                                      : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (dot != null)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin:
                                              const EdgeInsets.only(top: 2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: dot,
                                          ),
                                        )
                                      else
                                        const SizedBox(height: 8),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                    const SizedBox(height: 12),

                    // Legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _LegendDot(
                            color: Colors.green, label: 'Available'),
                        const SizedBox(width: 16),
                        const _LegendDot(
                            color: Colors.orange, label: 'Partly booked'),
                        const SizedBox(width: 16),
                        _LegendDot(
                            color: Colors.red.shade400, label: 'Full'),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: Colors.grey.shade600)),
      ],
    );
  }
}

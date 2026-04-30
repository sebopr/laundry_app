import 'package:flutter/material.dart';

void main() => runApp(const BookingMockupApp());

class BookingMockupApp extends StatelessWidget {
  const BookingMockupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          surface: const Color(0xFFF5F5F5),
          primary: const Color(0xFF5C6BC0),
          secondary: Colors.white,
          inversePrimary: Colors.grey.shade900,
        ),
      ),
      home: const OptionsShell(),
    );
  }
}

// ─── Top-level shell to switch between options ────────────────────────────────

class OptionsShell extends StatefulWidget {
  const OptionsShell({super.key});

  @override
  State<OptionsShell> createState() => _OptionsShellState();
}

class _OptionsShellState extends State<OptionsShell> {
  int _option = 0;
  final _controller = PageController();

  void _go(int i) {
    setState(() => _option = i);
    _controller.animateToPage(i,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // Option switcher bar
          SafeArea(
            bottom: false,
            child: Container(
              color: theme.colorScheme.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  _OptionChip(
                      label: 'A – Dashboard',
                      selected: _option == 0,
                      onTap: () => _go(0)),
                  const SizedBox(width: 8),
                  _OptionChip(
                      label: 'B – Dashboard + Cal',
                      selected: _option == 1,
                      onTap: () => _go(1)),
                  const SizedBox(width: 8),
                  _OptionChip(
                      label: 'C – Stacked',
                      selected: _option == 2,
                      onTap: () => _go(2)),
                ],
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _option = i),
              children: const [
                OptionA(),
                OptionB(),
                OptionC(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _OptionChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? const Color(0xFF5C6BC0)
                : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Shared mock data & widgets ───────────────────────────────────────────────

enum MachineStatus { free, mine, taken }

const _mockMachines = [
  (1, MachineStatus.free, null),
  (2, MachineStatus.mine, '14:30'),
  (3, MachineStatus.taken, '15:00'),
];

const _mockUpcoming = [
  (2, 'Today', '13:30 – 14:30'),
  (1, 'Tomorrow', '09:00 – 10:00'),
];

class _NextBookingCard extends StatelessWidget {
  const _NextBookingCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.local_laundry_service,
                color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next booking',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70)),
                Text('Machine 2 — Today 13:30',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                Text('1 hour slot',
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

class _MachineRow extends StatelessWidget {
  final int number;
  final MachineStatus status;
  final String? endsAt;
  const _MachineRow(
      {required this.number, required this.status, this.endsAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bgColor, dotColor, label, btnLabel) = switch (status) {
      MachineStatus.free => (
          Colors.green.shade50,
          Colors.green,
          'Available',
          'Book'
        ),
      MachineStatus.mine => (
          Colors.blue.shade50,
          Colors.blue,
          'Your booking',
          'Cancel'
        ),
      MachineStatus.taken => (
          Colors.red.shade50,
          Colors.red,
          'In use',
          null
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.local_laundry_service, color: dotColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Machine $number',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  endsAt != null ? '$label · until $endsAt' : label,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          if (btnLabel != null)
            FilledButton.tonal(
              onPressed: () {},
              style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact),
              child: Text(btnLabel),
            ),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final int machine;
  final String date;
  final String time;
  const _UpcomingTile(
      {required this.machine, required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.indigo.shade50,
        child: const Icon(Icons.local_laundry_service_outlined,
            color: Color(0xFF5C6BC0)),
      ),
      title: Text('Machine $machine'),
      subtitle: Text(time),
      trailing: Text(date,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey)),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 6),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Mock calendar widget (used in B and C) ───────────────────────────────────

class _MockWeekCalendar extends StatelessWidget {
  const _MockWeekCalendar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hours = ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
        '14:00', '15:00', '16:00', '17:00'];

    // Fake bookings: (dayIndex, hourIndex, isMine)
    const bookings = [
      (1, 2, false), // Tue 10:00 - taken
      (1, 5, true),  // Tue 13:00 - mine
      (3, 1, false), // Thu 09:00 - taken
      (4, 4, false), // Fri 12:00 - taken
      (6, 3, true),  // Sun 11:00 - mine
    ];

    return Container(
      color: theme.colorScheme.secondary,
      child: Column(
        children: [
          // Day headers
          Row(
            children: [
              const SizedBox(width: 44),
              ...days.map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: d == 'Tue'
                                  ? theme.colorScheme.primary
                                  : null)),
                    ),
                  )),
            ],
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: hours.asMap().entries.map((hourEntry) {
                  final hi = hourEntry.key;
                  final hour = hourEntry.value;
                  return SizedBox(
                    height: 44,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 44,
                          child: Center(
                            child: Text(hour,
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.grey.shade500)),
                          ),
                        ),
                        ...List.generate(7, (di) {
                          final booking = bookings.where(
                              (b) => b.$1 == di && b.$2 == hi).firstOrNull;
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: booking == null
                                    ? null
                                    : booking.$3
                                        ? Colors.green.shade300
                                        : Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.grey.shade200, width: 0.5),
                              ),
                              child: booking != null
                                  ? Center(
                                      child: Text(
                                        booking.$3 ? 'Me' : 'W${booking.$1 + 1}',
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Option A: Full dashboard replacement ────────────────────────────────────

class OptionA extends StatelessWidget {
  const OptionA({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          automaticallyImplyLeading: false,
          title: const Text('Laundry'),
          centerTitle: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _NextBookingCard(),
              const _SectionTitle('Machines'),
              ..._mockMachines.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _MachineRow(
                        number: m.$1, status: m.$2, endsAt: m.$3),
                  )),
              const _SectionTitle('Upcoming bookings'),
              ..._mockUpcoming.map((u) =>
                  _UpcomingTile(machine: u.$1, date: u.$2, time: u.$3)),
              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }
}

// ─── Option B: Dashboard + calendar toggle ────────────────────────────────────

class OptionB extends StatefulWidget {
  const OptionB({super.key});

  @override
  State<OptionB> createState() => _OptionBState();
}

class _OptionBState extends State<OptionB> {
  bool _showCalendar = false;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          automaticallyImplyLeading: false,
          title: const Text('Laundry'),
          centerTitle: false,
          actions: [
            IconButton(
              icon: Icon(
                _showCalendar
                    ? Icons.dashboard_outlined
                    : Icons.calendar_month_outlined,
              ),
              tooltip: _showCalendar ? 'Dashboard' : 'Calendar',
              onPressed: () =>
                  setState(() => _showCalendar = !_showCalendar),
            ),
          ],
        ),
        if (_showCalendar)
          SliverFillRemaining(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.green, size: 12),
                      const SizedBox(width: 6),
                      const Text('My booking', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 16),
                      Icon(Icons.circle, color: Colors.grey.shade400, size: 12),
                      const SizedBox(width: 6),
                      const Text('Other', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const Expanded(child: _MockWeekCalendar()),
              ],
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _NextBookingCard(),
                const _SectionTitle('Machines'),
                ..._mockMachines.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _MachineRow(
                          number: m.$1, status: m.$2, endsAt: m.$3),
                    )),
                const _SectionTitle('Upcoming bookings'),
                ..._mockUpcoming.map((u) =>
                    _UpcomingTile(machine: u.$1, date: u.$2, time: u.$3)),
                const SizedBox(height: 16),
              ]),
            ),
          ),
      ],
    );
  }
}

// ─── Option C: Stacked dashboard + calendar ───────────────────────────────────

class OptionC extends StatelessWidget {
  const OptionC({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          automaticallyImplyLeading: false,
          title: const Text('Laundry'),
          centerTitle: false,
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const _NextBookingCard(),
              const _SectionTitle('Machines'),
              ..._mockMachines.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child:
                        _MachineRow(number: m.$1, status: m.$2, endsAt: m.$3),
                  )),
              const _SectionTitle('Week view'),
            ]),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: SizedBox(
              height: 380,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 12),
                        const SizedBox(width: 6),
                        const Text('My booking',
                            style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 16),
                        Icon(Icons.circle,
                            color: Colors.grey.shade400, size: 12),
                        const SizedBox(width: 6),
                        const Text('Other', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const Expanded(child: _MockWeekCalendar()),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

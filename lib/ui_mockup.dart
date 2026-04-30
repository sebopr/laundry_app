import 'package:flutter/material.dart';

void main() {
  runApp(const MockupApp());
}

class MockupApp extends StatelessWidget {
  const MockupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          surface: const Color(0xFFF5F5F5),
          primary: const Color(0xFF5C6BC0), // indigo accent — just a suggestion
          secondary: Colors.white,
          inversePrimary: Colors.grey.shade900,
        ),
        useMaterial3: true,
      ),
      home: const MockupShell(),
    );
  }
}

// ─── Shell with bottom nav ────────────────────────────────────────────────────

class MockupShell extends StatefulWidget {
  const MockupShell({super.key});

  @override
  State<MockupShell> createState() => _MockupShellState();
}

class _MockupShellState extends State<MockupShell> {
  int _currentIndex = 0;

  final _pages = const [
    BookingsTab(),
    NeighboursTab(),
    SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_laundry_service_outlined),
            selectedIcon: Icon(Icons.local_laundry_service),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: _UnreadIcon(count: 2),
            selectedIcon: Icon(Icons.people),
            label: 'Neighbours',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// Badge icon for unread messages in nav bar
class _UnreadIcon extends StatelessWidget {
  final int count;
  const _UnreadIcon({required this.count});

  @override
  Widget build(BuildContext context) {
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: const Icon(Icons.people_outline),
    );
  }
}

// ─── Bookings Tab ─────────────────────────────────────────────────────────────

class BookingsTab extends StatelessWidget {
  const BookingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            title: const Text('Laundry'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_scanner),
                tooltip: 'Scan to join',
                onPressed: () => _showJoinDialog(context),
              ),
            ],
          ),
          // Next booking card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: _NextBookingCard(theme: theme),
            ),
          ),
          // Machine availability
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Machines',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MachineRow(
                    number: 1, status: MachineStatus.free, onBook: () {}),
                const SizedBox(height: 8),
                _MachineRow(
                    number: 2,
                    status: MachineStatus.mine,
                    onBook: () {},
                    endsAt: '14:30'),
                const SizedBox(height: 8),
                _MachineRow(
                    number: 3,
                    status: MachineStatus.taken,
                    onBook: () {},
                    endsAt: '15:00'),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          // Upcoming section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text('Upcoming bookings',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _UpcomingBookingTile(
                    machine: 2, date: 'Today', time: '13:30 – 14:30'),
                const _UpcomingBookingTile(
                    machine: 1, date: 'Tomorrow', time: '09:00 – 10:00'),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Join a group'),
        content: const Text(
            'Scan the QR code posted in your laundry room to join your building\'s group.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Open scanner')),
        ],
      ),
    );
  }
}

class _NextBookingCard extends StatelessWidget {
  final ThemeData theme;
  const _NextBookingCard({required this.theme});

  @override
  Widget build(BuildContext context) {
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

enum MachineStatus { free, mine, taken }

class _MachineRow extends StatelessWidget {
  final int number;
  final MachineStatus status;
  final VoidCallback onBook;
  final String? endsAt;

  const _MachineRow(
      {required this.number,
      required this.status,
      required this.onBook,
      this.endsAt});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (color, label, btnLabel) = switch (status) {
      MachineStatus.free => (Colors.green.shade50, 'Available', 'Book'),
      MachineStatus.mine => (Colors.blue.shade50, 'Your booking', 'Cancel'),
      MachineStatus.taken => (Colors.red.shade50, 'In use', null),
    };

    final (dotColor) = switch (status) {
      MachineStatus.free => Colors.green,
      MachineStatus.mine => Colors.blue,
      MachineStatus.taken => Colors.red,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color,
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
                    status == MachineStatus.free
                        ? label
                        : '$label · until $endsAt',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey.shade700)),
              ],
            ),
          ),
          if (btnLabel != null)
            FilledButton.tonal(
              onPressed: onBook,
              style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact),
              child: Text(btnLabel),
            ),
        ],
      ),
    );
  }
}

class _UpcomingBookingTile extends StatelessWidget {
  final int machine;
  final String date;
  final String time;
  const _UpcomingBookingTile(
      {required this.machine, required this.date, required this.time});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.indigo.shade50,
        child: const Icon(Icons.local_laundry_service_outlined,
            color: Colors.indigo),
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

// ─── Neighbours Tab ───────────────────────────────────────────────────────────

class NeighboursTab extends StatelessWidget {
  const NeighboursTab({super.key});

  static const _neighbours = [
    ('Anna M.', 'AM', Colors.pink, 2),
    ('Thomas B.', 'TB', Colors.teal, 0),
    ('Laura K.', 'LK', Colors.orange, 0),
    ('Peter S.', 'PS', Colors.purple, 1),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            title: Text('Neighbours'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final (name, initials, color, unread) = _neighbours[i];
                  return _NeighbourTile(
                    name: name,
                    initials: initials,
                    avatarColor: color,
                    unread: unread,
                    lastMessage: i == 0
                        ? 'Is machine 1 free at 3pm?'
                        : i == 3
                            ? 'Thanks!'
                            : null,
                  );
                },
                childCount: _neighbours.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NeighbourTile extends StatelessWidget {
  final String name;
  final String initials;
  final MaterialColor avatarColor;
  final int unread;
  final String? lastMessage;

  const _NeighbourTile({
    required this.name,
    required this.initials,
    required this.avatarColor,
    required this.unread,
    this.lastMessage,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: avatarColor.shade100,
        child: Text(initials,
            style: TextStyle(
                color: avatarColor.shade800, fontWeight: FontWeight.bold)),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: lastMessage != null
          ? Text(lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: unread > 0 ? Colors.black87 : Colors.grey.shade600,
                  fontWeight:
                      unread > 0 ? FontWeight.w500 : FontWeight.normal))
          : null,
      trailing: unread > 0
          ? CircleAvatar(
              radius: 11,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text('$unread',
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            )
          : null,
      onTap: () {},
    );
  }
}

// ─── Settings Tab ─────────────────────────────────────────────────────────────

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _darkMode = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(
            floating: true,
            title: Text('Settings'),
            centerTitle: false,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile card
                  _ProfileCard(),
                  const SizedBox(height: 24),

                  const _SectionLabel('Appearance'),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Dark mode'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    trailing: DropdownButton<String>(
                      value: _language,
                      underline: const SizedBox(),
                      items: ['English', 'Deutsch', 'Français', 'Italiano',
                            'Rumantsch']
                          .map((l) =>
                              DropdownMenuItem(value: l, child: Text(l)))
                          .toList(),
                      onChanged: (v) => setState(() => _language = v!),
                    ),
                  ),
                  const Divider(height: 32),

                  const _SectionLabel('Group'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.qr_code),
                    title: const Text('Generate group QR code'),
                    subtitle: const Text('Share with new members'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.qr_code_scanner),
                    title: const Text('Join a group'),
                    subtitle: const Text('Scan a QR code to enroll'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  const Divider(height: 32),

                  const _SectionLabel('Account'),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('Sign out',
                        style: TextStyle(color: Colors.redAccent)),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primary,
            child: const Text('SB',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('sebopr@gmail.com',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text('Building A · Group 4F2',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.grey.shade600, letterSpacing: 1.2)),
    );
  }
}

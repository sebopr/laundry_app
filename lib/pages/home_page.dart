import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laundry_app/pages/admin/admin_page.dart';
import 'package:laundry_app/pages/calendar_page.dart';
import 'package:laundry_app/pages/chat_page.dart';
import 'package:laundry_app/pages/settings_page.dart';
import 'package:laundry_app/services/chat/chat_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .snapshots(),
      builder: (context, snap) {
        final d = snap.data?.data() ?? {};
        final role = d['role'] as String? ?? 'resident';
        final isResidentAdmin = d['isResidentAdmin'] as bool? ?? false;

        final pages = _buildPages(role, isResidentAdmin);
        final destinations = _buildDestinations(role, isResidentAdmin);
        final safeIndex = _currentIndex.clamp(0, pages.length - 1);

        return Scaffold(
          body: IndexedStack(
            index: safeIndex,
            children: pages,
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: safeIndex,
            onDestinationSelected: (i) => setState(() => _currentIndex = i),
            destinations: destinations,
          ),
        );
      },
    );
  }

  List<Widget> _buildPages(String role, bool isResidentAdmin) {
    if (role == 'admin' && !isResidentAdmin) {
      return const [AdminPage(), SettingsPage()];
    }
    if (role == 'admin' && isResidentAdmin) {
      return const [
        BookingCalendarPage(),
        _NeighboursTab(),
        AdminPage(),
        SettingsPage(),
      ];
    }
    return const [BookingCalendarPage(), _NeighboursTab(), SettingsPage()];
  }

  List<NavigationDestination> _buildDestinations(
      String role, bool isResidentAdmin) {
    if (role == 'admin' && !isResidentAdmin) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.business_outlined),
          selectedIcon: Icon(Icons.business),
          label: 'Admin',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ];
    }
    if (role == 'admin' && isResidentAdmin) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.local_laundry_service_outlined),
          selectedIcon: Icon(Icons.local_laundry_service),
          label: 'Bookings',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: 'Neighbours',
        ),
        NavigationDestination(
          icon: Icon(Icons.business_outlined),
          selectedIcon: Icon(Icons.business),
          label: 'Admin',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ];
    }
    return const [
      NavigationDestination(
        icon: Icon(Icons.local_laundry_service_outlined),
        selectedIcon: Icon(Icons.local_laundry_service),
        label: 'Bookings',
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: 'Neighbours',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ];
  }
}

// ─── Neighbours tab ───────────────────────────────────────────────────────────

class _NeighboursTab extends StatelessWidget {
  const _NeighboursTab();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final chatService = ChatService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Neighbours'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: chatService.getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!
              .where((u) => u['email'] != currentUser.email)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No neighbours yet'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final userData = users[i];
              return StreamBuilder<int>(
                stream: chatService.getUnreadCount(
                    currentUser.uid, userData['uid']),
                builder: (context, unreadSnap) {
                  return _NeighbourTile(
                    userData: userData,
                    unread: unreadSnap.data ?? 0,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          receiverEmail: userData['email'],
                          receiverId: userData['uid'],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NeighbourTile extends StatelessWidget {
  final Map<String, dynamic> userData;
  final int unread;
  final VoidCallback onTap;

  const _NeighbourTile({
    required this.userData,
    required this.unread,
    required this.onTap,
  });

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final displayName =
        userData['displayName'] as String? ?? userData['email'] as String;
    final householdName = userData['household_name'] as String?;
    final initials = _initials(displayName);

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor:
            theme.colorScheme.primary.withValues(alpha: 0.15),
        child: Text(
          initials,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(displayName,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: householdName != null
          ? Text(householdName,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
          : null,
      trailing: unread > 0
          ? CircleAvatar(
              radius: 11,
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style:
                    const TextStyle(color: Colors.white, fontSize: 10),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}

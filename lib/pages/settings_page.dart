import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laundry_app/pages/generate_qr_page.dart';
import 'package:laundry_app/pages/onboarding_page.dart';
import 'package:laundry_app/pages/profile_page.dart';
import 'package:laundry_app/services/auth/auth_service.dart';
import 'package:laundry_app/services/household/household_service.dart';
import 'package:laundry_app/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          final userData = snap.data?.data() ?? {};
          final displayName = userData['displayName'] as String? ?? '';
          final email =
              FirebaseAuth.instance.currentUser!.email ?? '';
          final householdId =
              userData['household_id'] as String?;
          final householdName =
              userData['household_name'] as String?;
          final isHead =
              userData['isHouseholdHead'] as bool? ?? false;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Profile card ──────────────────────────────────────
              _ProfileCard(
                displayName: displayName,
                email: email,
                householdName: householdName,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProfilePage()),
                ),
              ),
              const SizedBox(height: 24),

              // ── Appearance ────────────────────────────────────────
              const _SectionLabel('Appearance'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                secondary: const Icon(Icons.dark_mode_outlined),
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                trailing: DropdownButton<String>(
                  value: _language,
                  underline: const SizedBox(),
                  items: [
                    'English',
                    'Deutsch',
                    'Français',
                    'Italiano',
                    'Rumantsch'
                  ]
                      .map((l) =>
                          DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => _language = v!),
                ),
              ),
              const Divider(height: 32),

              // ── Household ─────────────────────────────────────────
              const _SectionLabel('Household'),
              if (householdId != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.home_outlined),
                  title: Text(householdName ?? 'My household'),
                  subtitle: isHead
                      ? const Text('You manage this household')
                      : const Text('Member'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showHouseholdSheet(
                      context, householdId, householdName ?? '', isHead),
                ),
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.group_add_outlined),
                  title: const Text('Set up household'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const OnboardingPage(initialStep: 2)),
                  ),
                ),
              ],
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.qr_code),
                title: const Text('Building QR code'),
                subtitle: const Text('Print and post in laundry room'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const GenerateQrPage()),
                ),
              ),
              const Divider(height: 32),

              // ── Account ───────────────────────────────────────────
              const _SectionLabel('Account'),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading:
                    const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Sign out',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () => AuthService().signOut(),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showHouseholdSheet(BuildContext context, String householdId,
      String householdName, bool isHead) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _HouseholdSheet(
        householdId: householdId,
        householdName: householdName,
        isHead: isHead,
      ),
    );
  }
}

// ─── Profile card ─────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String? householdName;
  final VoidCallback onEdit;

  const _ProfileCard({
    required this.displayName,
    required this.email,
    required this.householdName,
    required this.onEdit,
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
    final name = displayName.isNotEmpty ? displayName : email;
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
            child: Text(
              _initials(name),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (householdName != null)
                  Text(householdName!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600)),
                Text(email,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.grey.shade500)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
            tooltip: 'Edit profile',
          ),
        ],
      ),
    );
  }
}

// ─── Household bottom sheet ───────────────────────────────────────────────────

class _HouseholdSheet extends StatelessWidget {
  final String householdId;
  final String householdName;
  final bool isHead;

  const _HouseholdSheet({
    required this.householdId,
    required this.householdName,
    required this.isHead,
  });

  // Household invite QR payload
  String get _inviteData => 'household:$householdId';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: HouseholdService.stream(householdId),
        builder: (context, snap) {
          final data = snap.data?.data();
          final members =
              List<String>.from(data?['members'] ?? []);

          return ListView(
            controller: controller,
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(Icons.home_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(householdName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),

              // Members list
              Text('Members',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600,
                      letterSpacing: 1.2)),
              const SizedBox(height: 8),
              _MembersList(memberUids: members),
              const Divider(height: 32),

              // Invite QR (head only)
              if (isHead) ...[
                Text('Invite a household member',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Let them scan this to join your household.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: QrImageView(
                      data: _inviteData,
                      version: QrVersions.auto,
                      size: 180,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MembersList extends StatelessWidget {
  final List<String> memberUids;
  const _MembersList({required this.memberUids});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: HouseholdService.getMembers(memberUids),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          );
        }
        final members = snap.data!;
        return Column(
          children: members.map((m) {
            final name =
                m['displayName'] as String? ?? m['email'] as String? ?? '?';
            final isCurrentUser =
                m['uid'] == FirebaseAuth.instance.currentUser!.uid;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                child: Text(
                  name.length >= 2
                      ? name.substring(0, 2).toUpperCase()
                      : name.toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(name),
              trailing: isCurrentUser
                  ? Text('You',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12))
                  : null,
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey.shade600, letterSpacing: 1.2),
      ),
    );
  }
}

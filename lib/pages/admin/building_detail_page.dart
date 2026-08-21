import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/pages/generate_qr_page.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BuildingDetailPage extends StatelessWidget {
  final String buildingUuid;
  final String buildingName;

  const BuildingDetailPage({
    super.key,
    required this.buildingUuid,
    required this.buildingName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(buildingName),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.qrCode),
              tooltip: 'Building QR',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        GenerateQrPage(buildingUuid: buildingUuid)),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(LucideIcons.users), text: 'Residents'),
              Tab(
                  icon: Icon(LucideIcons.washingMachine),
                  text: 'Machines'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ResidentsTab(buildingUuid: buildingUuid),
            _MachinesTab(buildingUuid: buildingUuid),
          ],
        ),
      ),
    );
  }
}

// ─── Residents tab ────────────────────────────────────────────────────────────

class _ResidentsTab extends StatelessWidget {
  final String buildingUuid;
  const _ResidentsTab({required this.buildingUuid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('linked_uuid', isEqualTo: buildingUuid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snap.data!.docs
            .map((d) => {'uid': d.id, ...d.data()})
            .toList();

        if (users.isEmpty) {
          return const Center(child: Text('No residents yet'));
        }

        // Group by household_id
        final Map<String, List<Map<String, dynamic>>> byHousehold = {};
        final List<Map<String, dynamic>> noHousehold = [];

        for (final u in users) {
          final hid = u['household_id'] as String?;
          if (hid == null) {
            noHousehold.add(u);
          } else {
            byHousehold.putIfAbsent(hid, () => []).add(u);
          }
        }

        final householdIds = byHousehold.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: householdIds.length + (noHousehold.isNotEmpty ? 1 : 0),
          itemBuilder: (context, i) {
            if (i == householdIds.length) {
              return _HouseholdGroup(
                name: 'No household',
                members: noHousehold,
                onRemove: (uid) => _removeResident(context, uid),
              );
            }
            final hid = householdIds[i];
            final members = byHousehold[hid]!;
            final householdName =
                members.first['household_name'] as String? ?? hid;
            return _HouseholdGroup(
              name: householdName,
              members: members,
              onRemove: (uid) => _removeResident(context, uid),
            );
          },
        );
      },
    );
  }

  Future<void> _removeResident(BuildContext context, String uid) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove resident'),
        content: const Text(
            'This will remove the resident from the building. They will need to re-scan the QR to rejoin.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'linked_uuid': FieldValue.delete(),
      'household_id': FieldValue.delete(),
      'household_name': FieldValue.delete(),
    });
  }
}

class _HouseholdGroup extends StatelessWidget {
  final String name;
  final List<Map<String, dynamic>> members;
  final void Function(String uid) onRemove;

  const _HouseholdGroup({
    required this.name,
    required this.members,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              name.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600, letterSpacing: 1.2),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF2B3542)
                      : const Color(0xFFE7EEEE)),
            ),
            child: Column(
              children: members.asMap().entries.map((entry) {
                final i = entry.key;
                final m = entry.value;
                final uid = m['uid'] as String;
                final displayName =
                    m['displayName'] as String? ?? m['email'] as String? ?? '?';
                final isHead = m['isHouseholdHead'] as bool? ?? false;
                final isSelf = uid == currentUid;

                return Column(
                  children: [
                    if (i > 0)
                      const Divider(height: 1, indent: 56, endIndent: 16),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary
                            .withValues(alpha: 0.12),
                        child: Text(
                          displayName.length >= 2
                              ? displayName.substring(0, 2).toUpperCase()
                              : displayName.toUpperCase(),
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12),
                        ),
                      ),
                      title: Text(displayName),
                      subtitle: Text(
                        m['email'] as String? ?? '',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isHead)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Head',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.primary)),
                            ),
                          if (!isSelf) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(LucideIcons.userMinus2,
                                  size: 18, color: Colors.redAccent),
                              onPressed: () => onRemove(uid),
                              tooltip: 'Remove from building',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Machines tab ─────────────────────────────────────────────────────────────

class _MachinesTab extends StatelessWidget {
  final String buildingUuid;
  const _MachinesTab({required this.buildingUuid});

  static String _machineStatus(dynamic value) {
    if (value is String) return value;
    if (value is Map) return value['status'] as String? ?? 'active';
    return 'active';
  }

  Future<void> _addMachine(Map<String, dynamic> machines) async {
    final keys = machines.keys.map(int.parse).toList();
    final next =
        keys.isEmpty ? 1 : (keys.reduce((a, b) => a > b ? a : b) + 1);
    await FirebaseFirestore.instance
        .collection('buildings')
        .doc(buildingUuid)
        .update({'machines.$next': 'active'});
  }

  Future<void> _removeMachine(BuildContext context, int number) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove machine?'),
        content: Text(
            'Machine $number will be removed. Existing bookings for this machine are not automatically cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseFirestore.instance
        .collection('buildings')
        .doc(buildingUuid)
        .update({'machines.$number': FieldValue.delete()});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingUuid)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final raw = snap.data!.data()?['machines'];
        final machines = raw is Map
            ? Map<String, dynamic>.from(raw)
            : <String, dynamic>{};

        final sortedEntries = machines.entries
            .where((e) => int.tryParse(e.key) != null)
            .toList()
          ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Toggle machines in or out of service, or add/remove machines.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ...sortedEntries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MachineToggleCard(
                    number: int.parse(e.key),
                    status: _machineStatus(e.value),
                    buildingUuid: buildingUuid,
                    onRemove: () =>
                        _removeMachine(context, int.parse(e.key)),
                  ),
                )),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => _addMachine(machines),
              icon: const Icon(LucideIcons.plus),
              label: const Text('Add machine'),
            ),
          ],
        );
      },
    );
  }
}

class _MachineToggleCard extends StatelessWidget {
  final int number;
  final String status;
  final String buildingUuid;
  final VoidCallback onRemove;

  const _MachineToggleCard({
    required this.number,
    required this.status,
    required this.buildingUuid,
    required this.onRemove,
  });

  bool get _isActive => status == 'active';

  Future<void> _toggle() async {
    final newStatus = _isActive ? 'maintenance' : 'active';
    await FirebaseFirestore.instance
        .collection('buildings')
        .doc(buildingUuid)
        .update({'machines.$number': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bgColor, dotColor, label) = _isActive
        ? (Colors.green.shade50, Colors.green, 'Active')
        : (Colors.orange.shade50, Colors.orange, 'Maintenance');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.washingMachine, color: dotColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Machine $number',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: dotColor),
                    ),
                    const SizedBox(width: 4),
                    Text(label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: dotColor)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 18),
            color: Colors.red.shade300,
            onPressed: onRemove,
            tooltip: 'Remove machine',
            visualDensity: VisualDensity.compact,
          ),
          Switch(
            value: _isActive,
            onChanged: (_) => _toggle(),
            activeThumbColor: Colors.green,
          ),
        ],
      ),
    );
  }
}

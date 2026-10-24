import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/pages/admin/hand_over_page.dart';
import 'package:lavaplan/pages/generate_qr_page.dart';
import 'package:lavaplan/services/building/building_service.dart';
import 'package:lavaplan/services/household/join_request_service.dart';
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
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(buildingName),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.qrCode),
              tooltip: l10n.buildingQrTooltip,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => GenerateQrPage(buildingUuid: buildingUuid)),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.arrowRightLeft),
              tooltip: l10n.handOverBuilding,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => HandOverPage(
                        buildingUuid: buildingUuid,
                        buildingName: buildingName)),
              ),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: const Icon(LucideIcons.users), text: l10n.residentsTab),
              Tab(
                  icon: const Icon(LucideIcons.washingMachine),
                  text: l10n.machinesTab),
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

class _ResidentsTab extends StatefulWidget {
  final String buildingUuid;
  const _ResidentsTab({required this.buildingUuid});

  @override
  State<_ResidentsTab> createState() => _ResidentsTabState();
}

class _ResidentsTabState extends State<_ResidentsTab> {
  // Loaded through getBuildingResidents rather than a live users query, so
  // contact details are only ever sent to verified admins.
  late Future<List<Map<String, dynamic>>> _residents;

  @override
  void initState() {
    super.initState();
    _residents = BuildingService.getResidents(widget.buildingUuid);
  }

  Future<void> _reload() async {
    final next = BuildingService.getResidents(widget.buildingUuid);
    setState(() => _residents = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PendingRequestsSection(
            buildingUuid: widget.buildingUuid, onResolved: _reload),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _residents,
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(
                    child: Text(AppLocalizations.of(context)!.errorGeneric));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snap.data!;

              if (users.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                          child: Text(
                              AppLocalizations.of(context)!.noResidentsYet)),
                    ],
                  ),
                );
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

              return RefreshIndicator(
                onRefresh: _reload,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount:
                      householdIds.length + (noHousehold.isNotEmpty ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == householdIds.length) {
                      return _HouseholdGroup(
                        name: AppLocalizations.of(context)!.noHousehold,
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
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _removeResident(BuildContext context, String uid) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.removeResident),
        content: Text(l10n.removeResidentContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.btnCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.btnRemove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await BuildingService.removeResident(widget.buildingUuid, uid);
      await _reload();
    } catch (e) {
      debugPrint('Remove resident failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}

// ─── Pending requests ──────────────────────────────────────────────────────────

class _PendingRequestsSection extends StatelessWidget {
  final String buildingUuid;
  final VoidCallback onResolved;
  const _PendingRequestsSection(
      {required this.buildingUuid, required this.onResolved});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: JoinRequestService.pendingForBuilding(buildingUuid),
      builder: (context, snap) {
        final requests = snap.data ?? [];
        if (requests.isEmpty) return const SizedBox.shrink();

        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF2B3542)
                    : const Color(0xFFE7EEEE)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Text(
                  l10n.pendingRequestsTitle(requests.length),
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.orange.shade800,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2),
                ),
              ),
              ...requests.map((r) => _PendingRequestTile(
                  request: r, onResolved: onResolved)),
            ],
          ),
        );
      },
    );
  }
}

class _PendingRequestTile extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback onResolved;
  const _PendingRequestTile({required this.request, required this.onResolved});

  @override
  State<_PendingRequestTile> createState() => _PendingRequestTileState();
}

class _PendingRequestTileState extends State<_PendingRequestTile> {
  bool _resolving = false;

  Future<void> _resolve(bool approve) async {
    setState(() => _resolving = true);
    try {
      await JoinRequestService.resolve(widget.request['id'] as String, approve);
      if (approve) widget.onResolved();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final displayName = widget.request['displayName'] as String? ??
        widget.request['email'] as String? ??
        '?';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.orange.withValues(alpha: 0.12),
        child: Icon(LucideIcons.userPlus2,
            color: Colors.orange.shade800, size: 18),
      ),
      title: Text(displayName),
      subtitle: Text(l10n.joinRequestBuildingLabel,
          style: const TextStyle(fontSize: 11)),
      trailing: _resolving
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.redAccent),
                  tooltip: l10n.btnReject,
                  onPressed: () => _resolve(false),
                ),
                IconButton(
                  icon:
                      Icon(LucideIcons.check, color: theme.colorScheme.primary),
                  tooltip: l10n.btnApprove,
                  onPressed: () => _resolve(true),
                ),
              ],
            ),
    );
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
    final l10n = AppLocalizations.of(context)!;
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
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: Colors.grey.shade600, letterSpacing: 1.2),
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
                final displayNameRaw = m['displayName'] as String? ?? '';
                final displayName = displayNameRaw.isNotEmpty
                    ? displayNameRaw
                    : m['email'] as String? ?? '?';
                // Only present for verified admins (getBuildingResidents).
                final email = m['email'] as String?;
                final isHead = m['isHouseholdHead'] as bool? ?? false;
                final isSelf = uid == currentUid;

                return Column(
                  children: [
                    if (i > 0)
                      const Divider(height: 1, indent: 56, endIndent: 16),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
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
                      subtitle: email == null || email.isEmpty
                          ? null
                          : Text(
                              email,
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
                              child: Text(l10n.headLabel,
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
                              tooltip: l10n.removeFromBuilding,
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
    final next = keys.isEmpty ? 1 : (keys.reduce((a, b) => a > b ? a : b) + 1);
    await FirebaseFirestore.instance
        .collection('buildings')
        .doc(buildingUuid)
        .update({'machines.$next': 'active'});
  }

  Future<void> _removeMachine(BuildContext context, int number) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.removeMachineTitle),
        content: Text(l10n.removeMachineContent(number)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.btnCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.btnRemove),
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
        final machines =
            raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

        final sortedEntries = machines.entries
            .where((e) => int.tryParse(e.key) != null)
            .toList()
          ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              AppLocalizations.of(context)!.machinesDescription,
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
                    onRemove: () => _removeMachine(context, int.parse(e.key)),
                  ),
                )),
            const SizedBox(height: 4),
            OutlinedButton.icon(
              onPressed: () => _addMachine(machines),
              icon: const Icon(LucideIcons.plus),
              label: Text(AppLocalizations.of(context)!.addMachine),
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme.brightness == Brightness.dark;
    final (dotColor, label) = _isActive
        ? (const Color(0xFF34A853), l10n.activeStatus)
        : (const Color(0xFFE8963C), l10n.maintenanceStatus);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? const Color(0xFF2B3542) : const Color(0xFFE7EEEE)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.washingMachine, color: dotColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.machineN(number),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: dotColor),
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
            tooltip: l10n.removeMachineTooltip,
            visualDensity: VisualDensity.compact,
          ),
          Switch(
            value: _isActive,
            onChanged: (_) => _toggle(),
          ),
        ],
      ),
    );
  }
}

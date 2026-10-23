import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/pages/admin/building_detail_page.dart';
import 'package:lavaplan/pages/admin/create_building_page.dart';
import 'package:lavaplan/services/building/building_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminTitle),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateBuildingPage()),
        ),
        icon: const Icon(LucideIcons.building2),
        label: Text(l10n.addBuilding),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          final managed = List<String>.from(
              snap.data?.data()?['managed_buildings'] ?? []);
          final verified =
              snap.data?.data()?['adminVerified'] as bool? ?? false;

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (managed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.building2,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(l10n.noBuildingsYet,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(l10n.tapToAddBuilding,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (!verified) ...[
                const _UnverifiedBanner(),
                const SizedBox(height: 12),
              ],
              for (final (i, uuid) in managed.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                _BuildingCard(buildingUuid: uuid),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Building card ────────────────────────────────────────────────────────────

class _BuildingCard extends StatelessWidget {
  final String buildingUuid;
  const _BuildingCard({required this.buildingUuid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingUuid)
          .snapshots(),
      builder: (context, buildingSnap) {
        final buildingData = buildingSnap.data?.data() ?? {};
        final name = buildingData['name'] as String? ?? 'Building';
        final machines =
            Map<String, dynamic>.from(buildingData['machines'] as Map? ?? {});
        final maintenanceCount =
            machines.values.where((v) => v == 'maintenance').length;

        return InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BuildingDetailPage(
                buildingUuid: buildingUuid,
                buildingName: name,
              ),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? const Color(0xFF2B3542)
                      : const Color(0xFFE7EEEE)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(LucideIcons.building2,
                      color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      _ResidentCount(buildingUuid: buildingUuid),
                      if (maintenanceCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.triangleAlert,
                                  size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                l10n.maintenanceCount(maintenanceCount),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Unverified banner ────────────────────────────────────────────────────────

/// Shown to self-declared admins: what they can do until they're verified.
class _UnverifiedBanner extends StatelessWidget {
  const _UnverifiedBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.shieldAlert, size: 18, color: Colors.orange.shade800),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.adminUnverifiedBanner,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResidentCount extends StatefulWidget {
  final String buildingUuid;
  const _ResidentCount({required this.buildingUuid});

  @override
  State<_ResidentCount> createState() => _ResidentCountState();
}

class _ResidentCountState extends State<_ResidentCount> {
  late final Future<List<Map<String, dynamic>>> _residents =
      BuildingService.getResidents(widget.buildingUuid);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _residents,
      builder: (context, snap) {
        final count = snap.data?.length ?? 0;
        return Text(
          AppLocalizations.of(context)!.residentsCount(count),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        );
      },
    );
  }
}

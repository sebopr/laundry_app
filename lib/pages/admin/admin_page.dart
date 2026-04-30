import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laundry_app/pages/admin/building_detail_page.dart';
import 'package:laundry_app/pages/admin/create_building_page.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateBuildingPage()),
        ),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add building'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          final managed = List<String>.from(
              snap.data?.data()?['managed_buildings'] ?? []);

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (managed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('No buildings yet',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Tap + Add building to get started.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: managed.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) =>
                _BuildingCard(buildingUuid: managed[i]),
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
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Icon(Icons.business_outlined,
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
                              const Icon(Icons.warning_amber_rounded,
                                  size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                '$maintenanceCount machine${maintenanceCount > 1 ? 's' : ''} in maintenance',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: Colors.orange),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ResidentCount extends StatelessWidget {
  final String buildingUuid;
  const _ResidentCount({required this.buildingUuid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('linked_uuid', isEqualTo: buildingUuid)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Text(
          '$count resident${count != 1 ? 's' : ''}',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        );
      },
    );
  }
}

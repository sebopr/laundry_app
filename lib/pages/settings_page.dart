import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/components/avatar_photo_picker.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/pages/onboarding_page.dart';
import 'package:lavaplan/pages/profile_page.dart';
import 'package:lavaplan/services/account/account_service.dart';
import 'package:lavaplan/services/auth/auth_service.dart';
import 'package:lavaplan/services/building/building_service.dart';
import 'package:lavaplan/services/household/household_service.dart';
import 'package:lavaplan/services/locale/locale_provider.dart';
import 'package:lavaplan/themes/theme_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
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
          final email = FirebaseAuth.instance.currentUser!.email ?? '';
          final householdId = userData['household_id'] as String?;
          final householdName = userData['household_name'] as String?;
          final isHead = userData['isHouseholdHead'] as bool? ?? false;
          final linkedUuid = userData['linked_uuid'] as String?;

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
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                ),
              ),
              const SizedBox(height: 24),

              // ── Appearance ────────────────────────────────────────
              _SectionLabel(l10n.sectionAppearance),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.darkMode),
                secondary: const _RowIcon(LucideIcons.moon),
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _RowIcon(LucideIcons.languages),
                title: Text(l10n.language),
                trailing: DropdownButton<String>(
                  value: localeProvider.languageName,
                  underline: const SizedBox(),
                  items: const [
                    'English',
                    'Deutsch',
                    'Français',
                    'Italiano',
                    'Rumantsch',
                  ]
                      .map((lang) =>
                          DropdownMenuItem(value: lang, child: Text(lang)))
                      .toList(),
                  onChanged: (v) => localeProvider.setLanguage(v!),
                ),
              ),
              const Divider(height: 32),

              // ── Household ─────────────────────────────────────────
              _SectionLabel(l10n.sectionHousehold),
              if (householdId != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _RowIcon(LucideIcons.house),
                  title: Text(householdName ?? l10n.myHousehold),
                  subtitle: isHead
                      ? Text(l10n.youManageHousehold)
                      : Text(l10n.memberLabel),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => _showHouseholdSheet(
                      context, householdId, householdName ?? '', isHead),
                ),
              ] else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _RowIcon(LucideIcons.userPlus2),
                  title: Text(l10n.setupHousehold),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const OnboardingPage(initialStep: 3)),
                  ),
                ),
              ],
              if (linkedUuid != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const _RowIcon(LucideIcons.doorOpen,
                      color: Colors.orange, tint: Color(0x1AE8963C)),
                  title: Text(l10n.leaveBuilding,
                      style: const TextStyle(color: Colors.orange)),
                  onTap: () => _confirmLeaveBuilding(context),
                ),
              const Divider(height: 32),

              // ── Building ──────────────────────────────────────────
              if (linkedUuid != null) ...[
                _SectionLabel(l10n.sectionBuilding),
                _BuildingAdminTile(buildingUuid: linkedUuid),
                const Divider(height: 32),
              ],

              // ── Account ───────────────────────────────────────────
              _SectionLabel(l10n.sectionAccount),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _RowIcon(LucideIcons.logOut,
                    color: Colors.redAccent, tint: Color(0x1AE15B5B)),
                title: Text(l10n.signOut,
                    style: const TextStyle(color: Colors.redAccent)),
                onTap: () => AuthService().signOut(),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const _RowIcon(LucideIcons.trash2,
                    color: Colors.redAccent, tint: Color(0x1AE15B5B)),
                title: Text(l10n.deleteAccount,
                    style: const TextStyle(color: Colors.redAccent)),
                onTap: () => _confirmDeleteAccount(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmLeaveBuilding(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.leaveBuilding),
        content: Text(l10n.leaveBuildingContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.btnCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(l10n.leaveBuilding),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AccountService.leaveBuilding();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountContent),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.btnCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await AccountService.deleteAccount();
      await AuthService().signOut();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
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
    final l10n = AppLocalizations.of(context)!;
    final name = displayName.isNotEmpty ? displayName : email;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          AvatarPhotoPicker(initials: _initials(name), radius: 28),
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
            icon: const Icon(LucideIcons.squarePen, size: 20),
            onPressed: onEdit,
            tooltip: l10n.editProfile,
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

  String get _inviteData => 'household:$householdId';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => StreamBuilder<
          DocumentSnapshot<Map<String, dynamic>>>(
        stream: HouseholdService.stream(householdId),
        builder: (context, snap) {
          final data = snap.data?.data();
          final members = List<String>.from(data?['members'] ?? []);

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
                  Icon(LucideIcons.house,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(householdName,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              Text(l10n.householdMembers,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey.shade600, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              _MembersList(memberUids: members),
              const Divider(height: 32),
              if (isHead) ...[
                Text(l10n.inviteHouseholdMember,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  l10n.inviteScanText,
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
    final l10n = AppLocalizations.of(context)!;
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
                  ? Text(l10n.youLabel,
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

// ─── Building admin ───────────────────────────────────────────────────────────

/// Who runs the resident's building, and whether that admin is verified.
/// Residents can report an admin who doesn't act for the owner or property
/// management (reportBuildingAdmin).
class _BuildingAdminTile extends StatelessWidget {
  final String buildingUuid;
  const _BuildingAdminTile({required this.buildingUuid});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('buildings')
          .doc(buildingUuid)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final adminName = data['admin_name'] as String? ?? '';
        // Older buildings get these fields from the backfill script.
        if (adminName.isEmpty) return const SizedBox.shrink();
        final verified = data['admin_verified'] as bool? ?? false;
        final isSelf = data['admin_uid'] == uid;

        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: _RowIcon(
            verified ? LucideIcons.shieldCheck : LucideIcons.shieldAlert,
            color: verified ? null : Colors.orange,
            tint: verified ? null : const Color(0x1AE8963C),
          ),
          title: Text(adminName),
          subtitle: Text(verified ? l10n.adminVerified : l10n.adminNotVerified),
          trailing: isSelf
              ? null
              : TextButton(
                  onPressed: () => _report(context),
                  child: Text(l10n.reportAdmin),
                ),
        );
      },
    );
  }

  Future<void> _report(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.reportAdminTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.reportAdminContent),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(hintText: l10n.reportAdminReasonHint),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.btnCancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.reportAdmin),
          ),
        ],
      ),
    );
    // Not disposed here: the dialog's closing animation still uses it.
    final text = reason.text.trim();
    if (confirmed != true) return;

    try {
      await BuildingService.reportAdmin(text);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.reportAdminSent)));
    } catch (e) {
      debugPrint('Report admin failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
    }
  }
}

// ─── Row icon chip ────────────────────────────────────────────────────────────

class _RowIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? tint;

  const _RowIcon(this.icon, {this.color, this.tint});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: tint ?? theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 17, color: color ?? theme.colorScheme.primary),
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

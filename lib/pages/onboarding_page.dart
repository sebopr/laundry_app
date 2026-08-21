// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/components/avatar_photo_picker.dart';
import 'package:lavaplan/components/custom_cam_painter.dart';
import 'package:lavaplan/constants/swiss_cantons.dart';
import 'package:lavaplan/pages/admin/create_building_page.dart';
import 'package:lavaplan/services/household/household_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

class OnboardingPage extends StatefulWidget {
  final int initialStep;
  const OnboardingPage({super.key, required this.initialStep});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final PageController _pageController;
  late int _step;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
    _pageController = PageController(initialPage: widget.initialStep);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    final next = _step + 1;
    setState(() => _step = next);
    _pageController.animateToPage(next,
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Steps: 0=name, 1=profile details, 2=role, 3=building, 4=household
    const totalSteps = 5;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/branding/lavaplan_mark.png', height: 28),
                const SizedBox(width: 10),
                Text('Lavaplan',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                totalSteps,
                (i) => _StepDot(active: i == _step, done: i < _step),
              ),
            ),
            const SizedBox(height: 36),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _NameStep(onDone: _nextStep),
                  _ProfileDetailsStep(onDone: _nextStep),
                  _RoleStep(onDone: _nextStep),
                  _BuildingStep(onDone: _nextStep),
                  const _HouseholdStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step indicator dot ───────────────────────────────────────────────────────

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepDot({required this.active, required this.done});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: (active || done) ? color : color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ─── Step 0: Name ─────────────────────────────────────────────────────────────

class _NameStep extends StatefulWidget {
  final VoidCallback onDone;
  const _NameStep({required this.onDone});

  @override
  State<_NameStep> createState() => _NameStepState();
}

class _NameStepState extends State<_NameStep> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({'displayName': name});
    setState(() => _loading = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What\'s your name?',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('This is how your neighbours will see you.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 32),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'e.g. Anna',
              filled: true,
              fillColor: theme.colorScheme.secondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 1: Profile details ──────────────────────────────────────────────────

class _ProfileDetailsStep extends StatefulWidget {
  final VoidCallback onDone;
  const _ProfileDetailsStep({required this.onDone});

  @override
  State<_ProfileDetailsStep> createState() => _ProfileDetailsStepState();
}

class _ProfileDetailsStepState extends State<_ProfileDetailsStep> {
  final _streetController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _canton;
  String _initials = '?';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadInitials();
  }

  Future<void> _loadInitials() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    final name = doc.data()?['displayName'] as String? ?? '';
    if (name.isEmpty || !mounted) return;
    final parts = name.trim().split(' ');
    setState(() {
      _initials = parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase();
    });
  }

  @override
  void dispose() {
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final street = _streetController.text.trim();
    final houseNumber = _houseNumberController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final city = _cityController.text.trim();
    final phone = _phoneController.text.trim();
    if (street.isEmpty ||
        houseNumber.isEmpty ||
        postalCode.isEmpty ||
        city.isEmpty ||
        _canton == null ||
        phone.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'street': street,
      'houseNumber': houseNumber,
      'postalCode': postalCode,
      'city': city,
      'canton': _canton,
      'phone': phone,
    });
    setState(() => _loading = false);
    widget.onDone();
  }

  InputDecoration _fieldDecoration(BuildContext context, String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: theme.colorScheme.secondary,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your contact details',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Shared with your neighbours so they can reach you.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Center(
            child: AvatarPhotoPicker(
              initials: _initials,
              radius: 36,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _streetController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(context, 'Street'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _houseNumberController,
                  keyboardType: TextInputType.text,
                  decoration: _fieldDecoration(context, 'No.'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _postalCodeController,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(context, 'PLZ'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(context, 'City'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _canton,
            decoration: _fieldDecoration(context, 'Canton'),
            icon: const Icon(LucideIcons.chevronDown),
            items: swissCantons
                .map((c) => DropdownMenuItem(
                      value: c.code,
                      child: Text('${c.code} — ${c.name}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _canton = v),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _fieldDecoration(context, 'Phone number'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Continue'),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─── Step 2: Role ─────────────────────────────────────────────────────────────

class _RoleStep extends StatefulWidget {
  final VoidCallback onDone;
  const _RoleStep({required this.onDone});

  @override
  State<_RoleStep> createState() => _RoleStepState();
}

class _RoleStepState extends State<_RoleStep> {
  String _role = 'resident';
  bool _isResidentAdmin = false;
  bool _loading = false;

  Future<void> _save() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'role': _role,
      if (_role == 'admin') 'isResidentAdmin': _isResidentAdmin,
    });

    setState(() => _loading = false);

    // Admin-only (not a resident): AuthGate detects role and routes to
    // HomePage. No need to advance — the stream handles it automatically.
    if (_role == 'admin' && !_isResidentAdmin) return;

    // Resident or resident-admin: proceed to building step
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How will you use this app?',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('You can change this later in Settings.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 28),
          _RoleCard(
            icon: LucideIcons.house,
            title: 'I\'m a resident',
            subtitle: 'I live in the building and want to book machines',
            selected: _role == 'resident',
            onTap: () => setState(() {
              _role = 'resident';
              _isResidentAdmin = false;
            }),
          ),
          const SizedBox(height: 12),
          _RoleCard(
            icon: LucideIcons.userCog2,
            title: 'I manage building(s)',
            subtitle: 'I\'m responsible for the laundry room',
            selected: _role == 'admin',
            onTap: () => setState(() => _role = 'admin'),
          ),
          if (_role == 'admin') ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () =>
                  setState(() => _isResidentAdmin = !_isResidentAdmin),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isResidentAdmin,
                      onChanged: (v) =>
                          setState(() => _isResidentAdmin = v ?? false),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('I also live in one of these buildings',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                          Text(
                            'You\'ll be able to book machines as a resident too',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.colorScheme.secondary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : (theme.brightness == Brightness.dark
                    ? const Color(0xFF2B3542)
                    : const Color(0xFFE7EEEE)),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.grey.shade500,
                size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? theme.colorScheme.primary
                              : null)),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Building ─────────────────────────────────────────────────────────

class _BuildingStep extends StatefulWidget {
  final VoidCallback onDone;
  const _BuildingStep({required this.onDone});

  @override
  State<_BuildingStep> createState() => _BuildingStepState();
}

class _BuildingStepState extends State<_BuildingStep> {
  bool _loading = false;
  String? _error;
  bool? _isAdminResident; // loaded from Firestore

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) {
      final role = doc.data()?['role'] as String? ?? 'resident';
      final isResidentAdmin =
          doc.data()?['isResidentAdmin'] as bool? ?? false;
      setState(
          () => _isAdminResident = role == 'admin' && isResidentAdmin);
    }
  }

  Future<void> _scanExisting() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (result == null || !mounted) return;

    if (!result.startsWith('building:')) {
      setState(() =>
          _error = 'This doesn\'t look like a building QR. Try again.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final linkedUuid = result.substring('building:'.length);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final updates = <String, dynamic>{'linked_uuid': linkedUuid};
    // Admin-resident scanning an existing building: also add to managed_buildings
    if (_isAdminResident == true) {
      updates['managed_buildings'] = FieldValue.arrayUnion([linkedUuid]);
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update(updates);

    if (mounted) {
      setState(() => _loading = false);
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAdmin = _isAdminResident == true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Join your building',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            isAdmin
                ? 'Create a new building or scan an existing QR.'
                : 'Scan the QR code posted in your laundry room.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),
          if (isAdmin) ...[
            _OptionCard(
              icon: LucideIcons.building2,
              title: 'Create a new building',
              subtitle: 'Set up a building and get its QR code',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateBuildingPage(
                    onCreated: widget.onDone,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _OptionCard(
              icon: LucideIcons.scanLine,
              title: 'Scan existing building QR',
              subtitle: 'Join a building that\'s already set up',
              onTap: _scanExisting,
            ),
          ] else ...[
            Center(
              child: Icon(LucideIcons.scanLine,
                  size: 96, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 32),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(_error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _scanExisting,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(LucideIcons.scanLine),
                label: const Text('Scan QR code'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Step 4: Household ────────────────────────────────────────────────────────

class _HouseholdStep extends StatefulWidget {
  const _HouseholdStep();

  @override
  State<_HouseholdStep> createState() => _HouseholdStepState();
}

class _HouseholdStepState extends State<_HouseholdStep> {
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your household',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Set up who shares the laundry with you.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600)),
          const SizedBox(height: 32),
          if (_creating)
            _CreateHouseholdForm()
          else
            Column(
              children: [
                _OptionCard(
                  icon: LucideIcons.house,
                  title: 'First from my household',
                  subtitle: 'Create a new household and invite others later',
                  onTap: () => setState(() => _creating = true),
                ),
                const SizedBox(height: 12),
                _OptionCard(
                  icon: LucideIcons.userPlus2,
                  title: 'Join an existing household',
                  subtitle:
                      'Scan the invite QR from your household member',
                  onTap: () => _joinFlow(context),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _joinFlow(BuildContext context) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScanPage()),
    );
    if (result == null || !mounted) return;

    if (!result.startsWith('household:')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('This is not a household invite QR.')));
      return;
    }

    try {
      await HouseholdService.join(result.substring('household:'.length));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Icon(icon, color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _CreateHouseholdForm extends StatefulWidget {
  @override
  State<_CreateHouseholdForm> createState() =>
      _CreateHouseholdFormState();
}

class _CreateHouseholdFormState extends State<_CreateHouseholdForm> {
  final _controller = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final linkedUuid =
        doc.data()?['linked_uuid'] as String? ?? '';

    await HouseholdService.create(name, linkedUuid);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Name on your mailbox',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. Müller',
            filled: true,
            fillColor: theme.colorScheme.secondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (_) => _create(),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _loading ? null : _create,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Create household'),
          ),
        ),
      ],
    );
  }
}

// ─── Reusable QR scanner page ─────────────────────────────────────────────────

class QrScanPage extends StatefulWidget {
  final void Function(String code)? onScanned;
  const QrScanPage({super.key, this.onScanned});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'qr_scan');
  QRViewController? _controller;
  bool _scanned = false;

  @override
  void dispose() {
    // ignore: deprecated_member_use
    _controller?.dispose();
    super.dispose();
  }

  void _onViewCreated(QRViewController controller) {
    _controller = controller;
    controller.scannedDataStream.listen((data) {
      if (_scanned) return;
      final code = data.code ?? '';
      if (code.isEmpty) return;
      _scanned = true;
      if (widget.onScanned != null) {
        widget.onScanned!(code);
      } else {
        Navigator.pop(context, code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: Stack(
        children: [
          QRView(key: _qrKey, onQRViewCreated: _onViewCreated),
          Center(
            child: SizedBox(
              width: 250,
              height: 250,
              child: CustomPaint(painter: BracketPainter()),
            ),
          ),
        ],
      ),
    );
  }
}

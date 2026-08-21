import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/components/avatar_photo_picker.dart';
import 'package:lavaplan/constants/swiss_cantons.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameController = TextEditingController();
  final _streetController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _canton;
  bool _loading = false;
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (mounted) {
      final data = doc.data();
      _nameController.text = data?['displayName'] ?? '';
      _streetController.text = data?['street'] ?? '';
      _houseNumberController.text = data?['houseNumber'] ?? '';
      _postalCodeController.text = data?['postalCode'] ?? '';
      _cityController.text = data?['city'] ?? '';
      _canton = data?['canton'] as String?;
      _phoneController.text = data?['phone'] ?? '';
      setState(() => _initialLoading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final street = _streetController.text.trim();
    final houseNumber = _houseNumberController.text.trim();
    final postalCode = _postalCodeController.text.trim();
    final city = _cityController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'displayName': name,
      'street': street,
      'houseNumber': houseNumber,
      'postalCode': postalCode,
      'city': city,
      'canton': _canton,
      'phone': phone,
    });
    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  String get _initials {
    final name = _nameController.text.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return (name.length >= 2 ? name.substring(0, 2) : name).toUpperCase();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit profile'),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: AvatarPhotoPicker(initials: _initials, radius: 40),
                ),
                const SizedBox(height: 32),
                Text('Display name',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: _fieldDecoration(context, 'Your first name'),
                ),
                const SizedBox(height: 8),
                Text(
                  'This is shown to your neighbours in the app.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                Text('Address',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _streetController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _fieldDecoration(context, 'Street'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _houseNumberController,
                        decoration: _fieldDecoration(context, 'No.'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 24),
                Text('Phone number',
                    style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.grey.shade600,
                        letterSpacing: 1.2)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration(context, 'Phone number'),
                ),
              ],
            ),
    );
  }
}

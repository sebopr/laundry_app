import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A circular initials avatar with a camera badge, standing in for a real
/// profile photo until upload is implemented. Tapping it says so rather
/// than doing nothing.
class AvatarPhotoPicker extends StatelessWidget {
  final String initials;
  final double radius;

  const AvatarPhotoPicker({
    super.key,
    required this.initials,
    this.radius = 40,
  });

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile photos are coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => _showComingSoon(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: theme.colorScheme.primary,
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: radius * 0.55,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 2,
                ),
              ),
              child: Icon(
                LucideIcons.camera,
                size: radius * 0.38,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

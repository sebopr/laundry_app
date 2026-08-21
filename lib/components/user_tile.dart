import 'package:flutter/material.dart';
import 'package:lavaplan/components/chat_icon_badge.dart';
import 'package:lavaplan/services/auth/auth_service.dart';
import 'package:lavaplan/services/chat/chat_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class UserTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  final ChatIconBadge leading;

//chat and auth services
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  UserTile({
    super.key,
    required this.text,
    required this.onTap,
    required this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            //Icon
            leading,
            const Icon(LucideIcons.user),

            //User name
            Text(text)
          ],
        ),
      ),
    );
  }
}

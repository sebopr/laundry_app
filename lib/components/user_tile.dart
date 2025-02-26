import 'package:flutter/material.dart';
import 'package:laundry_app/services/auth/auth_service.dart';
import 'package:laundry_app/services/chat/chat_service.dart';
import 'package:badges/badges.dart' as badges;

class UserTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;
//chat and auth services
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  //final int unreadMessages;
  final String receiverId;

  UserTile({
    super.key,
    required this.text,
    required this.onTap,
    required this.receiverId,
    // required this.unreadMessages,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(children: [
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              //Badge for unread messages

              _buildBadge(),

              //Icon or user picture later on
              const Icon(Icons.person),

              //User name
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(text),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildBadge() {
    return StreamBuilder<int>(
      stream: _chatService.getUnreadCount(
        _authService.getCurrentUser()!.uid,
        receiverId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == 0) {
          return const SizedBox(); // No unread messages
        }
        return badges.Badge(
          badgeContent: Text(
            snapshot.data?.toString() ?? '0',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        );
      },
    );
  }
}

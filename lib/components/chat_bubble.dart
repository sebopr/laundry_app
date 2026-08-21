import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lavaplan/themes/theme_provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isCurrentUser;
  final DateTime time;
  final bool isRead;
  final bool isLastInGroup;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    required this.time,
    this.isRead = false,
    this.isLastInGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkmode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    const fullRadius = Radius.circular(18);
    const tailRadius = Radius.circular(4);

    final borderRadius = BorderRadius.only(
      topLeft: fullRadius,
      topRight: fullRadius,
      bottomLeft: isCurrentUser || !isLastInGroup ? fullRadius : tailRadius,
      bottomRight: !isCurrentUser || !isLastInGroup ? fullRadius : tailRadius,
    );

    return Column(
      crossAxisAlignment:
          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: isCurrentUser
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF22C6C6), Color(0xFF12A3A8)],
                  )
                : null,
            color: isCurrentUser
                ? null
                : (isDarkmode ? theme.colorScheme.secondary : Colors.white),
            borderRadius: borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkmode ? 0.25 : 0.06),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            message,
            style: TextStyle(
              color: isCurrentUser
                  ? Colors.white
                  : (isDarkmode ? Colors.white : Colors.black87),
              fontSize: 15.5,
              height: 1.3,
            ),
          ),
        ),
        if (isLastInGroup)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('h:mm a').format(time),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkmode ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isRead ? LucideIcons.checkCheck : LucideIcons.check,
                    size: 14,
                    color: isRead
                        ? theme.colorScheme.primary
                        : (isDarkmode
                            ? Colors.grey.shade400
                            : Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

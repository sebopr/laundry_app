import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;

class UserTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  //final int unreadMessages;

  const UserTile({
    super.key,
    required this.text,
    required this.onTap,
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
              const badges.Badge(
                badgeContent: Text(
                  "1",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),

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
}

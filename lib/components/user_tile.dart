import 'package:flutter/material.dart';

class UserTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  final bool hasNewMessage;

  const UserTile({
    super.key,
    required this.text,
    required this.onTap,
    required this.hasNewMessage,
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
              if (hasNewMessage)
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color.fromARGB(255, 19, 18, 18),
                            width: 1),
                      ),
                    ),
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

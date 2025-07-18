import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laundry_app/components/my_drawer.dart';
import 'package:laundry_app/components/user_tile.dart';
import 'package:laundry_app/services/chat/chat_service.dart';
import 'package:laundry_app/pages/chat_page.dart';
import 'package:laundry_app/components/chat_icon_badge.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ChatService _chatService = ChatService();
  // final AuthService _authService = AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getCurrentUser()!.email ?? "No Email"),
        centerTitle: true,
      ),
      drawer: const MyDrawer(),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
        stream: _chatService.getUsersStream(),
        builder: (context, snapshot) {
          //error
          if (snapshot.hasError) {
            return const Text("Error");
          }
          //loading...

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading ...");
          }

          //return listview

          return ListView(
            children: snapshot.data!
                .map<Widget>(
                    (userData) => _buildeUserListItem(userData, context))
                .toList(),
          );
        });
  }

  Widget _buildeUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    final currentUser = getCurrentUser()!;
    final otherUserId = userData["uid"];
    final otherUserEmail = userData["email"];

    if (otherUserEmail == currentUser.email) return Container(); // skip self

    return StreamBuilder<int>(
      stream: ChatService().getUnreadCount(currentUser.uid, otherUserId),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;

        return UserTile(
          leading: ChatIconBadge(unreadCount: unread),
          text: userData["email"],
          onTap: () {
            // tapped on user > go to chat page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  receiverEmail: userData["email"],
                  receiverId: userData["uid"],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // Return an empty SizedBox if the user is the current user
}

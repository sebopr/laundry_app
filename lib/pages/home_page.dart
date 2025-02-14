import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:laundry_app/components/my_drawer.dart';
import 'package:laundry_app/components/user_tile.dart';
import 'package:laundry_app/services/chat/chat_service.dart';
import 'package:laundry_app/pages/chat_page.dart';

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
        title: const Text("Home Screen"),
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
    if (userData["email"] != getCurrentUser()!.email) {
      return UserTile(
          text: userData["email"],
          unreadMessages: int.parse(userData["unreadMessages"]),
          onTap: () {
            // tapped on use > go to chat page
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverEmail: userData["email"],
                    receiverId: userData["uid"],
                  ),
                ));
          });
    } else {
      return Container();
    }
  }
}

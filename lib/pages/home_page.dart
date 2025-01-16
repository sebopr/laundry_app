import 'package:flutter/material.dart';
import 'package:laundry_app/components/my_drawer.dart';
import 'package:laundry_app/services/auth/auth_service.dart';
import 'package:laundry_app/services/chat/chat_service.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Screen"),
      ),
      drawer: const MyDrawer(),
      body: _buildUserList(),
    );
  }

  //build userlist except it should not contain the logged in user
  Widget _buildeUserList() {
    return StreamBuilder(
      stream: _chatService.getUsersStream(),
      builder: (context, snapshot) {
        //error
        if (snapshot.hasError) {
          return const Text("Error");
        }
        //loadin

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading ...");
        }
        //return listview
      },
    );
  }
}

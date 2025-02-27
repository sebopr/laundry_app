import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:laundry_app/components/chat_bubble.dart';
import 'package:laundry_app/components/my_textfield.dart';
import 'package:laundry_app/services/auth/auth_service.dart';
import 'package:laundry_app/services/chat/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverId;

  const ChatPage(
      {super.key, required this.receiverEmail, required this.receiverId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
//text controller
  final TextEditingController _messageController = TextEditingController();

//chat and auth services
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

//for textfield focusing

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
//add listener to focus node
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), () => _scrollDown());
      }
    });

//wait for the ist to be built, and then scroll down
    resetUnreadCount();
    Future.delayed(const Duration(milliseconds: 500), () => _scrollDown());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    resetUnreadCount();
    super.dispose();
  }
//scroll controller

  final ScrollController _scrollController = ScrollController();
  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );
  }

  void resetUnreadCount() async {
    await _chatService.resetUnreadCount(
        _authService.getCurrentUser()!.uid, widget.receiverId);
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
          widget.receiverId, _messageController.text);
    }

    _messageController.clear();
  }

  Stream<QuerySnapshot> receiveMessages() {
    return _chatService.getMessages(
        _authService.getCurrentUser()!.uid, widget.receiverId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(widget.receiverEmail),
        ),
        body: Column(
          children: [
            //display the messages
            Expanded(child: _buildMessagesList()),
            //display the send field and button
            _buildMessageInput(),
          ],
        ));
  }

  Widget _buildMessagesList() {
    return StreamBuilder(
      stream: receiveMessages(),
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
          controller: _scrollController,
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser = data["senderId"] == _authService.getCurrentUser()!.uid;

    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
        alignment: alignment,
        child: Column(
          crossAxisAlignment:
              isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            ChatBubble(message: data["message"], isCurrentUser: isCurrentUser)
          ],
        ));
  }

  //message input
  Widget _buildMessageInput() {
    return Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: Row(
          children: [
            Expanded(
              child: MyTextField(
                controller: _messageController,
                hintText: "Type your message",
                obscureText: false,
                focusNode: _focusNode,
              ),
            ),
            //send button
            Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                margin: const EdgeInsets.only(right: 25),
                child: IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.arrow_upward),
                ))
          ],
        ));
  }
}

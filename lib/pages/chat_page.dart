import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lavaplan/components/chat_bubble.dart';
import 'package:lavaplan/components/my_textfield.dart';
import 'package:lavaplan/components/typing_indicator.dart';
import 'package:lavaplan/services/auth/auth_service.dart';
import 'package:lavaplan/services/chat/chat_service.dart';

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
  Timer? _typingTimer;

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
      _scrollDown();
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
          // 👇 Typing Indicator
          StreamBuilder<bool>(
            stream: _chatService.isOtherUserTyping(
              _authService.getCurrentUser()!.uid,
              widget.receiverId,
            ),
            builder: (context, snapshot) {
              final isTyping = snapshot.hasData && snapshot.data!;
              return AnimatedOpacity(
                opacity: isTyping ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const TypingIndicator(),
                        const SizedBox(width: 8),
                        Text(
                          "${widget.receiverEmail} is typing...",
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 👇 Messages List
          Expanded(child: _buildMessagesList()),

          // 👇 Input Field
          _buildMessageInput(),
        ],
      ),
    );
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
        // scroll after messages are updated
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());
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
                onChanged: (value) {
                  _chatService.setTypingStatus(
                      //set is typing
                      widget.receiverId,
                      value.isNotEmpty);
                  // reset is typing after 1 second of inactivity
                  _typingTimer?.cancel();
                  if (value.isNotEmpty) {
                    _typingTimer = Timer(const Duration(seconds: 2), () {
                      _chatService.setTypingStatus(widget.receiverId, false);
                    });
                  }
                },
                onSubmitted: (value) async {
                  await _chatService.sendMessage(widget.receiverId, value);
                  await _chatService.setTypingStatus(
                      widget.receiverId, false); // stop typing
                },
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

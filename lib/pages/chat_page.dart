import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lavaplan/components/chat_bubble.dart';
import 'package:lavaplan/components/nudge_picker.dart';
import 'package:lavaplan/components/typing_indicator.dart';
import 'package:lavaplan/l10n/app_localizations.dart';
import 'package:lavaplan/models/nudge.dart';
import 'package:lavaplan/services/auth/auth_service.dart';
import 'package:lavaplan/services/chat/chat_service.dart';
import 'package:lavaplan/services/notifications/active_chat_tracker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiverId;
  final String? receiverName;

  const ChatPage({
    super.key,
    required this.receiverEmail,
    required this.receiverId,
    this.receiverName,
  });

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

  String get _displayName => widget.receiverName ?? widget.receiverEmail;

  String get _initials {
    final parts = _displayName.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return (_displayName.length >= 2
            ? _displayName.substring(0, 2)
            : _displayName)
        .toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    ActiveChatTracker.currentPeerId = widget.receiverId;
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
    if (ActiveChatTracker.currentPeerId == widget.receiverId) {
      ActiveChatTracker.currentPeerId = null;
    }
    _focusNode.dispose();
    _messageController.dispose();
    resetUnreadCount();
    super.dispose();
  }
//scroll controller

  final ScrollController _scrollController = ScrollController();
  void _scrollDown() {
    if (!_scrollController.hasClients) return;
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
      try {
        await _chatService.sendMessage(
            widget.receiverId, _messageController.text);
        _scrollDown();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
    }

    _messageController.clear();
  }

  void _sendNudge(Nudge nudge) async {
    final l10n = AppLocalizations.of(context)!;
    await _chatService.sendNudge(
        widget.receiverId, nudge.id, nudge.message(l10n));
    _scrollDown();
  }

  Stream<QuerySnapshot> receiveMessages() {
    return _chatService.getMessages(
        _authService.getCurrentUser()!.uid, widget.receiverId);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
              child: Text(
                _initials,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _displayName,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 👇 Messages List
          Expanded(
            child: Stack(
              children: [
                _buildMessagesList(),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: NudgePicker(onSelected: _sendNudge),
                ),
              ],
            ),
          ),

          // 👇 Typing Indicator
          StreamBuilder<bool>(
            stream: _chatService.isOtherUserTyping(
              _authService.getCurrentUser()!.uid,
              widget.receiverId,
            ),
            builder: (context, snapshot) {
              final isTyping = snapshot.hasData && snapshot.data!;
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isTyping
                    ? Padding(
                        key: const ValueKey('typing'),
                        padding:
                            const EdgeInsets.only(left: 12, bottom: 8, top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              radius: 13,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              child: Text(
                                _initials,
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(18),
                                  topRight: Radius.circular(18),
                                  bottomRight: Radius.circular(18),
                                  bottomLeft: Radius.circular(4),
                                ),
                              ),
                              child: const TypingIndicator(),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('not-typing')),
              );
            },
          ),

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
        final l10n = AppLocalizations.of(context)!;
        //error
        if (snapshot.hasError) {
          return Center(child: Text(l10n.somethingWentWrong));
        }
        //loading...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              l10n.sayHelloTo(_displayName),
              style: TextStyle(color: Colors.grey.shade500),
            ),
          );
        }

        // scroll after messages are updated
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollDown());

        // mark newly-arrived messages from the other user as read while
        // the chat page is already open, not just when it's first opened
        final currentUserId = _authService.getCurrentUser()!.uid;
        final hasUnread = docs.any((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data["receiverId"] == currentUserId && data["isRead"] == false;
        });
        if (hasUnread) resetUnreadCount();

        return ListView(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          children: _buildMessageWidgets(context, docs),
        );
      },
    );
  }

  List<Widget> _buildMessageWidgets(
      BuildContext context, List<QueryDocumentSnapshot> docs) {
    final theme = Theme.of(context);
    final currentUserId = _authService.getCurrentUser()!.uid;
    final maxBubbleWidth = MediaQuery.of(context).size.width * 0.72;

    final widgets = <Widget>[];
    List<Widget> groupBubbles = [];
    bool groupIsMine = false;

    void flushGroup() {
      if (groupBubbles.isEmpty) return;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment:
                groupIsMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!groupIsMine) ...[
                CircleAvatar(
                  radius: 13,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.15),
                  child: Text(
                    _initials,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxBubbleWidth),
                child: Column(
                  crossAxisAlignment: groupIsMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: List.of(groupBubbles),
                ),
              ),
            ],
          ),
        ),
      );
      groupBubbles = [];
    }

    DateTime? lastDate;
    String? lastSenderId;

    for (var i = 0; i < docs.length; i++) {
      final data = docs[i].data() as Map<String, dynamic>;
      final senderId = data["senderId"] as String;
      final isMine = senderId == currentUserId;
      final timestamp = (data["timestamp"] as Timestamp).toDate();

      final isNewDay = lastDate == null || !_isSameDay(lastDate, timestamp);
      if (isNewDay) {
        flushGroup();
        widgets.add(_DayDivider(date: timestamp));
        lastSenderId = null;
      }

      if (lastSenderId != senderId) {
        flushGroup();
        groupIsMine = isMine;
      }

      bool isLastInGroup = true;
      if (i < docs.length - 1) {
        final nextData = docs[i + 1].data() as Map<String, dynamic>;
        final nextTimestamp = (nextData["timestamp"] as Timestamp).toDate();
        isLastInGroup = nextData["senderId"] != senderId ||
            !_isSameDay(timestamp, nextTimestamp);
      }

      groupBubbles.add(
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: ChatBubble(
            message: data["message"] as String,
            isCurrentUser: isMine,
            time: timestamp,
            isRead: data["isRead"] as bool? ?? false,
            isLastInGroup: isLastInGroup,
            nudgeId: data["nudgeId"] as String?,
          ),
        ),
      );

      lastDate = timestamp;
      lastSenderId = senderId;
    }

    flushGroup();
    return widgets;
  }

  //message input
  Widget _buildMessageInput() {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: l10n.messageHint(_displayName),
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                  ),
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
                    if (value.trim().isEmpty) return;
                    try {
                      await _chatService.sendMessage(widget.receiverId, value);
                      _scrollDown();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    }
                    await _chatService.setTypingStatus(
                        widget.receiverId, false); // stop typing
                    _messageController.clear();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            //send button
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF22C6C6), Color(0xFF12A3A8)],
                ),
              ),
              child: IconButton(
                padding: EdgeInsets.zero,
                onPressed: sendMessage,
                icon: const Icon(LucideIcons.arrowUp,
                    color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  final DateTime date;

  const _DayDivider({required this.date});

  String _label(AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(date.year, date.month, date.day);

    if (day == today) return l10n.todayBtn;
    if (day == yesterday) return l10n.yesterdayLabel;
    if (date.year == now.year) return DateFormat('MMMM d').format(date);
    return DateFormat('MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            _label(AppLocalizations.of(context)!),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ),
      ),
    );
  }
}

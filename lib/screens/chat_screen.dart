import 'dart:async';

import 'package:flutter/material.dart';
import 'package:travelcompanionfinder/screens/detail_profile_page.dart';
import 'package:intl/intl.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String chatId; // Unique identifier for the chat conversation

  const ChatScreen({Key? key, required this.user, required this.chatId})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  late DatabaseReference _messagesRef;
  late User? _currentUser;
  late StreamSubscription<DatabaseEvent> _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _initializeFirebase();
  }

  void _initializeFirebase() {
    // Initialize database reference
    _messagesRef =
        FirebaseDatabase.instance.ref('chats/${widget.chatId}/messages');

    // Listen for new messages
    _messagesSubscription = _messagesRef
        .orderByChild('timestamp')
        .onChildAdded
        .listen(_onNewMessage);

    // Load existing messages
    _loadInitialMessages();
  }

  void _loadInitialMessages() async {
    try {
      final snapshot = await _messagesRef.orderByChild('timestamp').once();
      if (snapshot.snapshot.value != null) {
        final messagesMap = snapshot.snapshot.value as Map<dynamic, dynamic>;
        final messagesList = messagesMap.entries.map((entry) {
          return {
            'id': entry.key,
            'text': entry.value['text'],
            'senderId': entry.value['senderId'],
            'timestamp': entry.value['timestamp'],
            'isMe': entry.value['senderId'] == _currentUser?.uid,
            'time':
                DateTime.fromMillisecondsSinceEpoch(entry.value['timestamp']),
          };
        }).toList();

        // Sort by timestamp (oldest first)
        messagesList.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

        setState(() {
          _messages.addAll(messagesList);
        });

        // Scroll to bottom
        _scrollToBottom();
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  void _onNewMessage(DatabaseEvent event) {
    final newMessage = {
      'id': event.snapshot.key,
      'text': event.snapshot.child('text').value,
      'senderId': event.snapshot.child('senderId').value,
      'timestamp': event.snapshot.child('timestamp').value,
      'isMe': event.snapshot.child('senderId').value == _currentUser?.uid,
      'time': DateTime.fromMillisecondsSinceEpoch(
          event.snapshot.child('timestamp').value as int),
    };

    // Check if message already exists to avoid duplicates
    if (!_messages.any((msg) => msg['id'] == newMessage['id'])) {
      setState(() {
        _messages.add(newMessage);
      });

      // Scroll to bottom for new messages
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageText = _messageController.text.trim();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      // Push new message to Firebase
      final newMessageRef = _messagesRef.push();
      await newMessageRef.set({
        'text': messageText,
        'senderId': _currentUser?.uid,
        'timestamp': timestamp,
        'status': 'sent',
      });

      // Clear input field
      _messageController.clear();
      setState(() => _isTyping = false);
    } catch (e) {
      print('Error sending message: $e');
      // Optionally show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  @override
  void dispose() {
    _messagesSubscription.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailProfilePage(
                  userId: widget.user['userId'].toString(),
                ),
              ),
            );
          },
          child: Row(
            children: [
              Hero(
                tag: 'profile-${widget.user['userId']}',
                child: CircleAvatar(
                  backgroundImage: widget.user['image'] != null
                      ? NetworkImage(widget.user['image'])
                      : null,
                  backgroundColor: Colors.grey[300],
                  child: widget.user['image'] == null
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user['name'] ?? "User",
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    _isTyping ? 'typing...' : 'online',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isTyping ? Colors.green : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(icon: Icon(Icons.videocam), onPressed: () {}),
          IconButton(icon: Icon(Icons.call), onPressed: () {}),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(child: Text("View profile")),
              PopupMenuItem(child: Text("Media")),
              PopupMenuItem(child: Text("Search")),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/chat_bg.png'),
                  fit: BoxFit.cover,
                  opacity: 0.05,
                ),
              ),
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(top: 10, bottom: 10),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final time = DateFormat('h:mm a').format(message['time']);

                  return Column(
                    children: [
                      // Date divider if needed
                      if (index == 0 ||
                          _messages[index - 1]['time'].day !=
                              message['time'].day)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              DateFormat('MMM d, y').format(message['time']),
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),

                      // Message bubble
                      Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          mainAxisAlignment: message['isMe']
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            if (!message['isMe']) ...[
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: widget.user['image'] != null
                                    ? NetworkImage(widget.user['image'])
                                    : null,
                                backgroundColor: Colors.grey[300],
                              ),
                              SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: message['isMe']
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(18),
                                    topRight: Radius.circular(18),
                                    bottomLeft: message['isMe']
                                        ? Radius.circular(18)
                                        : Radius.circular(2),
                                    bottomRight: message['isMe']
                                        ? Radius.circular(2)
                                        : Radius.circular(18),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: message['isMe']
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['text'],
                                      style: TextStyle(
                                        color: message['isMe']
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          time,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: message['isMe']
                                                ? Colors.white70
                                                : Colors.grey[600],
                                          ),
                                        ),
                                        if (message['isMe']) ...[
                                          SizedBox(width: 4),
                                          Icon(
                                            message['status'] == 'read'
                                                ? Icons.done_all
                                                : Icons.done,
                                            size: 14,
                                            color: message['status'] == 'read'
                                                ? Colors.blue[200]
                                                : Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.add, color: Colors.grey[600]),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: (text) {
                      setState(() => _isTyping = text.isNotEmpty);
                    },
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.emoji_emotions_outlined,
                                color: Colors.grey[600]),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.attach_file,
                                color: Colors.grey[600]),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: Icon(_isTyping ? Icons.send : Icons.mic,
                        color: Colors.white),
                    onPressed: _isTyping ? _sendMessage : () {},
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

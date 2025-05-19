import 'package:chat/views/services/message_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/message_model.dart';
import '../providers/message_provider.dart';

class ChatPage extends ConsumerStatefulWidget {
  final String userName;
  final String phoneNumber; // The recipient's phone number
  final String currentUserId; // The current user's ID

  const ChatPage({
    required this.userName,
    required this.phoneNumber,
    required this.currentUserId,
    Key? key,
  }) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch initial messages
    ref.read(messageServiceProvider).getMessages(widget.currentUserId, widget.phoneNumber).then((messages) {
      print('Initial messages loaded: ${messages.length}'); // Debug print
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsyncValue = ref.watch(messagesProvider(MessageQuery(widget.currentUserId, widget.phoneNumber)));

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            // Navigate to view profile screen
            Navigator.pushNamed(
              context,
              "/view_profile",
              arguments: {'userId': widget.phoneNumber},
            );
          },
          child: Row(
            children: [
              Text(widget.userName),
              SizedBox(width: 4),
              Icon(Icons.info_outline, size: 16),
            ],
          ),
        ),
        backgroundColor: Colors.teal[800],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsyncValue.when(
              data: (messages) {
                print('Messages to display: ${messages.length}'); // Debug print
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isCurrentUser = message.senderId == widget.currentUserId;

                    return Align(
                      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.pink[200] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message.content,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    if (_messageController.text.isNotEmpty) {
                      ref.read(messageServiceProvider).sendMessage(
                        currentUserId: widget.currentUserId,
                        recipientPhoneNumber: widget.phoneNumber,
                        content: _messageController.text,
                      );
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

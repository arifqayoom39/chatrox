import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/constants/group_chat_message.dart';
import 'package:chat/constants/memberCalculate.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/models/group_message_model.dart';
import 'package:chat/models/group_model.dart';
import 'package:chat/models/user_data.dart';
import 'package:chat/providers/group_message_provider.dart';
import 'package:chat/providers/user_data_provider.dart';
import 'package:chat/views/chat_page.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class GroupChatPage extends StatefulWidget {
  const GroupChatPage({super.key});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> with TickerProviderStateMixin {
  TextEditingController _messageController = TextEditingController();
  TextEditingController _editMessageController = TextEditingController();
  ScrollController _scrollController = ScrollController();
  
  late String currentUser;
  late String currentUserName;

  FilePickerResult? _filePickerResult;
  
  // For reply functionality
  GroupMessageModel? replyingTo;

  // For reactions
  final List<String> reactions = ["❤️", "👍", "👎", "😂", "😮", "😢", "🎉"];
  
  // Animation controllers
  late AnimationController _typingController;
  bool _isAttachmentMenuOpen = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    
    // Get user data
    currentUser = Provider.of<UserDataProvider>(context, listen: false).getUserId;
    currentUserName = Provider.of<UserDataProvider>(context, listen: false).getUserName;
    
    // Scroll to bottom after frame is rendered - more reliable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom(animate: false);
    });
  }

  // Function to scroll to bottom of chat
  void scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.minScrollExtent;
      if (animate) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _editMessageController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  // to open file picker
  void _openFilePicker(GroupModel groupData) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: true, type: FileType.image);

    setState(() {
      _filePickerResult = result;
      uploadAllImage(groupData);
    });
  }

  // to open video picker
  void _openVideoPicker(GroupModel groupData) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.video);

    if (result != null) {
      var path = result.files.single.path;
      if (path != null) {
        var file = File(path);
        final fileBytes = file.readAsBytesSync();
        final inputfile = InputFile.fromBytes(
            bytes: fileBytes, filename: file.path.split("/").last);

        // Show loading indicator
        _showUploadingDialog("video");
        
        // Upload video
        saveVideoToBucket(video: inputfile).then((videoId) {
          Navigator.pop(context); // Dismiss loading dialog
          if (videoId != null) {
            sendGroupMessage(
              groupId: groupData.groupId,
              message: videoId,
              senderId: currentUser,
              isVideo: true,
            );
            
            // Send notifications
            List<String> userTokens = [];
            for (var i = 0; i < groupData.userData.length; i++) {
              if (groupData.userData[i].userId != currentUser) {
                userTokens.add(groupData.userData[i].deviceToken ?? "");
              }
            }
            
            sendMultipleNotificationtoOtherUser(
              notificationTitle: "Received a video in ${groupData.groupName}",
              notificationBody: '${currentUserName}: Sent a video',
              deviceToken: userTokens
            );
          } else {
            _showErrorSnackbar("Failed to upload video");
          }
        });
      }
    }
  }

  // to open audio picker
  void _openAudioPicker(GroupModel groupData) async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(allowMultiple: false, type: FileType.audio);

    if (result != null) {
      var path = result.files.single.path;
      if (path != null) {
        var file = File(path);
        final fileBytes = file.readAsBytesSync();
        final inputfile = InputFile.fromBytes(
            bytes: fileBytes, filename: file.path.split("/").last);

        // Show loading indicator
        _showUploadingDialog("audio");
        
        // Upload audio
        saveAudioToBucket(audio: inputfile).then((audioId) {
          Navigator.pop(context); // Dismiss loading dialog
          if (audioId != null) {
            sendGroupMessage(
              groupId: groupData.groupId,
              message: audioId,
              senderId: currentUser,
              isAudio: true,
            );
            
            // Send notifications
            List<String> userTokens = [];
            for (var i = 0; i < groupData.userData.length; i++) {
              if (groupData.userData[i].userId != currentUser) {
                userTokens.add(groupData.userData[i].deviceToken ?? "");
              }
            }
            
            sendMultipleNotificationtoOtherUser(
              notificationTitle: "Received an audio in ${groupData.groupName}",
              notificationBody: '${currentUserName}: Sent an audio message',
              deviceToken: userTokens
            );
          } else {
            _showErrorSnackbar("Failed to upload audio");
          }
        });
      }
    }
  }

  void _showUploadingDialog(String mediaType) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: kPrimaryColor),
              const SizedBox(height: 16),
              Text(
                "Uploading your $mediaType...",
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Please wait",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
        elevation: 0,
      ),
    );
  }

  // to upload files to our storage bucket and our database
  void uploadAllImage(GroupModel groupData) async {
    if (_filePickerResult != null) {
      // Show loading indicator
      _showUploadingDialog("image");
      
      List<Future> futures = [];
      
      _filePickerResult!.paths.forEach((path) {
        if (path != null) {
          var file = File(path);
          final fileBytes = file.readAsBytesSync();
          final inputfile = InputFile.fromBytes(
              bytes: fileBytes, filename: file.path.split("/").last);

          // Create a future for each image upload
          futures.add(saveImageToBucket(image: inputfile).then((imageId) {
            if (imageId != null) {
              sendGroupMessage(
                groupId: groupData.groupId,
                message: imageId,
                senderId: currentUser,
                isImage: true,
              );
              return true;
            }
            return false;
          }));
        }
      });
      
      // Wait for all uploads to complete
      await Future.wait(futures);
      
      // Send notifications
      List<String> userTokens = [];
      for (var i = 0; i < groupData.userData.length; i++) {
        if (groupData.userData[i].userId != currentUser) {
          userTokens.add(groupData.userData[i].deviceToken ?? "");
        }
      }
      
      sendMultipleNotificationtoOtherUser(
        notificationTitle: "Received images in ${groupData.groupName}", 
        notificationBody: '${currentUserName}: Sent images', 
        deviceToken: userTokens
      );
      
      // Dismiss loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      print("file pick cancelled by user");
    }
  }

  void _sendGroupMessage({
    required GroupModel groupData,
    String? message,
    bool isImage = false,
    bool isAudio = false,
    bool isVideo = false,
  }) async {
    final msg = message ?? _messageController.text.trim();
    
    if (msg.isNotEmpty) {
      await sendGroupMessage(
        groupId: groupData.groupId,
        message: msg,
        senderId: currentUser,
        isImage: isImage,
        isAudio: isAudio,
        isVideo: isVideo,
        replyMessage: replyingTo?.message,
        replySender: replyingTo?.userData[0].name,
        replyMessageId: replyingTo?.messageId,
      ).then((value) {
        if (value) {
          // Add message to provider
          Provider.of<GroupMessageProvider>(context, listen: false).addGroupMessage(
            groupId: groupData.groupId,
            msg: GroupMessageModel(
              messageId: "",
              groupId: groupData.groupId,
              message: msg,
              senderId: currentUser,
              timestamp: DateTime.now(),
              userData: [UserData(name: currentUserName, userId: currentUser, phone: '')],
              isImage: isImage,
              isAudio: isAudio,
              isVideo: isVideo,
              replyMessage: replyingTo?.message,
              replySender: replyingTo?.userData[0].name,
              replyMessageId: replyingTo?.messageId,
            ),
          );
          
          // Send notifications
          List<String> userTokens = [];
          for (var i = 0; i < groupData.userData.length; i++) {
            if (groupData.userData[i].userId != currentUser) {
              userTokens.add(groupData.userData[i].deviceToken ?? "");
            }
          }
          
          sendMultipleNotificationtoOtherUser(
            notificationTitle: "Received a message in ${groupData.groupName}",
            notificationBody: '${currentUserName}: ${isImage ? "Sent an image" : isAudio ? "Sent an audio message" : isVideo ? "Sent a video message" : msg}',
            deviceToken: userTokens
          );
          
          _messageController.clear();
          
          // Reset reply state
          setState(() {
            replyingTo = null;
          });
          
          // Improved scrolling after sending message
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToBottom();
          });
        }
      });
    }
  }

  // Add reaction to message
  void _addReaction(GroupMessageModel msg, String reaction) {
    // Use the provider to add the reaction
    Provider.of<GroupMessageProvider>(context, listen: false).addReaction(
      groupId: msg.groupId,
      messageId: msg.messageId,
      reaction: reaction,
    ).then((success) {
      if (success) {
        // Successfully added reaction
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reaction added"),
            duration: Duration(seconds: 1),
            backgroundColor: kPrimaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Show error message if reaction failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to add reaction"),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  // Show reaction picker
  void _showReactionPicker(GroupMessageModel msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                "React to message",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: reactions.map((reaction) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _addReaction(msg, reaction);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        reaction,
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Show full screen image
  void _showFullScreenImage(String imageId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(imageId: imageId),
      ),
    );
  }

  // Show video player
  void _showVideoPlayer(String videoId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenVideoPlayer(videoId: videoId),
      ),
    );
  }

  // Show audio player
  void _showAudioPlayer(String audioId, String senderName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenAudioPlayer(
          audioId: audioId,
          senderName: senderName,
        ),
      ),
    );
  }
  
  // Show message options dialog
  void _showMessageOptions(GroupMessageModel msg, GroupModel groupData) {
    final bool isAdmin = groupData.admin == currentUser;
    final bool isMessageSender = msg.senderId == currentUser;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (isMessageSender || isAdmin)
              ListTile(
                leading: const Icon(Icons.edit, color: kPrimaryColor),
                title: const Text("Edit message"),
                onTap: () {
                  Navigator.pop(context);
                  if (msg.isImage != true && msg.isVideo != true && msg.isAudio != true) {
                    _showEditDialog(msg);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Cannot edit media messages"))
                    );
                  }
                },
              ),
            if (isMessageSender || isAdmin)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red.shade600),
                title: const Text("Delete message"),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(msg);
                },
              ),
            ListTile(
              leading: const Icon(Icons.reply, color: kPrimaryColor),
              title: const Text("Reply"),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  replyingTo = msg;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions, color: kPrimaryColor),
              title: const Text("React"),
              onTap: () {
                Navigator.pop(context);
                _showReactionPicker(msg);
              },
            ),
            if (msg.isImage == false && msg.isVideo == false && msg.isAudio == false)
              ListTile(
                leading: const Icon(Icons.content_copy, color: kPrimaryColor),
                title: const Text("Copy text"),
                onTap: () {
                  Navigator.pop(context);
                  // Copy text functionality
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  void _showEditDialog(GroupMessageModel msg) {
    _editMessageController.text = msg.message;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Edit message"),
        content: TextField(
          controller: _editMessageController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: "Edit your message...",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimaryColor, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              updateGroupMessage(
                messageId: msg.messageId,
                newMessage: _editMessageController.text,
              ).then((_) {
                Provider.of<GroupMessageProvider>(context, listen: false).loadAllGroupData(currentUser);
                Navigator.pop(context);
                _editMessageController.text = "";
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
  
  void _showDeleteConfirmation(GroupMessageModel msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete message?"),
        content: const Text("This message will be permanently deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade700)),
          ),
          ElevatedButton(
            onPressed: () {
              deleteGroupMessage(messageId: msg.messageId).then((_) {
                Provider.of<GroupMessageProvider>(context, listen: false).loadAllGroupData(currentUser);
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: kPrimaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Replying to ${replyingTo!.senderId == currentUser ? 'yourself' : replyingTo!.userData[0].name ?? 'user'}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: kPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  replyingTo!.message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey.shade600),
            onPressed: () {
              setState(() {
                replyingTo = null;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageInputArea(GroupModel groupData) {
    return Column(
      children: [
        if (_isAttachmentMenuOpen)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.grey.shade100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _attachmentButton(
                  icon: Icons.image,
                  color: Colors.purple,
                  label: "Image",
                  onTap: () {
                    setState(() {
                      _isAttachmentMenuOpen = false;
                    });
                    _openFilePicker(groupData);
                  },
                ),
                _attachmentButton(
                  icon: Icons.audiotrack,
                  color: Colors.orange,
                  label: "Audio",
                  onTap: () {
                    setState(() {
                      _isAttachmentMenuOpen = false;
                    });
                    _openAudioPicker(groupData);
                  },
                ),
                _attachmentButton(
                  icon: Icons.videocam,
                  color: Colors.red,
                  label: "Video",
                  onTap: () {
                    setState(() {
                      _isAttachmentMenuOpen = false;
                    });
                    _openVideoPicker(groupData);
                  },
                ),
                _attachmentButton(
                  icon: Icons.location_on,
                  color: Colors.green,
                  label: "Location",
                  onTap: () {
                    setState(() {
                      _isAttachmentMenuOpen = false;
                    });
                    // Location functionality
                  },
                ),
              ],
            ),
          ),
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                offset: const Offset(0, 2),
                blurRadius: 5,
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
                  });
                },
                icon: Icon(
                  _isAttachmentMenuOpen ? Icons.close : Icons.add,
                  color: kPrimaryColor,
                ),
                padding: const EdgeInsets.all(0),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 1,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // Emoji picker functionality
                },
                icon: const Icon(Icons.emoji_emotions, color: Colors.amber),
                padding: const EdgeInsets.all(0),
              ),
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    if (_messageController.text.trim().isNotEmpty) {
                      _sendGroupMessage(groupData: groupData);
                    }
                  },
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _attachmentButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final GroupModel groupData = ModalRoute.of(context)!.settings.arguments as GroupModel;
    
    // Check if the current user can send messages
    final bool canSendMessages = groupData.allowAllToSendMessages || 
                               groupData.admin == currentUser || 
                               groupData.moderators.contains(currentUser);
    
    Provider.of<GroupMessageProvider>(context, listen: false).loadAllGroupData(currentUser);
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leadingWidth: 40,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () => Navigator.pushNamed(context, "/group_detail", arguments: groupData),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: groupData.image == "" || groupData.image == null
                    ? const AssetImage("assets/user.png") as ImageProvider
                    : CachedNetworkImageProvider(
                        "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${groupData.image}/view?project=67cc0b99002c794410a6&mode=admin"),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    groupData.groupName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    memCal(groupData.members.length),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            itemBuilder: (context) => <PopupMenuEntry<String>>[
              if (groupData.isPublic || groupData.admin == currentUser)
                PopupMenuItem<String>(
                  onTap: () => Navigator.pushNamed(context, "/invite_members", arguments: groupData),
                  child: const Row(
                    children: [
                      Icon(Icons.group_add_outlined, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Text("Invite Members")
                    ],
                  ),
                ),
              if (groupData.admin == currentUser)
                PopupMenuItem<String>(
                  onTap: () => Navigator.pushNamed(context, "/modify_group", arguments: groupData),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_outlined, color: kPrimaryColor),
                      SizedBox(width: 8),
                      Text("Edit Group")
                    ],
                  ),
                ),
              if (groupData.admin != currentUser)
                PopupMenuItem<String>(
                  onTap: () async {
                    await exitGroup(
                      groupId: groupData.groupId,
                      currentUser: currentUser
                    ).then((value) {
                      if (value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Group Left Successfully."))
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Failed to exit group."))
                        );
                      }
                    });
                  },
                  child: Row(
                    children: [
                      Icon(Icons.exit_to_app, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      const Text("Exit Group")
                    ],
                  ),
                ),
            ],
            child: const Icon(Icons.more_vert, color: Colors.black87),
          )
        ],
      ),
      body: Column(
        children: [
          // Reply preview if replying to a message
          if (replyingTo != null)
            _buildReplyPreview(),
            
          // Messages list
          Expanded(
            child: Consumer<GroupMessageProvider>(
              builder: (context, value, child) {
                Map<String, List<GroupMessageModel>> allGroupMessages = value.getGroupMessages;
                List<GroupMessageModel> thisGroupMsg = allGroupMessages[groupData.groupId] ?? [];
                
                // Reverse the list for display
                List<GroupMessageModel> reversedMsg = thisGroupMsg.reversed.toList();
                
                if (thisGroupMsg.isNotEmpty) {
                  updateLastMessageSeen(groupData.groupId, thisGroupMsg.last.messageId);
                }
                
                // Improved scroll behavior - ensure we scroll only when messages are loaded
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  scrollToBottom(animate: false);
                });
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: reversedMsg.length,
                    itemBuilder: (context, index) {
                      final msg = reversedMsg[index];
                      return GestureDetector(
                        onLongPress: () => _showMessageOptions(msg, groupData),
                        child: GroupChatMessage(
                          msg: msg,
                          currentUser: currentUser,
                          isImage: msg.isImage ?? false,
                          onImageTap: (imageId) => _showFullScreenImage(imageId),
                          onVideoTap: (videoId) => _showVideoPlayer(videoId),
                          onAudioTap: (audioId) => _showAudioPlayer(
                            audioId, 
                            msg.senderId == currentUser ? 'You' : msg.userData[0].name ?? 'User'
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          // Show message restriction notice if user can't send messages
          if (!canSendMessages)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.grey.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.grey.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Only admins and moderators can send messages",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input area - only show if user can send messages
          if (canSendMessages)
            _buildMessageInputArea(groupData),
        ],
      ),
    );
  }
}

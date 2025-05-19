import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/constants/formate_date.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/models/message_model.dart';
import 'package:chat/providers/chat_provider.dart';

class ChatMessage extends StatefulWidget {
  final MessageModel msg;
  final String currentUser;
  final bool isImage;
  final Function(String)? onImageTap;
  final Function(String)? onVideoTap;
  final Function(String)? onAudioTap;

  const ChatMessage({
    super.key,
    required this.msg,
    required this.currentUser,
    required this.isImage,
    this.onImageTap,
    this.onVideoTap,
    this.onAudioTap,
  });

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isAudioPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = widget.msg.sender == widget.currentUser;
    Map groupInviteData = widget.msg.isGroupInvite == true
        ? jsonDecode(widget.msg.message) ?? {}
        : {};

    // Build reply widget if this is a reply message
    Widget? replyWidget;
    if (widget.msg.replyMessage != null && widget.msg.replySender != null) {
      replyWidget = _buildReplyWidget(isMe);
    }

    // Reaction widget
    Widget? reactionWidget;
    if (widget.msg.reaction != null) {
      reactionWidget = _buildReactionWidget();
    }

    return FadeTransition(
      opacity: _animation,
      child: SizeTransition(
        sizeFactor: _animation,
        child: Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          child: widget.msg.isGroupInvite == true
              ? _buildGroupInvite(isMe, groupInviteData)
              : widget.msg.isAudio == true
                  ? _buildAudioMessage(isMe, replyWidget, reactionWidget)
                  : widget.msg.isVideo == true
                      ? _buildVideoMessage(isMe, replyWidget, reactionWidget)
                      : widget.isImage
                          ? _buildImageMessage(isMe, replyWidget, reactionWidget)
                          : _buildTextMessage(isMe, replyWidget, reactionWidget),
        ),
      ),
    );
  }

  Widget _buildReplyWidget(bool isMe) {
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isMe
            ? kPrimaryColor.withOpacity(0.2)
            : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.msg.replySender == widget.currentUser
                ? "You"
                : widget.msg.replySender!,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isMe ? kPrimaryColor : Colors.black87,
            ),
          ),
          SizedBox(height: 2),
          Text(
            widget.msg.replyMessage!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        widget.msg.reaction!,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildGroupInvite(bool isMe, Map groupInviteData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            isMe
                ? "You sent a group invitation for ${groupInviteData["name"]}."
                : "Group invitation for ${groupInviteData["name"]}.",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width * .8,
          margin: EdgeInsets.only(
            left: isMe ? 64 : 8,
            right: isMe ? 8 : 64,
          ),
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(
                    colors: [
                      kPrimaryColor.withOpacity(0.9),
                      kPrimaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isMe ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade100,
                    backgroundImage: groupInviteData["image"] == null ||
                            groupInviteData["image"] == ""
                        ? AssetImage("assets/user.png") as ImageProvider
                        : CachedNetworkImageProvider(
                            "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${groupInviteData["image"]}/view?project=67cc0b99002c794410a6&mode=admin"),
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  groupInviteData["name"] ?? "",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${groupInviteData["members"]?.length ?? 0} members",
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  groupInviteData["desc"] ?? "",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isMe ? Colors.white.withOpacity(0.9) : Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        if (isMe) {
                          // cancel the invitation
                          Provider.of<ChatProvider>(context, listen: false)
                              .deleteMessage(widget.msg, widget.currentUser);
                        } else {
                          await addUserToGroup(
                            groupId: groupInviteData["id"],
                            currentUser: widget.currentUser,
                          ).then((value) {
                            if (value) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Joined ${groupInviteData["name"]} group successfully.",
                                  ),
                                  backgroundColor: kSecureGreen,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.all(10),
                                ),
                              );
                              Provider.of<ChatProvider>(context, listen: false)
                                  .deleteMessage(widget.msg, widget.currentUser);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error in joining group."),
                                  backgroundColor: Colors.red.shade600,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  margin: EdgeInsets.all(10),
                                ),
                              );
                            }
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMe ? Colors.white : kPrimaryColor,
                        foregroundColor: isMe ? kPrimaryColor : Colors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isMe ? "Cancel Invitation" : "Join Group",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (!isMe) SizedBox(width: 10),
                    if (!isMe)
                      OutlinedButton(
                        onPressed: () {
                          Provider.of<ChatProvider>(context, listen: false)
                              .deleteMessage(widget.msg, widget.currentUser);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Colors.red.shade400,
                            width: 1,
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Reject",
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 4),
        _buildMessageTime(isMe),
      ],
    );
  }

  Widget _buildAudioMessage(bool isMe, Widget? replyWidget, Widget? reactionWidget) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (replyWidget != null)
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 64 : 8,
                  right: isMe ? 8 : 64,
                ),
                child: replyWidget,
              ),
            GestureDetector(
              onTap: () {
                if (widget.onAudioTap != null) {
                  widget.onAudioTap!(widget.msg.message);
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                margin: EdgeInsets.only(
                  left: isMe ? 64 : 8,
                  right: isMe ? 8 : 64,
                ),
                decoration: BoxDecoration(
                  color: isMe ? kPrimaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                        color: isMe ? Colors.white : kPrimaryColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Audio Message",
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Tap to play",
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (reactionWidget != null)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 16,
                  right: isMe ? 16 : 0,
                  top: 4,
                ),
                child: reactionWidget,
              ),
            _buildMessageTime(isMe),
          ],
        ),
      ],
    );
  }

  Widget _buildVideoMessage(bool isMe, Widget? replyWidget, Widget? reactionWidget) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (replyWidget != null)
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 64 : 8,
                  right: isMe ? 8 : 64,
                ),
                child: replyWidget,
              ),
            GestureDetector(
              onTap: () {
                if (widget.onVideoTap != null) {
                  widget.onVideoTap!(widget.msg.message);
                }
              },
              child: Container(
                width: 200,
                height: 200,
                margin: EdgeInsets.only(
                  left: isMe ? 64 : 8,
                  right: isMe ? 8 : 64,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        color: Colors.black,
                        child: Center(
                          child: Icon(
                            Icons.video_library,
                            color: Colors.white54,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "Video",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (reactionWidget != null)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 16,
                  right: isMe ? 16 : 0,
                  top: 4,
                ),
                child: reactionWidget,
              ),
            _buildMessageTime(isMe),
          ],
        ),
      ],
    );
  }

  Widget _buildImageMessage(bool isMe, Widget? replyWidget, Widget? reactionWidget) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (replyWidget != null)
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 64 : 8,
                  right: isMe ? 8 : 64,
                ),
                child: replyWidget,
              ),
            GestureDetector(
              onTap: () {
                if (widget.onImageTap != null) {
                  widget.onImageTap!(widget.msg.message);
                }
              },
              child: Container(
                margin: EdgeInsets.only(
                  left: isMe ? 64 : 8,
                  right: isMe ? 8 : 64,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Hero(
                        tag: "image_${widget.msg.messageId}",
                        child: CachedNetworkImage(
                          imageUrl: "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.message}/view?project=67cc0b99002c794410a6&mode=admin",
                          height: 200,
                          width: 200,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 200,
                            width: 200,
                            color: Colors.grey.shade300,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: kPrimaryColor,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            width: 200,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (reactionWidget != null)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 16,
                  right: isMe ? 16 : 0,
                  top: 4,
                ),
                child: reactionWidget,
              ),
            _buildMessageTime(isMe),
          ],
        ),
      ],
    );
  }

  Widget _buildTextMessage(bool isMe, Widget? replyWidget, Widget? reactionWidget) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe)
          GestureDetector(
            onTap: () {
              if (widget.msg.userData?.isNotEmpty ?? false) {
                Navigator.pushNamed(
                  context,
                  "/view_profile",
                  arguments: {'userId': widget.msg.sender},
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: widget.msg.userData?.isNotEmpty ?? false
                    ? (widget.msg.userData![0].profilePic != null &&
                            widget.msg.userData![0].profilePic!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.userData![0].profilePic}/view?project=67cc0b99002c794410a6&mode=admin",
                          )
                        : AssetImage("assets/user.png") as ImageProvider)
                    : AssetImage("assets/user.png") as ImageProvider,
              ),
            ),
          ),
        Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (replyWidget != null)
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 64 : 8,
                  right: isMe ? 8 : 0,
                ),
                child: replyWidget,
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: EdgeInsets.only(
                left: isMe ? 64 : 8,
                right: isMe ? 8 : 16,
              ),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe ? kPrimaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: isMe ? Radius.circular(18) : Radius.circular(0),
                  bottomRight: isMe ? Radius.circular(0) : Radius.circular(18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                widget.msg.message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
            if (reactionWidget != null)
              Padding(
                padding: EdgeInsets.only(
                  left: isMe ? 0 : 16,
                  right: isMe ? 16 : 0,
                  top: 4,
                ),
                child: reactionWidget,
              ),
            _buildMessageTime(isMe),
          ],
        ),
        if (isMe)
          GestureDetector(
            onTap: () {
              if (widget.msg.userData?.isNotEmpty ?? false) {
                Navigator.pushNamed(
                  context,
                  "/view_profile",
                  arguments: {'userId': widget.msg.sender},
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: widget.msg.userData?.isNotEmpty ?? false
                    ? (widget.msg.userData![0].profilePic != null &&
                            widget.msg.userData![0].profilePic!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.userData![0].profilePic}/view?project=67cc0b99002c794410a6&mode=admin",
                          )
                        : AssetImage("assets/user.png") as ImageProvider)
                    : AssetImage("assets/user.png") as ImageProvider,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageTime(bool isMe) {
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 0 : 16,
        right: isMe ? 16 : 0,
        top: 4,
        bottom: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formatDate(widget.msg.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(width: 4),
          if (isMe)
            widget.msg.isSeenByReceiver
                ? Icon(
                    Icons.done_all,
                    size: 14,
                    color: kPrimaryColor,
                  )
                : Icon(
                    Icons.done,
                    size: 14,
                    color: Colors.grey,
                  ),
        ],
      ),
    );
  }
}

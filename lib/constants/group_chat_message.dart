import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/constants/formate_date.dart';
import 'package:chat/models/group_message_model.dart';

class GroupChatMessage extends StatefulWidget {
  final GroupMessageModel msg;
  final String currentUser;
  final bool isImage;
  final Function(String)? onImageTap;
  final Function(String)? onVideoTap;
  final Function(String)? onAudioTap;

  const GroupChatMessage({
    super.key,
    required this.msg,
    required this.currentUser,
    required this.isImage,
    this.onImageTap,
    this.onVideoTap,
    this.onAudioTap,
  });

  @override
  State<GroupChatMessage> createState() => _GroupChatMessageState();
}

class _GroupChatMessageState extends State<GroupChatMessage> with SingleTickerProviderStateMixin {
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
    final bool isMe = widget.msg.senderId == widget.currentUser;
    
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
          child: widget.msg.isAudio == true
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
                : widget.msg.replySender ?? "Unknown",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isMe ? kPrimaryColor : Colors.black87,
            ),
          ),
          SizedBox(height: 2),
          Text(
            widget.msg.replyMessage ?? "",
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

  Widget _buildAudioMessage(bool isMe, Widget? replyWidget, Widget? reactionWidget) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.msg.userData[0].profilePic == null ||
                      widget.msg.userData[0].profilePic!.isEmpty
                  ? AssetImage("assets/user.png") as ImageProvider
                  : CachedNetworkImageProvider(
                      "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.userData[0].profilePic}/view?project=67cc0b99002c794410a6&mode=admin"),
            ),
          ),
        Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 2),
                child: Text(
                  widget.msg.userData[0].name ?? "Unknown",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            if (replyWidget != null)
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 0 : 8,
                  right: isMe ? 8 : 0,
                  bottom: 4,
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
                  right: isMe ? 8 : 16,
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
        if (isMe)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.msg.userData[0].profilePic == null ||
                      widget.msg.userData[0].profilePic!.isEmpty
                  ? AssetImage("assets/user.png") as ImageProvider
                  : CachedNetworkImageProvider(
                      "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.userData[0].profilePic}/view?project=67cc0b99002c794410a6&mode=admin"),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoMessage(bool isMe, Widget? replyWidget, Widget? reactionWidget) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.msg.userData[0].profilePic == null ||
                      widget.msg.userData[0].profilePic!.isEmpty
                  ? AssetImage("assets/user.png") as ImageProvider
                  : CachedNetworkImageProvider(
                      "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.userData[0].profilePic}/view?project=67cc0b99002c794410a6&mode=admin"),
            ),
          ),
        Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 2),
                child: Text(
                  widget.msg.userData[0].name ?? "Unknown",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            if (replyWidget != null)
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 0 : 8,
                  right: isMe ? 8 : 0,
                  bottom: 4,
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
                  right: isMe ? 8 : 16,
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
        if (isMe)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.msg.userData[0].profilePic == null ||
                      widget.msg.userData[0].profilePic!.isEmpty
                  ? AssetImage("assets/user.png") as ImageProvider
                  : CachedNetworkImageProvider(
                      "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.userData[0].profilePic}/view?project=67cc0b99002c794410a6&mode=admin"),
            ),
          ),
      ],
    );
  }

  Widget _buildImageMessage(bool isMe, Widget? replyWidget, Widget? reactionWidget) {
    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMe)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.msg.userData[0].profilePic == null ||
                      widget.msg.userData[0].profilePic!.isEmpty
                  ? AssetImage("assets/user.png") as ImageProvider
                  : CachedNetworkImageProvider(
                      "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.userData[0].profilePic}/view?project=67cc0b99002c794410a6&mode=admin"),
            ),
          ),
        Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 2),
                child: Text(
                  widget.msg.userData[0].name ?? "Unknown",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            if (replyWidget != null)
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 0 : 8,
                  right: isMe ? 8 : 0,
                  bottom: 4,
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
                  right: isMe ? 8 : 16,
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
                        tag: "group_image_${widget.msg.messageId}",
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
        if (isMe)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.msg.userData[0].profilePic == null ||
                      widget.msg.userData[0].profilePic!.isEmpty
                  ? AssetImage("assets/user.png") as ImageProvider
                  : CachedNetworkImageProvider(
                      "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.userData[0].profilePic}/view?project=67cc0b99002c794410a6&mode=admin"),
            ),
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
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.msg.userData[0].profilePic == null ||
                      widget.msg.userData[0].profilePic!.isEmpty
                  ? AssetImage("assets/user.png") as ImageProvider
                  : CachedNetworkImageProvider(
                      "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.userData[0].profilePic}/view?project=67cc0b99002c794410a6&mode=admin"),
            ),
          ),
        Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe)
              Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 2),
                child: Text(
                  widget.msg.userData[0].name ?? "Unknown",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            if (replyWidget != null)
              Container(
                margin: EdgeInsets.only(
                  left: isMe ? 0 : 8,
                  right: isMe ? 8 : 0,
                  bottom: 4,
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
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: widget.msg.userData[0].profilePic == null ||
                      widget.msg.userData[0].profilePic!.isEmpty
                  ? AssetImage("assets/user.png") as ImageProvider
                  : CachedNetworkImageProvider(
                      "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${widget.msg.userData[0].profilePic}/view?project=67cc0b99002c794410a6&mode=admin"),
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
        ],
      ),
    );
  }
}

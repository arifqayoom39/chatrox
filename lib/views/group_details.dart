import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/constants/memberCalculate.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/models/group_model.dart';
import 'package:chat/providers/user_data_provider.dart';
import 'package:chat/views/view_profile.dart';

class GroupDetails extends StatefulWidget {
  const GroupDetails({super.key});

  @override
  State<GroupDetails> createState() => _GroupDetailsState();
}

class _GroupDetailsState extends State<GroupDetails> {
  late String currentUserId;
  bool _showAllMembers = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    currentUserId = Provider.of<UserDataProvider>(context, listen: false).getUserId;
  }
  
  // Method to handle adding a moderator
  void _addModerator(GroupModel groupData, String userId, BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    
    // Only admin can add moderators
    if (groupData.admin != currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Only admin can add moderators"))
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    // Add moderator using the controller function
    bool success = await addModerator(
      groupId: groupData.groupId,
      userId: userId,
    );
    
    if (success) {
      // Update local state
      setState(() {
        if (!groupData.moderators.contains(userId)) {
          groupData.moderators.add(userId);
        }
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Moderator added successfully"))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add moderator"))
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Method to handle removing a moderator
  void _removeModerator(GroupModel groupData, String userId, BuildContext context) async {
    setState(() {
      _isLoading = true;
    });
    
    // Only admin can remove moderators
    if (groupData.admin != currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Only admin can remove moderators"))
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    // Remove moderator using the controller function
    bool success = await removeModerator(
      groupId: groupData.groupId,
      userId: userId,
    );
    
    if (success) {
      // Update local state
      setState(() {
        groupData.moderators.remove(userId);
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Moderator removed successfully"))
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove moderator"))
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final GroupModel groupData = ModalRoute.of(context)!.settings.arguments as GroupModel;
    final isAdmin = groupData.admin == currentUserId;
    final isModerator = groupData.moderators.contains(currentUserId);
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Group Details",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(Icons.edit, color: kPrimaryColor),
              onPressed: () => Navigator.pushNamed(
                context, 
                "/modify_group", 
                arguments: groupData
              ).then((_) {
                // Refresh page after editing
                setState(() {});
              }),
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Group Header Section - Chatrox style
                  _buildGroupHeader(groupData),
                  
                  Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
                  
                  // Group Description Section - Chatrox style
                  _buildGroupDescription(groupData),
                  
                  SizedBox(height: 8),
                  
                  // Admin Settings Section (only for admin) - Chatrox style
                  if (isAdmin)
                    _buildAdminSettings(groupData),
                  
                  SizedBox(height: 8),
                  
                  // Admin Section - Chatrox style
                  _buildAdminSection(groupData),
                  
                  SizedBox(height: 8),
                  
                  // Moderators Section - Chatrox style
                  _buildModeratorsSection(groupData, isAdmin),
                  
                  // Members Section
                  _buildMembersSection(groupData, isAdmin),
                  
                  // Actions Section
                  if (!isAdmin)
                    _buildActionsSection(groupData),
                ],
              ),
            ),
    );
  }
  
  Widget _buildGroupHeader(GroupModel groupData) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Hero(
            tag: "group_${groupData.groupId}",
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: groupData.image == null || groupData.image!.isEmpty
                    ? Image.asset("assets/user.png", fit: BoxFit.cover)
                    : CachedNetworkImage(
                        imageUrl: "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${groupData.image}/view?project=67cc0b99002c794410a6&mode=admin",
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.group,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          "assets/user.png",
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            groupData.groupName,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: groupData.isPublic
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              groupData.isPublic ? "Public Group" : "Private Group",
              style: TextStyle(
                color: groupData.isPublic
                    ? Colors.green.shade800
                    : Colors.orange.shade800,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            memCal(groupData.members.length),
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGroupDescription(GroupModel groupData) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            groupData.groupDesc ?? "No description provided",
            style: TextStyle(
              color: Colors.grey.shade800,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdminSettings(GroupModel groupData) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Group Settings",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          
          // Message permission setting
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.message,
                      color: kPrimaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Message Permissions",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            groupData.allowAllToSendMessages
                                ? "Everyone can send messages"
                                : "Only admins & moderators can send messages",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            groupData.allowAllToSendMessages
                                ? "All members can participate in the discussion"
                                : "Other members can only view messages",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: groupData.allowAllToSendMessages,
                      activeColor: kPrimaryColor,
                      onChanged: (newValue) async {
                        setState(() {
                          _isLoading = true;
                        });
                        
                        bool success = await updateGroupMessagePermission(
                          groupId: groupData.groupId,
                          allowAllToSendMessages: newValue,
                        );
                        
                        setState(() {
                          if (success) {
                            groupData.allowAllToSendMessages = newValue;
                          }
                          _isLoading = false;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success 
                                ? "Message permissions updated successfully"
                                : "Failed to update message permissions",
                            ),
                            backgroundColor: success ? kPrimaryColor : Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.all(10),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdminSection(GroupModel groupData) {
    // Find admin in userData
    final adminData = groupData.userData.firstWhere(
      (user) => user.userId == groupData.admin,
      orElse: () => groupData.userData.first,
    );
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Admin",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: adminData.profilePic == null || adminData.profilePic!.isEmpty
                  ? AssetImage("assets/user.png") as ImageProvider
                  : CachedNetworkImageProvider(
                      "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${adminData.profilePic}/view?project=67cc0b99002c794410a6&mode=admin",
                    ),
            ),
            title: Text(
              adminData.name ?? "Unknown",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Text(
              "Group Admin",
              style: TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: adminData.userId == currentUserId
                ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "You",
                      style: TextStyle(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewProfile(userId: adminData.userId),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildModeratorsSection(GroupModel groupData, bool isAdmin) {
    // Filter to get moderator user data
    final moderatorUsers = groupData.userData.where(
      (user) => groupData.moderators.contains(user.userId)
    ).toList();
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Moderators",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                "${moderatorUsers.length} moderators",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (moderatorUsers.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "No moderators assigned yet",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Column(
              children: moderatorUsers.map((user) {
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: user.profilePic == null || user.profilePic!.isEmpty
                        ? AssetImage("assets/user.png") as ImageProvider
                        : CachedNetworkImageProvider(
                            "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${user.profilePic}/view?project=67cc0b99002c794410a6&mode=admin",
                          ),
                  ),
                  title: Text(
                    user.name ?? "Unknown",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "Moderator",
                    style: TextStyle(
                      color: Colors.blue.shade700,
                    ),
                  ),
                  trailing: user.userId == currentUserId
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "You",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : isAdmin
                          ? IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: Colors.red.shade400),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Remove moderator?"),
                                    content: Text("Are you sure you want to remove ${user.name ?? 'this user'} as a moderator?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red.shade400,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _removeModerator(groupData, user.userId, context);
                                        },
                                        child: Text("Remove"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewProfile(userId: user.userId),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMembersSection(GroupModel groupData, bool isAdmin) {
    // Filter to get regular members (not admin and not moderators)
    final regularMembers = groupData.userData.where(
      (user) => user.userId != groupData.admin && 
                !groupData.moderators.contains(user.userId)
    ).toList();
    
    // Display all or just a few members
    final displayMembers = _showAllMembers 
        ? regularMembers 
        : regularMembers.take(5).toList();
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Members",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                "${regularMembers.length} members",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          if (regularMembers.isEmpty)
            Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  "No regular members",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            Column(
              children: displayMembers.map((user) {
                final bool isCurrentUser = user.userId == currentUserId;
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: user.profilePic == null || user.profilePic!.isEmpty
                        ? AssetImage("assets/user.png") as ImageProvider
                        : CachedNetworkImageProvider(
                            "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${user.profilePic}/view?project=67cc0b99002c794410a6&mode=admin",
                          ),
                  ),
                  title: Text(
                    user.name ?? "Unknown",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "Member",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  trailing: isCurrentUser
                      ? Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "You",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : isAdmin
                          ? IconButton(
                              icon: Icon(Icons.add_moderator, color: kPrimaryColor),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text("Add as moderator?"),
                                    content: Text("Do you want to make ${user.name ?? 'this user'} a moderator of this group?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: kPrimaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _addModerator(groupData, user.userId, context);
                                        },
                                        child: Text("Add"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            )
                          : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewProfile(userId: user.userId),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          if (regularMembers.length > 5)
            TextButton(
              onPressed: () {
                setState(() {
                  _showAllMembers = !_showAllMembers;
                });
              },
              child: Text(
                _showAllMembers ? "Show less" : "Show all members",
                style: TextStyle(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildActionsSection(GroupModel groupData) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            icon: Icon(Icons.exit_to_app),
            label: Text("Leave Group"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text("Leave group?"),
                  content: Text("Are you sure you want to leave this group? You'll need an invitation to join again."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("Cancel"),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade500,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        setState(() {
                          _isLoading = true;
                        });
                        Navigator.pop(context);
                        
                        await exitGroup(
                          groupId: groupData.groupId,
                          currentUser: currentUserId,
                        ).then((success) {
                          if (success) {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("You left the group"))
                            );
                          } else {
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Failed to leave group"))
                            );
                          }
                        });
                      },
                      child: Text("Leave"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
import 'dart:convert';

import 'package:appwrite/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/controllers/local_saved_data.dart';
import 'package:chat/models/group_model.dart';
import 'package:chat/models/synced_contact.dart';
import 'package:chat/models/user_data.dart';
import 'package:chat/providers/user_data_provider.dart';

class InviteMembers extends StatefulWidget {
  const InviteMembers({super.key});

  @override
  State<InviteMembers> createState() => _InviteMembersState();
}

class _InviteMembersState extends State<InviteMembers> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<SyncedContact> contacts = [];
  List<SyncedContact> filteredContacts = [];
  Set<String> selectedUserIds = {};
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSearching = false;
  bool _isLoading = true;
  String lastSyncTime = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _loadSyncedContacts();
    _getLastSyncTime();
  }

  Future<void> _getLastSyncTime() async {
    String time = await LocalSavedData.getLastSyncTime();
    if (mounted) {
      setState(() {
        lastSyncTime = time.isNotEmpty ? time : 'Never synced';
      });
    }
  }

  Future<void> _loadSyncedContacts() async {
    setState(() {
      _isLoading = true;
    });
    
    List<SyncedContact> loadedContacts = await LocalSavedData.getSyncedContacts();
    
    if (mounted) {
      setState(() {
        contacts = loadedContacts;
        filteredContacts = loadedContacts;
        _isLoading = false;
      });
      _animationController.forward();
    }
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredContacts = contacts;
      });
    } else {
      setState(() {
        filteredContacts = contacts
            .where((contact) =>
                contact.name.toLowerCase().contains(query.toLowerCase()) ||
                contact.phoneNumber.contains(query))
            .toList();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    GroupModel groupData = ModalRoute.of(context)!.settings.arguments as GroupModel;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    final secondaryColor = isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF8F8F8);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    final accentColor = Color(0xFF3A76F0); // Chatrox blue
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  hintStyle: TextStyle(color: subtitleColor),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: textColor, fontSize: 16),
                onChanged: _filterContacts,
              )
            : Text(
                "Add People",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 0.2,
                ),
              ),
        leading: IconButton(
          icon: Icon(_isSearching ? Icons.arrow_back : Icons.arrow_back, color: textColor),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _filterContacts('');
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          _isSearching 
              ? IconButton(
                  icon: Icon(Icons.clear, color: textColor),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _filterContacts('');
                    });
                  },
                )
              : IconButton(
                  icon: Icon(Icons.search, color: textColor),
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                    });
                  },
                ),
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.refresh, color: textColor),
              onPressed: _loadSyncedContacts,
            ),
        ],
      ),
      body: Column(
        children: [
          if (lastSyncTime.isNotEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 12, color: accentColor),
                  SizedBox(width: 8),
                  Text(
                    'Contacts updated ${_formatSyncTime(lastSyncTime)}',
                    style: TextStyle(fontSize: 12, color: subtitleColor),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildContactList(
                accentColor,
                textColor,
                subtitleColor,
                secondaryColor,
                isDarkMode
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: selectedUserIds.isNotEmpty
          ? AnimatedContainer(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Material(
                color: accentColor,
                borderRadius: BorderRadius.circular(28),
                elevation: 4,
                child: InkWell(
                  borderRadius: BorderRadius.circular(28),
                  onTap: () {
                    showDialog(
                      context: context, 
                      builder: (context) => _buildInviteDialog(
                        context, 
                        selectedUserIds,
                        groupData,
                        accentColor,
                        textColor,
                        secondaryColor,
                        isDarkMode
                      )
                    );
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.group_add,
                          color: Colors.white,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Add ${selectedUserIds.length} member${selectedUserIds.length > 1 ? "s" : ""}",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildContactList(
    Color accentColor,
    Color textColor,
    Color subtitleColor,
    Color secondaryColor,
    bool isDarkMode
  ) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
            SizedBox(height: 16),
            Text(
              "Loading contacts...",
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
          ],
        ),
      );
    } else if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 60,
              color: subtitleColor.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              "No contacts found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Sync your contacts first from the contacts tab",
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, "/search_users");
              },
              icon: Icon(Icons.sync, color: accentColor),
              label: Text("Go to Contacts", style: TextStyle(color: accentColor)),
            ),
          ],
        ),
      );
    } else if (filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: subtitleColor.withOpacity(0.5),
            ),
            SizedBox(height: 16),
            Text(
              "No matching contacts",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Try a different search term",
              style: TextStyle(
                fontSize: 14,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        final isSelected = selectedUserIds.contains(contact.userId);
        
        return SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              0.3 + (index * 0.05).clamp(0.0, 0.5),
              1.0,
              curve: Curves.easeOut,
            ),
          )),
          child: Opacity(
            opacity: _animationController.value,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: secondaryColor,
                borderRadius: BorderRadius.circular(12),
                border: isSelected 
                    ? Border.all(color: accentColor, width: 2)
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedUserIds.remove(contact.userId);
                      } else {
                        selectedUserIds.add(contact.userId);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        _buildContactAvatar(contact),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name.isNotEmpty ? contact.name : "Unknown",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                contact.phoneNumber,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? accentColor : subtitleColor,
                              width: 2,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContactAvatar(SyncedContact contact) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getAvatarColor(contact.name),
      ),
      child: contact.profilePic != null && contact.profilePic!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${contact.profilePic}/view?project=67cc0b99002c794410a6&mode=admin",
                fit: BoxFit.cover,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Center(
                  child: Text(
                    _getInitials(contact.name),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                _getInitials(contact.name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildInviteDialog(
    BuildContext context, 
    Set<String> selectedUserIds, 
    GroupModel groupData,
    Color accentColor,
    Color textColor,
    Color secondaryColor,
    bool isDarkMode
  ) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: isDarkMode ? Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.group_add,
                size: 30,
                color: accentColor,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Invite to ${groupData.groupName}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              "You are about to invite ${selectedUserIds.length} user${selectedUserIds.length > 1 ? 's' : ''} to join this group. They will need to accept your invitation.",
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text("Cancel"),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      String currentUserId = Provider.of<UserDataProvider>(context, listen: false).getUserId;
                      
                      // Show loading
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                          ),
                        ),
                      );
                      
                      for (String id in selectedUserIds) {
                        await createNewChat(
                          message: jsonEncode({
                            "name": groupData.groupName,
                            "id": groupData.groupId,
                            "desc": groupData.groupDesc,
                            "image": groupData.image
                          }), 
                          senderId: currentUserId, 
                          receiverId: id, 
                          isImage: false, 
                          isGroupInvite: true
                        );
                      }
                      
                      // Pop all screens
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      
                      // Show success snackbar
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Invitations sent successfully"),
                          backgroundColor: accentColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: EdgeInsets.all(8),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text("Send Invites"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "?";
    
    final nameParts = name.split(" ");
    if (nameParts.length > 1) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }
  
  Color _getAvatarColor(String name) {
    final List<Color> colors = [
      Color(0xFF3A76F0), // Chatrox blue
      Color(0xFF4CAF50), // Green
      Color(0xFFF44336), // Red
      Color(0xFF9C27B0), // Purple
      Color(0xFF2196F3), // Blue
      Color(0xFFFF9800), // Orange
    ];
    
    if (name.isEmpty) return colors[0];
    
    // Simple hash function to determine color based on name
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    return colors[hash.abs() % colors.length];
  }
  
  String _formatSyncTime(String timeString) {
    try {
      final syncTime = DateTime.parse(timeString);
      final now = DateTime.now();
      final difference = now.difference(syncTime);

      if (difference.inMinutes < 1) {
        return 'just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
      } else {
        return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return timeString;
    }
  }
}

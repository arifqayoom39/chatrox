import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/constants/formate_date.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/controllers/fcm_controllers.dart';
import 'package:chat/controllers/local_saved_data.dart';
import 'package:chat/models/chat_data_model.dart';
import 'package:chat/models/group_message_model.dart';
import 'package:chat/models/status_model.dart';
import 'package:chat/models/synced_contact.dart';
import 'package:chat/models/user_data.dart';
import 'package:chat/providers/chat_provider.dart';
import 'package:chat/providers/group_message_provider.dart';
import 'package:chat/providers/status_provider.dart';
import 'package:chat/providers/user_data_provider.dart';
import 'package:chat/views/status_view.dart';
import 'package:chat/views/profile_image_viewer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String currentUserid = "";
  int _selectedIndex = 0;
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingContacts = false;
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  void initState() {
    currentUserid =
        Provider.of<UserDataProvider>(context, listen: false).getUserId;
    Provider.of<ChatProvider>(context, listen: false).loadChats(currentUserid);
    Provider.of<GroupMessageProvider>(context, listen: false)
        .loadAllGroupRequiredData(currentUserid);
    
    // Schedule status data loading after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatusData();
    });
    
    PushNotifications.getDeviceToken();
    subscribeToRealtime(userId: currentUserid);
    subscribeToRealtimeGroupMsg(userId: currentUserid);
    super.initState();
  }
  
  Future<void> _loadStatusData() async {
    setState(() {
      _isLoadingContacts = true;
    });
    
    final statusProvider = Provider.of<StatusProvider>(context, listen: false);
    List<SyncedContact> savedContacts = await LocalSavedData.getSyncedContacts();
    
    List<String> contactUserIds = [];
    
    if (savedContacts.isNotEmpty) {
      contactUserIds = savedContacts
          .where((contact) => contact.userId != null && contact.userId!.isNotEmpty)
          .map((contact) => contact.userId!)
          .toList();
    }
    
    if (contactUserIds.isEmpty) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (chatProvider.getAllChats.isNotEmpty) {
        contactUserIds = chatProvider.getAllChats.keys.toList();
      }
    }
    
    // Always make sure to load the user's own status first
    await statusProvider.loadUserOwnStatuses(currentUserid);
    
    // Then load contact statuses
    await statusProvider.initializeData(currentUserid, contactUserIds);
    
    setState(() {
      _isLoadingContacts = false;
    });
    
    // Debug output to verify statuses
    print("User own statuses count: ${statusProvider.userOwnStatuses.length}");
    print("Contact statuses count: ${statusProvider.contactStatuses.length}");
  }
  
  @override
  void dispose() {
    _captionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Add this method to show profile image in full screen
  void _showProfileImage(BuildContext context, String? profileImage, String name) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => ProfileImageViewer(
          imageUrl: profileImage,
          name: name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    updateOnlineStatus(status: true, userId: currentUserid);
    
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: _selectedIndex == 0 
          ? _buildDirectMessagesPage() 
          : IndexedStack(
              index: _selectedIndex - 1,
              children: [
                _buildStatusPage(),
                _buildGroupMessagesPage(),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }
  
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: kBackgroundColor,
      title: Row(
        children: [
          const Text(
            "Chatrox",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.black87,
            ),
          ),
          if (_selectedIndex == 0 && !_isSearching)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kSecureGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                "Secure",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      actions: [
        if (_selectedIndex == 0 && !_isSearching)
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.grey, width: 0.2),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Row(
                  children: const [
                    Icon(Icons.group_add, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text('New Group'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 2,
                child: Row(
                  children: const [
                    Icon(Icons.lock, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text('Secure Settings'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 3,
                child: Row(
                  children: const [
                    Icon(Icons.person, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 3) {
                Navigator.pushNamed(context, "/profile");
              } else if (value == 1) {
                Navigator.pushNamed(context, "/modify_group");
              }
            },
          )
        else if (_selectedIndex == 0 && _isSearching)
          Container()
        else
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black87),
            onPressed: () => Navigator.pushNamed(context, "/search"),
          ),
      ],
    );
  }
  
  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: kPrimaryColor,
        unselectedItemColor: Colors.grey.shade600,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.circle_outlined),
            activeIcon: Icon(Icons.circle),
            label: 'Stories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Groups',
          ),
        ],
      ),
    );
  }
  
  Widget _buildFloatingActionButton() {
    switch (_selectedIndex) {
      case 0: // Chats
        return FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, "/search"),
          backgroundColor: kPrimaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(CupertinoIcons.pencil, color: Colors.white),
        );
      case 1: // Stories
        return FloatingActionButton(
          onPressed: () => _showStatusOptions(),
          backgroundColor: kPrimaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        );
      case 2: // Groups
        return FloatingActionButton(
          onPressed: () => Navigator.pushNamed(context, "/explore_groups"),
          backgroundColor: kPrimaryColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.group_add, color: Colors.white),
        );
      default:
        return const SizedBox.shrink();
    }
  }
  
  void _showStatusOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your story",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Share a photo or message that disappears after 24 hours.",
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _storyOptionButton(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  _storyOptionButton(
                    icon: Icons.photo_library,
                    label: "Gallery",
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  Widget _storyOptionButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: kPrimaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: kPrimaryColor,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    
    if (image != null) {
      _showCaptionDialog(File(image.path));
    }
  }
  
  void _showCaptionDialog(File imageFile) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.file(
                  imageFile,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Add to your story",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _captionController,
                      decoration: InputDecoration(
                        hintText: "Add a caption...",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _captionController.clear();
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _uploadStatus(imageFile, _captionController.text);
                _captionController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text("Share"),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _uploadStatus(File imageFile, String caption) async {
    try {
      final statusProvider = Provider.of<StatusProvider>(context, listen: false);
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: kPrimaryColor),
                SizedBox(height: 16),
                Text(
                  "Securing your story...",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      
      String? imageId = await saveImageToBucket(
        image: InputFile(
          path: imageFile.path,
          filename: 'story_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
      
      Navigator.of(context, rootNavigator: true).pop();
      
      if (imageId != null) {
        final success = await statusProvider.createNewStatus(
          currentUserid,
          imageId,
          caption.isNotEmpty ? caption : null,
        );
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Story shared successfully'),
                ],
              ),
              backgroundColor: kSecureGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
              elevation: 0,
            ),
          );
          _loadStatusData();
        } else {
          _showErrorSnackbar('Failed to post story. Please try again.');
        }
      } else {
        _showErrorSnackbar('Failed to upload image. Please try again.');
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      _showErrorSnackbar('Error: ${e.toString()}');
    }
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
  
  Widget _buildDirectMessagesPage() {
    return Consumer<ChatProvider>(
      builder: (context, value, child) {
        if (_isSearching) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Search conversations...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade200,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchController.clear();
                          _searchQuery = "";
                        });
                      },
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: _buildChatListWithSearch(value),
              ),
            ],
          );
        }
        
        if (value.getAllChats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.chat_bubble_text,
                  size: 70,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  "No secure messages yet",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Start a private conversation with\nyour contacts",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, "/search"),
                  icon: const Icon(Icons.add),
                  label: const Text("New Message"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          return _buildChatListWithSearch(value);
        }
      },
    );
  }

  Widget _buildChatListWithSearch(ChatProvider provider) {
    if (provider.getAllChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.chat_bubble_text,
              size: 70,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              _isSearching ? "No matches found" : "No secure messages yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isSearching 
                ? "Try a different search term"
                : "Start a private conversation with\nyour contacts",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            if (!_isSearching)
              const SizedBox(height: 32),
            if (!_isSearching)
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, "/search"),
                icon: const Icon(Icons.add),
                label: const Text("New Message"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      );
    }
    
    List<String> otherUsers = provider.getAllChats.keys.toList();
    
    // Filter users based on search query
    if (_isSearching && _searchQuery.isNotEmpty) {
      otherUsers = otherUsers.where((userId) {
        List<ChatDataModel> chatData = provider.getAllChats[userId]!;
        if (chatData.isEmpty) return false;
        
        UserData otherUser = chatData[0].users[0].userId == currentUserid
            ? chatData[0].users[1]
            : chatData[0].users[0];
        
        String userName = (otherUser.name ?? "").toLowerCase();
        
        // Check if the name contains the search query
        return userName.contains(_searchQuery);
      }).toList();
    }
    
    if (_isSearching && otherUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 70,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              "No matches found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Try a different search term",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: otherUsers.length,
      itemBuilder: (context, index) {
        List<ChatDataModel> chatData = provider.getAllChats[otherUsers[index]]!;
        if (chatData.isEmpty) return const SizedBox.shrink();
        
        int totalChats = chatData.length;
        UserData otherUser = chatData[0].users[0].userId == currentUserid
            ? chatData[0].users[1]
            : chatData[0].users[0];
        
        int unreadMsg = 0;
        for (var element in chatData) {
          if (element.message.isSeenByReceiver == false &&
              element.message.sender != currentUserid) {
            unreadMsg++;
          }
        }
        
        return _buildChatListItem(
          otherUser: otherUser, 
          chatData: chatData, 
          totalChats: totalChats, 
          unreadMsg: unreadMsg,
        );
      },
    );
  }
  
  Widget _buildChatListItem({
    required UserData otherUser,
    required List<ChatDataModel> chatData,
    required int totalChats,
    required int unreadMsg,
  }) {
    final latestMessage = chatData[totalChats - 1];
    final isMessageFromMe = latestMessage.message.sender == currentUserid;
    
    return Column(
      children: [
        Ink(
          decoration: BoxDecoration(
            color: unreadMsg > 0 && !isMessageFromMe
                ? kLightBlue.withOpacity(0.3)
                : Colors.transparent,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            onTap: () => Navigator.pushNamed(context, "/chat", arguments: otherUser),
            leading: Stack(
              children: [
                GestureDetector(
                  onTap: () => _showProfileImage(
                    context,
                    otherUser.profilePic,
                    otherUser.name ?? "User"
                  ),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Hero(
                      tag: "profile-${otherUser.userId}",
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: otherUser.profilePic == "" ||
                                otherUser.profilePic == null
                            ? const AssetImage("assets/user.png") as ImageProvider
                            : CachedNetworkImageProvider(
                                "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${otherUser.profilePic}/view?project=67cc0b99002c794410a6&mode=admin"),
                      ),
                    ),
                  ),
                ),
                if (otherUser.isOnline == true)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: kSecureGreen,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    otherUser.name ?? "User",
                    style: TextStyle(
                      fontWeight: unreadMsg > 0 && !isMessageFromMe
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  formatDate(latestMessage.message.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: unreadMsg > 0 && !isMessageFromMe
                        ? kPrimaryColor
                        : Colors.grey.shade500,
                    fontWeight: unreadMsg > 0 && !isMessageFromMe
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            subtitle: Row(
              children: [
                isMessageFromMe
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            latestMessage.message.isSeenByReceiver
                                ? Icons.done_all
                                : Icons.done,
                            size: 16,
                            color: latestMessage.message.isSeenByReceiver
                                ? kPrimaryColor
                                : Colors.grey,
                          ),
                          const SizedBox(width: 4),
                        ],
                      )
                    : const SizedBox(),
                Expanded(
                  child: Text(
                    latestMessage.message.isGroupInvite
                        ? "${isMessageFromMe ? "You sent a group invite" : "Sent you a group invite"}"
                        : "${isMessageFromMe ? "You: " : ""}${latestMessage.message.isImage == true ? "Photo" : latestMessage.message.message ?? ""}",
                    style: TextStyle(
                      color: unreadMsg > 0 && !isMessageFromMe
                          ? Colors.black87
                          : Colors.grey.shade600,
                      fontWeight: unreadMsg > 0 && !isMessageFromMe
                          ? FontWeight.w500
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                unreadMsg > 0 && !isMessageFromMe
                    ? Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: kPrimaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadMsg.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ),
        const Divider(
          height: 1,
          thickness: 0.5,
          indent: 72,
          endIndent: 0,
          color: kSeparatorColor,
        ),
      ],
    );
  }
  
  Widget _buildStatusPage() {
    return Consumer<StatusProvider>(
      builder: (context, statusProvider, child) {
        return Consumer<UserDataProvider>(
          builder: (context, userProvider, child) {
            bool hasStatus = statusProvider.userOwnStatuses.isNotEmpty;
            
            if (hasStatus) {
              print("User has ${statusProvider.userOwnStatuses.length} stories");
            }
            
            return RefreshIndicator(
              onRefresh: () async {
                await _loadStatusData();
              },
              color: kPrimaryColor,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Your status
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          InkWell(
                            onTap: hasStatus 
                                ? () {
                                    print("Navigating to StatusView with ${statusProvider.userOwnStatuses.length} statuses");
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => StatusView(
                                          statuses: statusProvider.userOwnStatuses,
                                          userId: currentUserid,
                                        ),
                                      ),
                                    ).then((_) => _loadStatusData());
                                  }
                                : () => _showStatusOptions(),
                            onLongPress: () => _showProfileImage(
                              context,
                              userProvider.getUserProfile,
                              userProvider.getUserName ?? "You"
                            ),
                            child: Stack(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: hasStatus ? kPrimaryColor : Colors.grey.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: Hero(
                                      tag: "profile-${currentUserid}",
                                      child: CircleAvatar(
                                        backgroundImage: userProvider.getUserProfile != null &&
                                                userProvider.getUserProfile.isNotEmpty
                                            ? CachedNetworkImageProvider(
                                                "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${userProvider.getUserProfile}/view?project=67cc0b99002c794410a6&mode=admin")
                                            : const AssetImage("assets/user.png") as ImageProvider,
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: kPrimaryColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(
                                      hasStatus ? Icons.add : Icons.add,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "My Story",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hasStatus 
                                    ? "Tap to view your story"
                                    : "Tap to add story update",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (hasStatus)
                            IconButton(
                              icon: Icon(Icons.more_horiz, color: Colors.grey.shade700),
                              onPressed: () {
                                // Show story options
                              },
                            ),
                        ],
                      ),
                    ),
                    
                    const Divider(height: 24, thickness: 0.5, color: kSeparatorColor),
                    
                    // Recent Updates Header
                    if (statusProvider.contactStatuses.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          "Recent Stories",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kSecondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    
                    // Loading state
                    if (statusProvider.isLoading || _isLoadingContacts)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: kPrimaryColor),
                              SizedBox(height: 16),
                              Text(
                                "Loading stories...",
                                style: TextStyle(color: kSecondaryTextColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Empty state
                    if (statusProvider.contactStatuses.isEmpty && !statusProvider.isLoading && !_isLoadingContacts)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.circle_outlined, 
                                size: 60, 
                                color: Colors.grey.shade400
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "No stories yet",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "When your contacts share stories,\nyou'll see them here",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Contact statuses list
                    ...statusProvider.contactStatuses.entries.map((entry) {
                      String userId = entry.key;
                      List<StatusModel> statuses = entry.value;
                      StatusModel latestStatus = statuses.first;
                      bool isViewed = latestStatus.viewedBy.contains(currentUserid);
                      
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StatusView(
                                  statuses: statuses,
                                  userId: currentUserid,
                                ),
                              ),
                            ).then((_) => _loadStatusData()),
                            leading: GestureDetector(
                              onTap: () => _showProfileImage(
                                context,
                                latestStatus.userData?.profilePic,
                                latestStatus.userData?.name ?? "User"
                              ),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isViewed ? Colors.grey.shade400 : kPrimaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(2.0),
                                  child: Hero(
                                    tag: "profile-${userId}",
                                    child: CircleAvatar(
                                      backgroundImage: latestStatus.userData?.profilePic != null &&
                                              latestStatus.userData!.profilePic!.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${latestStatus.userData!.profilePic}/view?project=67cc0b99002c794410a6&mode=admin")
                                          : const AssetImage("assets/user.png") as ImageProvider,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              latestStatus.userData?.name ?? "User",
                              style: TextStyle(
                                fontWeight: isViewed ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              formatTimeAgo(latestStatus.timestamp),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const Divider(
                            height: 1,
                            thickness: 0.5,
                            indent: 76,
                            color: kSeparatorColor,
                          ),
                        ],
                      );
                    }).toList(),
                    
                    const SizedBox(height: 80), // Bottom padding for FAB
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  String formatTimeAgo(DateTime dateTime) {
    final Duration difference = DateTime.now().difference(dateTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return 'Today';
    }
  }
  
  Widget _buildGroupMessagesPage() {
    return Consumer<GroupMessageProvider>(
      builder: (context, value, child) {
        if (value.getJoinedGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 70,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  "No groups yet",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Create or join a secure group chat",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, "/explore_groups"),
                  icon: const Icon(Icons.group_add),
                  label: const Text("Find Groups"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Sort groups based on latest message timestamp
          value.getJoinedGroups.sort((a, b) {
            String groupIdA = a.groupId;
            String groupIdB = b.groupId;

            List<GroupMessageModel>? messagesA = value.getGroupMessages?[groupIdA];
            DateTime? latestTimestampA = messagesA != null && messagesA.isNotEmpty
                ? messagesA.last.timestamp
                : DateTime.fromMillisecondsSinceEpoch(0);

            List<GroupMessageModel>? messagesB = value.getGroupMessages?[groupIdB];
            DateTime? latestTimestampB = messagesB != null && messagesB.isNotEmpty
                ? messagesB.last.timestamp
                : DateTime.fromMillisecondsSinceEpoch(0);

            return latestTimestampB.compareTo(latestTimestampA);
          });
          
          return Column(
            children: [
              // Search/Explore card
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, "/explore_groups"),
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kPrimaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.search,
                            color: kPrimaryColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Find and join groups",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: ListView.builder(
                  itemCount: value.getJoinedGroups.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final group = value.getJoinedGroups[index];
                    String groupId = group.groupId;
                    List<GroupMessageModel>? messages = value.getGroupMessages[groupId];
                    GroupMessageModel? latestMessage = messages != null && messages.isNotEmpty
                        ? messages.last
                        : null;
                    
                    return FutureBuilder(
                      future: calculateUnreadMessages(groupId, messages ?? []),
                      builder: (context, snapshot) {
                        int unreadMsgCount = snapshot.data ?? 0;
                        
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onTap: () => Navigator.pushNamed(
                                context, 
                                "/read_group_message",
                                arguments: group
                              ),
                              leading: GestureDetector(
                                onTap: () => _showProfileImage(
                                  context,
                                  group.image,
                                  group.groupName
                                ),
                                child: Stack(
                                  children: [
                                    Hero(
                                      tag: "profile-group-${group.groupId}",
                                      child: CircleAvatar(
                                        radius: 26,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage: group.image == "" ||
                                                group.image == null
                                            ? const AssetImage("assets/user.png") as ImageProvider
                                            : CachedNetworkImageProvider(
                                                "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${group.image}/view?project=67cc0b99002c794410a6&mode=admin"
                                              ),
                                      ),
                                    ),
                                    if (unreadMsgCount > 0)
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: kSecureGreen,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      group.groupName,
                                      style: TextStyle(
                                        fontWeight: unreadMsgCount > 0
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  if (latestMessage != null)
                                    Text(
                                      formatDate(latestMessage.timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: unreadMsgCount > 0
                                            ? kPrimaryColor
                                            : Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      latestMessage == null
                                          ? "Secure group • ${group.members.length} members"
                                          : "${latestMessage.senderId == currentUserid ? "You: " : "${latestMessage.userData != null && latestMessage.userData.isNotEmpty ? latestMessage.userData[0].name ?? "User" : "User"}: "}${latestMessage.isImage == true ? "Photo" : latestMessage.message}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: unreadMsgCount > 0
                                            ? Colors.black87
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  unreadMsgCount > 0
                                      ? Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: kPrimaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            unreadMsgCount.toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                            const Divider(
                              height: 1,
                              thickness: 0.5,
                              indent: 72,
                              color: kSeparatorColor,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }
  
  
}

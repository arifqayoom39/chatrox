import 'package:appwrite/models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/controllers/local_saved_data.dart';
import 'package:chat/models/synced_contact.dart';
import 'package:chat/models/user_data.dart';
import 'package:chat/providers/user_data_provider.dart';
import 'package:flutter_contacts_service/flutter_contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SearchUsers extends StatefulWidget {
  const SearchUsers({super.key});

  @override
  State<SearchUsers> createState() => _SearchUsersState();
}

class _SearchUsersState extends State<SearchUsers> {
  TextEditingController _searchController = TextEditingController();
  List<SyncedContact> syncedContacts = [];
  List<SyncedContact> filteredContacts = [];
  bool isLoading = false;
  String lastSyncTime = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSyncedContacts();
    _getLastSyncTime();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getLastSyncTime() async {
    String time = await LocalSavedData.getLastSyncTime();
    setState(() {
      lastSyncTime = time.isNotEmpty ? time : 'Never synced';
    });
  }

  Future<void> _loadSyncedContacts() async {
    List<SyncedContact> contacts = await LocalSavedData.getSyncedContacts();
    setState(() {
      syncedContacts = contacts;
      filteredContacts = contacts;
    });
  }

  void _filterContacts(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredContacts = syncedContacts;
      });
    } else {
      setState(() {
        filteredContacts = syncedContacts
            .where((contact) =>
                contact.name.toLowerCase().contains(query.toLowerCase()) ||
                contact.phoneNumber.contains(query))
            .toList();
      });
    }
  }

  Future<void> _syncContacts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final status = await Permission.contacts.request();
      if (status != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Contacts permission is required for syncing')),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      final contacts = await FlutterContactsService.getContacts();

      final phoneNumbers = contacts
          .where((contact) => contact.phones?.isNotEmpty == true)
          .map((contact) => contact.phones!.first.value)
          .toList();

      final normalizedNumbers = phoneNumbers.map((number) {
        return number?.replaceAll(RegExp(r'[^\d+]'), '');
      }).toList();

      print("Found ${normalizedNumbers.length} contacts on device");

      final currentUserId = Provider.of<UserDataProvider>(context, listen: false).getUserId;

      final syncedDocs = await batchSyncContacts(
        allPhoneNumbers: normalizedNumbers.whereType<String>().toList(),
        currentUserId: currentUserId,
      );

      List<SyncedContact> syncedContactsList = syncedDocs.map((doc) {
        return SyncedContact.fromMap(doc.data);
      }).toList();

      await LocalSavedData.saveSyncedContacts(syncedContactsList);

      final now = DateTime.now().toString();
      await LocalSavedData.saveLastSyncTime(now);

      setState(() {
        syncedContacts = syncedContactsList;
        filteredContacts = syncedContactsList;
        isLoading = false;
        lastSyncTime = now;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Found ${syncedContactsList.length} contacts using the app'),
            ],
          ),
          backgroundColor: kSecureGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
          elevation: 0,
        ),
      );
    } catch (e) {
      print("Error during contact sync: $e");
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Error syncing contacts: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(10),
          elevation: 0,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (lastSyncTime.isNotEmpty && !_isSearching)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 4),
              child: Row(
                children: [
                  isLoading
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                          ))
                      : Icon(Icons.check_circle, size: 12, color: kSecureGreen),
                  SizedBox(width: 8),
                  Text(
                    'Contacts updated ${_formatSyncTime(lastSyncTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          if (!_isSearching) Divider(height: 1, thickness: 0.5, color: kSeparatorColor),
          if (!_isSearching)
            ListTile(
              onTap: () => Navigator.pushNamed(context, "/modify_group"),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kPrimaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.group_add, color: kPrimaryColor, size: 24),
              ),
              title: Text(
                "New Group",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          if (!_isSearching) Divider(height: 1, thickness: 0.5, color: kSeparatorColor),
          Expanded(
            child: syncedContacts.isEmpty && !isLoading
                ? _buildEmptyState()
                : isLoading && syncedContacts.isEmpty
                    ? _buildLoadingState()
                    : _buildContactsList(),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: kBackgroundColor,
      title: _isSearching
          ? TextField(
              controller: _searchController,
              onChanged: _filterContacts,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Search contacts...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
              style: TextStyle(color: Colors.black87, fontSize: 16),
            )
          : Row(
              children: [
                Text(
                  "Chatrox",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(left: 8),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kSecureGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Contacts",
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
        if (_isSearching)
          IconButton(
            icon: Icon(Icons.close, color: Colors.black87),
            onPressed: () {
              setState(() {
                _isSearching = false;
                _searchController.clear();
                _filterContacts('');
              });
            },
          )
        else
          IconButton(
            icon: Icon(Icons.search, color: Colors.black87),
            onPressed: () {
              setState(() {
                _isSearching = true;
              });
            },
          ),
        if (!_isSearching)
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.black87),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sync',
                child: Row(
                  children: [
                    Icon(Icons.sync, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text('Refresh contacts'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'invite',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.black87, size: 20),
                    SizedBox(width: 8),
                    Text('Invite friends'),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'sync') {
                _syncContacts();
              }
            },
          ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () => _syncContacts(),
      backgroundColor: kPrimaryColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: isLoading 
          ? CircularProgressIndicator(color: Colors.white)  
          : Icon(Icons.sync, color: Colors.white),
    );
  }

  Widget _buildContactsList() {
    return ListView.separated(
      itemCount: filteredContacts.length,
      padding: EdgeInsets.only(bottom: 80),
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.5,
        indent: 72,
        color: kSeparatorColor,
      ),
      itemBuilder: (context, index) {
        final contact = filteredContacts[index];
        return _buildContactTile(contact);
      },
    );
  }

  Widget _buildContactTile(SyncedContact contact) {
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          onTap: () {
            Map<String, dynamic> contactData = {
              'name': contact.name,
              'phone_no': contact.phoneNumber,
              'userId': contact.userId,
              'profile_pic': contact.profilePic ?? "",
            };

            Navigator.pushNamed(
              context,
              "/chat",
              arguments: UserData.toMap(contactData),
            );
          },
          leading: Hero(
            tag: 'avatar-${contact.userId}',
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
              child: contact.profilePic != null && contact.profilePic!.isNotEmpty
                  ? CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: NetworkImage(
                        "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${contact.profilePic}/view?project=67cc0b99002c794410a6&mode=admin",
                      ),
                    )
                  : CircleAvatar(
                      radius: 24,
                      backgroundColor: kPrimaryColor.withOpacity(0.2),
                      child: Text(
                        _getInitials(contact.name),
                        style: TextStyle(
                          color: kPrimaryColor, 
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
            ),
          ),
          title: Text(
            contact.name.isNotEmpty ? contact.name : "Unknown",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            contact.phoneNumber,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              CupertinoIcons.chat_bubble_text, 
              color: kPrimaryColor, 
              size: 22
            ),
            onPressed: () {
              Map<String, dynamic> contactData = {
                'name': contact.name,
                'phone_no': contact.phoneNumber,
                'userId': contact.userId,
                'profile_pic': contact.profilePic ?? "",
              };

              Navigator.pushNamed(
                context,
                "/chat",
                arguments: UserData.toMap(contactData),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 70,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 24),
          Text(
            "No contacts found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            "Sync your contacts to find\nfriends using the app",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: isLoading ? null : _syncContacts,
            icon: Icon(Icons.sync),
            label: Text("Sync Contacts"),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: kPrimaryColor),
          SizedBox(height: 16),
          Text(
            "Syncing contacts...",
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

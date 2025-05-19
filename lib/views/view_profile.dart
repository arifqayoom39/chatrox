import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/models/user_data.dart';

class ViewProfile extends StatefulWidget {
  final String userId;

  const ViewProfile({Key? key, required this.userId}) : super(key: key);

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  UserData? userData;
  bool isLoading = true;
  bool hasError = false;
  
  // Signal-like color scheme
  final Color primaryColor = Color(0xFF3A76F0);
  final Color secondaryColor = Color(0xFFE7EDF7);
  final Color textColor = Color(0xFF1B1B1B);
  final Color subtitleColor = Color(0xFF767676);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final data = await getUserDetails(userId: widget.userId);
      setState(() {
        userData = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: textColor),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load profile',
                        style: TextStyle(fontSize: 16, color: subtitleColor),
                      ),
                      SizedBox(height: 24),
                      TextButton(
                        onPressed: _loadUserData,
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _buildSignalStyleProfile(),
    );
  }

  Widget _buildSignalStyleProfile() {
    if (userData == null) {
      return Center(child: Text('No user data available'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24),
            // Simple, centered profile picture
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: secondaryColor,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: userData!.profilePic != null &&
                              userData!.profilePic!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${userData!.profilePic}/view?project=67cc0b99002c794410a6&mode=admin",
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey[400],
                                  size: 40,
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.person,
                                color: Colors.grey[400],
                                size: 40,
                              ),
                            )
                          : Icon(
                              Icons.person,
                              color: Colors.grey[400],
                              size: 40,
                            ),
                    ),
                  ),
                  if (userData!.isOnline == true)
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // User name and verification
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    userData!.name ?? 'User',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (userData!.isVerified == true) 
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Icon(
                        Icons.verified,
                        color: primaryColor,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
            Center(
              child: Text(
                userData!.isOnline == true ? 'Active now' : 'Last seen recently',
                style: TextStyle(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),
            ),
            SizedBox(height: 32),
            // Contact info section
            Text(
              'Contact Info',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 12),
            _buildSignalInfoItem(Icons.phone, 'Phone', userData!.phone),
            if (userData!.email != null && userData!.email!.isNotEmpty)
              _buildSignalInfoItem(Icons.email, 'Email', userData!.email!),
            if (userData!.status != null && userData!.status!.isNotEmpty)
              _buildSignalInfoItem(Icons.info_outline, 'About', userData!.status!),
            if (userData!.activeChat != null && userData!.activeChat!.isNotEmpty)
              _buildSignalInfoItem(Icons.chat_bubble_outline, 'Active Chat', userData!.activeChat!),
            SizedBox(height: 32),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildSignalButton(
                    'Message',
                    primaryColor,
                    Colors.white,
                    () => Navigator.pop(context),
                  ),
                ),
                SizedBox(width: 12),
                if (userData!.isVerified != true)
                  Expanded(
                    child: _buildSignalButton(
                      'Verify',
                      Colors.white,
                      primaryColor,
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Verification request sent'),
                            backgroundColor: primaryColor,
                          )
                        );
                      },
                      outlined: true,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSignalInfoItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: subtitleColor,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: subtitleColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 8),
                Divider(height: 1, color: Colors.grey[200]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignalButton(
      String label, Color bgColor, Color textColor, VoidCallback onTap, {bool outlined = false}) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: bgColor,
        padding: EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: outlined 
              ? BorderSide(color: this.primaryColor, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/controllers/local_saved_data.dart';
import 'package:chat/providers/chat_provider.dart';
import 'package:chat/providers/user_data_provider.dart';
import 'package:chat/views/information_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Chatrox uses a blue accent color
  final Color ChatroxBlue = Color(0xFF3A76F0);
  
  @override
  Widget build(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, value, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark 
              ? Color(0xFF121212) 
              : Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.black87,
            title: Text(
              "Profile", 
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                // Profile image section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: value.getUserProfile != null && value.getUserProfile != ""
                              ? CachedNetworkImage(
                                  imageUrl: "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${value.getUserProfile}/view?project=67cc0b99002c794410a6&mode=admin",
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => 
                                      Center(child: CircularProgressIndicator(color: ChatroxBlue)),
                                  errorWidget: (context, url, error) => 
                                      Image.asset("assets/user.png", fit: BoxFit.cover),
                                )
                              : Image.asset("assets/user.png", fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context, 
                            "/update", 
                            arguments: {"title": "edit"}
                          ),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ChatroxBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  value.getUserName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  value.getUserNumber,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 40),
                
                // Menu items
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Color(0xFF1E1E1E) 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.account_circle_outlined,
                        title: "Edit Profile",
                        onTap: () => Navigator.pushNamed(
                          context, 
                          "/update", 
                          arguments: {"title": "edit"}
                        ),
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.lock_outline,
                        title: "Privacy",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InformationPage(
                                title: "Privacy Policy",
                                content: _getPrivacyPolicyText(),
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.notifications_none_outlined,
                        title: "Notifications",
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 24),
                
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Color(0xFF1E1E1E) 
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.help_outline,
                        title: "Help",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InformationPage(
                                title: "Help",
                                content: _getHelpText(),
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.info_outline,
                        title: "About",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => InformationPage(
                                title: "About",
                                content: _getAboutText(),
                              ),
                            ),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildMenuItem(
                        icon: Icons.logout_outlined,
                        title: "Logout",
                        isDestructive: true,
                        onTap: () async {
                          await updateOnlineStatus(
                            status: false,
                            userId: Provider.of<UserDataProvider>(context, listen: false).getUserId
                          );
                          await LocalSavedData.clearAll();
                          Provider.of<UserDataProvider>(context, listen: false).clearAllProvider();
                          Provider.of<ChatProvider>(context, listen: false).clearChats();
                          await logoutUser();
                          Navigator.pushNamedAndRemoveUntil(context, "/login", (route) => false);
                        },
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 40),
                Text(
                  "Chatrox v1.0",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMenuItem({
    required IconData icon, 
    required String title, 
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isDestructive 
            ? Colors.red 
            : Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black87,
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isDestructive 
              ? Colors.red 
              : Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white 
                  : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: Colors.grey,
        size: 20,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
  
  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 70,
      endIndent: 0,
      color: Colors.grey.withOpacity(0.3),
    );
  }

  List<Map<String, String>> _getPrivacyPolicyText() {
    return [
      {
        'title': 'Your Privacy Matters',
        'content': 'Chatrox is designed with your privacy as our top priority. All messages are end-to-end encrypted and we do not store any of your conversations on our servers.',
      },
      {
        'title': 'Information We Collect',
        'content': 'We only collect minimal information required to provide our service, including your phone number, profile name, and optional profile picture. This information is stored securely and is never shared with third parties.',
      },
      {
        'title': 'Message Security',
        'content': 'All messages sent through Chatrox are encrypted end-to-end, meaning only you and your recipient can read them. Not even we can access the content of your messages.',
      },
      {
        'title': 'Data Retention',
        'content': 'Your messages are stored only on your device. If you delete a message, it is permanently removed from our system. You can request deletion of your account at any time.',
      },
    ];
  }

  List<Map<String, String>> _getHelpText() {
    return [
      {
        'title': 'Getting Started',
        'content': 'Chatrox lets you send encrypted messages to your contacts. After signing up, you can start a new conversation by tapping the compose button on the home screen.',
      },
      {
        'title': 'Adding Contacts',
        'content': 'You can add contacts by their phone number. Once added, you can start messaging them securely right away.',
      },
      {
        'title': 'Message Features',
        'content': 'Chatrox supports text messages, images, and files. To send media, tap the attachment icon in the chat screen.',
      },
      {
        'title': 'Troubleshooting',
        'content': 'If you\'re experiencing issues, ensure you have a stable internet connection. You can also try logging out and back in. If problems persist, contact our support team at support@Chatrox.com',
      },
    ];
  }

  List<Map<String, String>> _getAboutText() {
    return [
      {
        'title': 'Chatrox',
        'content': 'Version 1.0.0\nBuilt with Flutter and Appwrite',
      },
      {
        'title': 'Our Mission',
        'content': 'Chatrox was created to provide a secure and private messaging experience. We believe everyone deserves communication tools that respect their privacy.',
      },
      {
        'title': 'Security',
        'content': 'We use industry-standard encryption protocols to ensure your messages remain private and secure.',
      },
      {
        'title': 'Contact Us',
        'content': 'For support or inquiries, please contact us at:\nsupport@Chatrox.com',
      },
    ];
  }
}

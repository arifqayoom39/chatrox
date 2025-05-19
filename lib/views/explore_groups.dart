import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/providers/user_data_provider.dart';

class ExploreGroups extends StatefulWidget {
  const ExploreGroups({super.key});

  @override
  State<ExploreGroups> createState() => _ExploreGroupsState();
}

class _ExploreGroupsState extends State<ExploreGroups> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
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
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
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
        leading: _isSearching 
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: textColor),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
              )
            : null,
        title: _isSearching 
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search groups...',
                  hintStyle: TextStyle(color: subtitleColor),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: textColor, fontSize: 16),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              )
            : Text(
                "Find Groups",
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  letterSpacing: 0.2,
                ),
              ),
        actions: [
          _isSearching 
              ? IconButton(
                  icon: Icon(Icons.clear, color: textColor),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
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
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: () {
              _animationController.reset();
              _animationController.forward();
              setState(() {});
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: FutureBuilder(
          future: getPublicGroups(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
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
                      "Loading groups...",
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError || snapshot.data == null || snapshot.data!.isEmpty) {
              return _buildEmptyState(
                icon: Icons.group_off,
                title: "No groups available",
                subtitle: "Create a new group or try again later",
                textColor: textColor,
                subtitleColor: subtitleColor,
              );
            } else {
              // Filter groups based on search query
              final filteredGroups = snapshot.data!.where((group) {
                final groupName = group.data["group_name"].toString().toLowerCase();
                final groupDesc = group.data["group_desc"].toString().toLowerCase();
                return groupName.contains(_searchQuery) || groupDesc.contains(_searchQuery);
              }).toList();

              if (filteredGroups.isEmpty) {
                return _buildEmptyState(
                  icon: Icons.search_off,
                  title: "No matching groups",
                  subtitle: "Try a different search term",
                  textColor: textColor,
                  subtitleColor: subtitleColor,
                );
              }

              return ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredGroups.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.transparent,
                  height: 2,
                ),
                itemBuilder: (context, index) {
                  final group = filteredGroups[index].data;
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.05),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _animationController,
                      curve: Interval(
                        0.4 + (index * 0.05).clamp(0.0, 0.5),
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
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              // Group details
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  _buildAvatar(group),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          group["group_name"] ?? "Unnamed Group",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          group["group_desc"] ?? "No description",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: subtitleColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  _buildJoinButton(context, group, accentColor, isDarkMode),
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
          },
        ),
      ),
    );
  }
  
  Widget _buildAvatar(Map<String, dynamic> group) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getAvatarColor(group["group_name"] ?? ""),
      ),
      child: group["image"] == "" || group["image"] == null
          ? Center(
              child: Text(
                _getInitials(group["group_name"] ?? "G"),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: CachedNetworkImage(
                imageUrl: "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${group["image"]}/view?project=67cc0b99002c794410a6&mode=admin",
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
                    _getInitials(group["group_name"] ?? "G"),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
  
  Widget _buildJoinButton(BuildContext context, Map<String, dynamic> group, Color accentColor, bool isDarkMode) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          final userId = Provider.of<UserDataProvider>(context, listen: false).getUserId;
          final success = await addUserToGroup(
            groupId: group["\$id"], 
            currentUser: userId,
          );
          
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("You joined the group"),
                backgroundColor: accentColor,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                margin: EdgeInsets.all(8),
              ),
            );
            setState(() {}); // Refresh the list
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? accentColor.withOpacity(0.15) : accentColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Join",
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color textColor,
    required Color subtitleColor,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 60,
            color: subtitleColor.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: subtitleColor,
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
}
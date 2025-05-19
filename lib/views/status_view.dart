import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/models/status_model.dart';
import 'package:chat/models/user_data.dart';
import 'package:chat/providers/status_provider.dart';

class StatusView extends StatefulWidget {
  final List<StatusModel> statuses;
  final String userId; // current user ID

  const StatusView({
    Key? key,
    required this.statuses,
    required this.userId,
  }) : super(key: key);

  @override
  State<StatusView> createState() => _StatusViewState();
}

class _StatusViewState extends State<StatusView> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 5),
    );
    
    _loadStatus(0);
    
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reset();
        if (_currentIndex + 1 < widget.statuses.length) {
          setState(() {
            _currentIndex += 1;
          });
          _pageController.animateToPage(
            _currentIndex,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          Navigator.pop(context);
        }
      }
    });
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _loadStatus(int index) {
    setState(() {
      _currentIndex = index;
    });
    
    // Mark status as viewed
    final status = widget.statuses[index];
    if (status.userId != widget.userId) { // Don't mark your own status as viewed
      Provider.of<StatusProvider>(context, listen: false)
        .viewStatus(status.statusId, widget.userId);
    }
    
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final StatusModel status = widget.statuses[_currentIndex];
    final bool isOwnStatus = status.userId == widget.userId;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) => _animationController.stop(),
        onTapUp: (details) => _animationController.forward(),
        onTapCancel: () => _animationController.forward(),
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0 && _currentIndex > 0) {
            // Swipe right, go to previous
            _animationController.reset();
            _loadStatus(_currentIndex - 1);
          } else if (details.primaryVelocity! < 0 && _currentIndex < widget.statuses.length - 1) {
            // Swipe left, go to next
            _animationController.reset();
            _loadStatus(_currentIndex + 1);
          }
        },
        child: Stack(
          children: [
            // Status content
            PageView.builder(
              controller: _pageController,
              itemCount: widget.statuses.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _animationController.reset();
                _animationController.forward();
              },
              itemBuilder: (context, index) {
                final StatusModel currentStatus = widget.statuses[index];
                return Stack(
                  children: [
                    // Status image
                    Center(
                      child: CachedNetworkImage(
                        imageUrl: "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${currentStatus.imageUrl}/view?project=67cc0b99002c794410a6&mode=admin",
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(color: kPrimaryColor),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                      ),
                    ),
                    
                    // Caption overlay at bottom if available
                    if (currentStatus.caption != null && currentStatus.caption!.isNotEmpty)
                      Positioned(
                        bottom: 80,
                        left: 0,
                        right: 0,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 24),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            currentStatus.caption!,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            
            // Progress indicator
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 10,
              right: 10,
              child: Row(
                children: List.generate(
                  widget.statuses.length,
                  (index) => Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: index == _currentIndex
                          ? AnimatedBuilder(
                              animation: _animationController,
                              builder: (context, child) {
                                return FractionallySizedBox(
                                  widthFactor: _animationController.value,
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : FractionallySizedBox(
                              widthFactor: index < _currentIndex ? 1.0 : 0.0,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Top header with user info
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: status.userData?.profilePic != null &&
                            status.userData!.profilePic!.isNotEmpty
                        ? CachedNetworkImageProvider(
                            "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${status.userData!.profilePic}/view?project=67cc0b99002c794410a6&mode=admin")
                        : AssetImage("assets/user.png") as ImageProvider,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOwnStatus ? "Your Status" : (status.userData?.name ?? "Unknown User"),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getTimeAgo(status.timestamp),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isOwnStatus)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await Provider.of<StatusProvider>(context, listen: false)
                              .removeStatus(status.statusId, widget.userId);
                          if (widget.statuses.length <= 1) {
                            Navigator.pop(context);
                          } else {
                            setState(() {
                              // Handle index after deletion
                              if (_currentIndex >= widget.statuses.length - 1) {
                                _currentIndex = widget.statuses.length - 2;
                              }
                              _loadStatus(_currentIndex);
                            });
                          }
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            
            // Seen by indicator for own status
            if (isOwnStatus && status.viewedBy.isNotEmpty)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () {
                    // Show who viewed the status
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.black.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => Container(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Viewed by ${status.viewCount} ${status.viewCount == 1 ? 'person' : 'people'}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 200,
                              child: FutureBuilder<List<UserData>>(
                                future: _fetchViewerData(status.viewedBy),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                  
                                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                    return Text(
                                      'No viewer information available',
                                      style: TextStyle(color: Colors.white70),
                                    );
                                  }
                                  
                                  return ListView.builder(
                                    itemCount: snapshot.data!.length,
                                    itemBuilder: (context, index) {
                                      final userData = snapshot.data![index];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          backgroundImage: userData.profilePic != null && 
                                                  userData.profilePic!.isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                  "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${userData.profilePic}/view?project=67cc0b99002c794410a6&mode=admin")
                                              : AssetImage("assets/user.png") as ImageProvider,
                                        ),
                                        title: Text(
                                          userData.name ?? "Unknown User",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.remove_red_eye, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '${status.viewCount} ${status.viewCount == 1 ? 'view' : 'views'}',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime) {
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

  Future<List<UserData>> _fetchViewerData(List<String> viewerIds) async {
    List<UserData> viewers = [];
    
    for (String viewerId in viewerIds) {
      try {
        final userResponse = await databases.getDocument(
          databaseId: db,
          collectionId: userCollection,
          documentId: viewerId,
        );
        
        if (userResponse != null) {
          UserData userData = UserData.toMap(userResponse.data);
          viewers.add(userData);
        }
      } catch (e) {
        print("Error fetching viewer data for $viewerId: $e");
      }
    }
    
    return viewers;
  }
}

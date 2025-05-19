import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chat/constants/colors.dart';

class ProfileImageViewer extends StatelessWidget {
  final String? imageUrl;
  final String name;

  const ProfileImageViewer({
    Key? key,
    required this.imageUrl,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String imageFullUrl = imageUrl != null && imageUrl!.isNotEmpty
        ? "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/$imageUrl/view?project=67cc0b99002c794410a6&mode=admin"
        : "";

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Show options for the image (save, share, etc.)
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.grey.shade900,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.save_alt, color: Colors.white),
                      title: const Text(
                        'Save to Gallery',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Implement save functionality here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Saving image...')),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.share, color: Colors.white),
                      title: const Text(
                        'Share',
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Implement share functionality here
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Hero(
              tag: "profile-${name.hashCode}",
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageFullUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: Colors.transparent,
                        child: const CircularProgressIndicator(
                          color: kPrimaryColor,
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 120,
                          color: kPrimaryColor,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 120,
                        color: kPrimaryColor,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

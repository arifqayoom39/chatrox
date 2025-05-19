import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/models/group_model.dart';
import 'package:chat/providers/user_data_provider.dart';

class CreateOrUpdateGroup extends StatefulWidget {
  const CreateOrUpdateGroup({super.key});

  @override
  State<CreateOrUpdateGroup> createState() => _CreateOrUpdateGroupState();
}

class _CreateOrUpdateGroupState extends State<CreateOrUpdateGroup> {
  final _groupKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _groupDescController = TextEditingController();
  bool isPublic = true;

  late String? imageId = "";
  late String userId = "";

  FilePickerResult? _filePickerResult;
  bool _isLoading = false;

  @override
  void initState() {
    userId = Provider.of<UserDataProvider>(context, listen: false).getUserId;
    super.initState();
  }

  // to open file picker
  void _openFilePicker() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    setState(() {
      _filePickerResult = result;
    });
  }

  // upload user profile image and save it to bucket and database
  Future uploadProfileImage() async {
    try {
      if (_filePickerResult != null && _filePickerResult!.files.isNotEmpty) {
        PlatformFile file = _filePickerResult!.files.first;
        final fileByes = await File(file.path!).readAsBytes();
        final inputfile =
            InputFile.fromBytes(bytes: fileByes, filename: file.name);

        // if image already exist for the user profile or not
        if (imageId != null && imageId != "") {
          // then update the image
          await updateImageOnBucket(image: inputfile, oldImageId: imageId!)
              .then((value) {
            if (value != null) {
              imageId = value;
            }
          });
        }

        // create new image and upload to bucket
        else {
          await saveImageToBucket(image: inputfile).then((value) {
            if (value != null) {
              imageId = value;
            }
          });
        }
      } else {
        print("something went wrong");
      }
    } catch (e) {
      print("error on uploading image :$e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final GroupModel? existingData =
        ModalRoute.of(context)?.settings.arguments as GroupModel?;

    if (existingData != null) {
      _groupNameController.text = existingData.groupName ?? "No Name";
      _groupDescController.text = existingData.groupDesc ?? "";
      isPublic = existingData.isPublic;
    }
  }

  @override
  Widget build(BuildContext context) {
    GroupModel? existingData =
        ModalRoute.of(context)?.settings.arguments as GroupModel?;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: _buildAppBar(existingData),
      body: Form(
        key: _groupKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              _buildGroupImagePicker(existingData),
              SizedBox(height: 32),
              _buildSectionTitle("GROUP INFO"),
              SizedBox(height: 8),
              _buildTextField(
                controller: _groupNameController,
                labelText: "Group Name",
                validator: (value) {
                  if (value == null || value.isEmpty) 
                    return "Group name is required";
                  return null;
                },
              ),
              _buildTextField(
                controller: _groupDescController,
                labelText: "Group Description",
                validator: (value) {
                  if (value == null || value.isEmpty) 
                    return "Group description is required";
                  return null;
                },
                maxLines: 3,
              ),
              SizedBox(height: 24),
              _buildSectionTitle("PRIVACY"),
              SizedBox(height: 8),
              _buildPrivacyToggle(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildCreateButton(existingData),
    );
  }

  PreferredSizeWidget _buildAppBar(GroupModel? existingData) {
    return AppBar(
      elevation: 0,
      backgroundColor: kBackgroundColor,
      foregroundColor: Colors.black87,
      centerTitle: true,
      title: Text(
        existingData != null ? "Update Group" : "New Group",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildGroupImagePicker(GroupModel? existingData) {
    return Center(
      child: GestureDetector(
        onTap: () => _openFilePicker(),
        child: Stack(
          children: [
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: _filePickerResult != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(60),
                      child: Image(
                        image: FileImage(
                            File(_filePickerResult!.files.first.path!)),
                        fit: BoxFit.cover,
                      ),
                    )
                  : existingData != null &&
                          existingData.image != null &&
                          existingData.image != ""
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: CachedNetworkImage(
                            imageUrl:
                                "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${existingData.image}/view?project=67cc0b99002c794410a6&mode=admin",
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    kPrimaryColor),
                                strokeWidth: 2,
                              ),
                            ),
                            errorWidget: (context, url, error) => Icon(
                              Icons.group,
                              color: kPrimaryColor,
                              size: 48,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.group,
                          color: kPrimaryColor,
                          size: 48,
                        ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: kBackgroundColor, width: 2),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String? Function(String?) validator,
    int maxLines = 1,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          validator: validator,
          controller: controller,
          decoration: InputDecoration(
            labelText: labelText,
            labelStyle: TextStyle(color: Colors.grey.shade600),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16),
          ),
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
          ),
          maxLines: maxLines,
          minLines: 1,
        ),
      ),
    );
  }

  Widget _buildPrivacyToggle() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(
          "Public Group",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          "Anyone can find and join this group",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),
        trailing: Switch(
          value: isPublic,
          onChanged: (value) {
            setState(() {
              isPublic = value;
            });
          },
          activeColor: kPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildCreateButton(GroupModel? existingData) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading 
              ? null 
              : () async {
                  if (_groupKey.currentState!.validate()) {
                    setState(() {
                      _isLoading = true;
                    });
                    
                    try {
                      if (_filePickerResult != null) {
                        await uploadProfileImage();
                      }
                      
                      bool success = false;
                      // updating the group
                      if (existingData != null) {
                        success = await updateExistingGroup(
                          groupId: existingData.groupId ?? "",
                          groupName: _groupNameController.text,
                          groupDesc: _groupDescController.text,
                          image: imageId == null || imageId == "" 
                            ? existingData.image ?? "" 
                            : imageId ?? "",
                          isOpen: isPublic
                        );
                      }
                      // for create a new group
                      else {
                        success = await createNewGroup(
                          currentUser: userId,
                          groupName: _groupNameController.text,
                          groupDesc: _groupDescController.text,
                          image: imageId ?? "",
                          isOpen: isPublic
                        );
                      }
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 10),
                                Text(
                                  existingData != null 
                                    ? "Group updated successfully" 
                                    : "Group created successfully"
                                ),
                              ],
                            ),
                            backgroundColor: kSecureGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: EdgeInsets.all(10),
                            elevation: 0,
                          )
                        );
                        Navigator.pop(context);
                      } else {
                        _showErrorSnackbar(
                          existingData != null
                            ? "Failed to update group" 
                            : "Failed to create group"
                        );
                      }
                    } catch (e) {
                      _showErrorSnackbar("Error: $e");
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: kPrimaryColor.withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  existingData != null ? "Save Changes" : "Create Group",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
          ),
        ),
      ),
    );
  }
  
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text(message)),
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

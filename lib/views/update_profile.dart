import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/providers/user_data_provider.dart';

class UpdateProfile extends StatefulWidget {
  const UpdateProfile({super.key});

  @override
  State<UpdateProfile> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();

  FilePickerResult? _filePickerResult;

  late String? imageId = "";
  late String? userId = "";

  final _namekey = GlobalKey<FormState>();

  @override
  void initState() {
    // try to load the data from local database
    Future.delayed(Duration.zero, () {
      userId = Provider.of<UserDataProvider>(context, listen: false).getUserId;
      Provider.of<UserDataProvider>(context, listen: false)
          .loadUserData(userId!);
      imageId =
          Provider.of<UserDataProvider>(context, listen: false).getUserProfile;
    });

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
  Widget build(BuildContext context) {
    final Color signalBlue = const Color(0xFF2C6BED); // Exact Signal blue color
    final Map<String, dynamic> datapassed =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    return Consumer<UserDataProvider>(
      builder: (context, value, child) {
        _nameController.text = value.getUserName;
        _phoneController.text = value.getUserNumber;
        imageId = value.getUserProfile;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            title: Text(
              datapassed["title"] == "edit" ? "Update Profile" : "Set Up Profile",
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    _openFilePicker();
                  },
                  child: Stack(children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade100,
                      ),
                      child: _filePickerResult != null || (value.getUserProfile != "" && value.getUserProfile != null)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(75),
                            child: _filePickerResult != null
                              ? Image.file(
                                  File(_filePickerResult!.files.first.path!),
                                  fit: BoxFit.cover,
                                )
                              : CachedNetworkImage(
                                  imageUrl: "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/${value.getUserProfile}/view?project=67cc0b99002c794410a6&mode=admin",
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      color: signalBlue,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                            )
                        : Icon(
                            Icons.person_outline_rounded,
                            size: 70,
                            color: Colors.grey.shade400,
                          ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: signalBlue,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Form(
                    key: _namekey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: TextFormField(
                            validator: (value) {
                              if (value!.isEmpty) return "Name is required";
                              return null;
                            },
                            controller: _nameController,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: "Enter your name",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              fillColor: Colors.transparent,
                              filled: false,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade300,
                                width: 1.0,
                              ),
                            ),
                          ),
                          child: TextFormField(
                            controller: _phoneController,
                            enabled: false,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                            decoration: InputDecoration(
                              hintText: "Phone Number",
                              hintStyle: TextStyle(
                                color: Colors.grey.shade400,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                              fillColor: Colors.transparent,
                              filled: false,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              disabledBorder: InputBorder.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: SizedBox(
                    height: 50,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        print("current image id is $imageId");
                        if (_namekey.currentState!.validate()) {
                          // upload the image if file is picked
                          if (_filePickerResult != null) {
                            await uploadProfileImage();
                          }

                          // save the data to database user collection
                          await updateUserDetails(imageId ?? "",
                              userId: userId!, name: _nameController.text);

                          // navigate the user to the home route
                          Navigator.pushNamedAndRemoveUntil(
                              context, "/home", (route) => false);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: signalBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        datapassed["title"] == "edit" ? "Save Changes" : "Next",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat/constants/colors.dart';
import 'package:chat/controllers/appwrite_controllers.dart';
import 'package:chat/providers/user_data_provider.dart';

class EmailUpdateProfile extends StatefulWidget {
  const EmailUpdateProfile({Key? key}) : super(key: key);

  @override
  State<EmailUpdateProfile> createState() => _EmailUpdateProfileState();
}

class _EmailUpdateProfileState extends State<EmailUpdateProfile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  FilePickerResult? _filePickerResult;
  String? imageId = "";
  String? userId = "";
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () async {
      userId = Provider.of<UserDataProvider>(context, listen: false).getUserId;
      _emailController.text = Provider.of<UserDataProvider>(context, listen: false).getUserEmail;
      _nameController.text = Provider.of<UserDataProvider>(context, listen: false).getUserName;
      _phoneController.text = Provider.of<UserDataProvider>(context, listen: false).getUserNumber;
      imageId = Provider.of<UserDataProvider>(context, listen: false).getUserProfile;
      
      // Ensure user document exists in database FIRST - before any other operations
      bool exists = await userDocumentExists(userId: userId!);
      if (!exists) {
        print("Creating user document for new signup: $userId");
        await createUserDocumentIfNotExists(
          userId: userId!,
          email: _emailController.text,
          name: _nameController.text,
          phoneNo: _phoneController.text
        );
      }
    });
  }

  void _openFilePicker() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    setState(() {
      _filePickerResult = result;
    });
  }

  Future<String?> uploadProfileImage() async {
    try {
      if (_filePickerResult != null && _filePickerResult!.files.isNotEmpty) {
        PlatformFile file = _filePickerResult!.files.first;
        final fileBytes = await File(file.path!).readAsBytes();
        final inputFile = InputFile.fromBytes(bytes: fileBytes, filename: file.name);

        if (imageId != null && imageId!.isNotEmpty) {
          // Update existing image
          return await updateImageOnBucket(image: inputFile, oldImageId: imageId!);
        } else {
          // Create new image
          return await saveImageToBucket(image: inputFile);
        }
      }
      return imageId;
    } catch (e) {
      print("Error uploading profile image: $e");
      return null;
    }
  }

  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // First ensure document exists
        bool exists = await userDocumentExists(userId: userId!);
        if (!exists) {
          // Create document first if it doesn't exist
          await createUserDocumentIfNotExists(
            userId: userId!,
            email: _emailController.text,
            name: _nameController.text,
            phoneNo: _phoneController.text
          );
        }
        
        // Upload profile image if selected
        final uploadedImageId = await uploadProfileImage();
        final finalImageId = uploadedImageId ?? imageId ?? "";
        
        // Now update the document (which we know exists)
        bool success = await updateUserDetails(
          finalImageId,
          userId: userId!,
          name: _nameController.text,
          phoneNumber: _phoneController.text,
        );
        
        // Update phone number separately
        if (success && _phoneController.text.isNotEmpty) {
          await updateUserPhoneNumber(
            userId: userId!,
            phoneNumber: _phoneController.text,
          );

          // Update in provider
          Provider.of<UserDataProvider>(context, listen: false).setUserPhone(_phoneController.text);
        }

        if (success) {
          // Update user data in provider
          Provider.of<UserDataProvider>(context, listen: false).setUserName(_nameController.text);
          if (finalImageId.isNotEmpty) {
            Provider.of<UserDataProvider>(context, listen: false).setProfilePic(finalImageId);
          }

          // Navigate to home screen
          Navigator.pushNamedAndRemoveUntil(context, "/home", (route) => false);
        } else {
          setState(() {
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Failed to update profile. Please try again."),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complete Your Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : Consumer<UserDataProvider>(
              builder: (context, userProvider, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Profile Image Section
                        GestureDetector(
                          onTap: _openFilePicker,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 80,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _filePickerResult != null
                                    ? FileImage(File(_filePickerResult!.files.first.path!))
                                    : (imageId != null && imageId!.isNotEmpty)
                                        ? CachedNetworkImageProvider(
                                            "https://cloud.appwrite.io/v1/storage/buckets/670a3db8000bd6aa32b7/files/$imageId/view?project=67cc0b99002c794410a6&mode=admin") as ImageProvider<Object>
                                        : null,
                                child: (_filePickerResult == null && (imageId == null || imageId!.isEmpty))
                                    ? const Icon(Icons.person, size: 80, color: Colors.grey)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 24),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Name Field
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: "Full Name",
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your name";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // Email Field (Read-only)
                        TextFormField(
                          controller: _emailController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: "Email",
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                            helperText: "Email cannot be changed",
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Phone Field (Optional, no verification)
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: "Phone Number (Optional)",
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                            helperText: "Add your phone number for contact syncing",
                            prefixText: "+91 ",
                          ),
                          keyboardType: TextInputType.phone,
                        ),

                        const SizedBox(height: 16),

                        // Replace the info text with a note about the phone number
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Phone number is optional. Adding one helps friends find you via their contacts.",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Continue to App',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

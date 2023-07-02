// ignore_for_file: library_private_types_in_public_api, file_names, use_build_context_synchronously, library_prefixes

import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as Path;
import 'package:sqflite/sqflite.dart';

class ProfilAkunKonsumenPage extends StatefulWidget {
  static const routeName = '/useraccount';

  const ProfilAkunKonsumenPage({Key? key}) : super(key: key);

  @override
  _ProfilAkunKonsumenPageState createState() => _ProfilAkunKonsumenPageState();
}

class _ProfilAkunKonsumenPageState extends State<ProfilAkunKonsumenPage> {
  late String _userId;
  String? _profilePhoto;
  String _name = '';
  String _email = '';
  String _address = '';
  String _phoneNumber = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userId = user.uid;
      });
      await _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('konsumen')
          .doc(_userId)
          .get();

      setState(() {
        _profilePhoto = userData.get('profile_photo') as String?;
        _name = userData.get('name') as String;
        _email = userData.get('email') as String;
        _address = userData.get('address') as String;
        _phoneNumber = userData.get('phone_number') as String;
      });
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching user data: $error');
      }
    }
  }

  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _isUploading = true;
      });

      File imageFile = File(pickedFile.path);

      // Compress the image before uploading
      Uint8List? compressedImage = await FlutterImageCompress.compressWithFile(
        imageFile.path,
        minWidth: 500,
        minHeight: 500,
        quality: 80,
      );

      // Create a temporary file for the compressed image
      Directory tempDir = await getTemporaryDirectory();
      File compressedFile = File('${tempDir.path}/compressed_image.jpg');
      await compressedFile.writeAsBytes(compressedImage as List<int>);

      String fileName = 'profile_photo.jpg';

      try {
        Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('konsumen')
            .child(_userId)
            .child(fileName);
        await storageRef.putFile(compressedFile);
        String downloadURL = await storageRef.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('konsumen')
            .doc(_userId)
            .update({'profile_photo': downloadURL});

        setState(() {
          _profilePhoto = downloadURL;
          _isUploading = false;
        });

        Fluttertoast.showToast(
          msg: 'Photo uploaded successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        // Reload user data to show updated profile photo
        await _fetchUserData();
      } catch (error) {
        if (kDebugMode) {
          print('Error uploading profile photo: $error');
        }
        setState(() {
          _isUploading = false;
        });
      } finally {
        // Delete the temporary compressed file
        compressedFile.deleteSync();
      }
    }
  }

  Future<void> _showEditProfileModal() async {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final addressController = TextEditingController(text: _address);
    final phoneNumberController = TextEditingController(text: _phoneNumber);
    final passwordController = TextEditingController();

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter an email';
                        }
                        if (!isValidEmail(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                      ),
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter an address';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a phone number';
                        }
                        if (!isValidPhoneNumber(value)) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Please enter a password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          // Validations pass

                          String name = nameController.text.trim();
                          String email = emailController.text.trim();
                          String address = addressController.text.trim();
                          String phoneNumber =
                              phoneNumberController.text.trim();
                          String password = passwordController.text.trim();

                          try {
                            User? user = FirebaseAuth.instance.currentUser;
                            if (user != null) {
                              AuthCredential credential =
                                  EmailAuthProvider.credential(
                                email: user.email!,
                                password: password,
                              );
                              await user
                                  .reauthenticateWithCredential(credential);

                              // Update email in Firebase Authentication
                              await user.updateEmail(email);

                              // Update fields in Firestore
                              await FirebaseFirestore.instance
                                  .collection('konsumen')
                                  .doc(_userId)
                                  .update({
                                'name': name,
                                'email': email,
                                'address': address,
                                'phone_number': phoneNumber,
                              });

                              Fluttertoast.showToast(
                                msg: 'Profile updated successfully',
                                toastLength: Toast.LENGTH_SHORT,
                                gravity: ToastGravity.BOTTOM,
                              );

                              Navigator.pop(context); // Close the modal
                              await _fetchUserData(); // Reload user data
                            }
                          } catch (error) {
                            if (kDebugMode) {
                              print('Error updating profile: $error');
                            }
                            Fluttertoast.showToast(
                              msg: 'Failed to update profile',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.BOTTOM,
                            );
                          }
                        }
                      },
                      child: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool isValidEmail(String email) {
    // Use a regular expression to validate the email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool isValidPhoneNumber(String phoneNumber) {
    // Use a regular expression to validate the phone number format
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    return phoneRegex.hasMatch(phoneNumber);
  }

  Future<void> _showChangePasswordModal() async {
    final newPasswordController = TextEditingController();
    final confirmNewPasswordController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Change Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: confirmNewPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      String newPassword = newPasswordController.text.trim();
                      String confirmNewPassword =
                          confirmNewPasswordController.text.trim();

                      if (newPassword.isEmpty || confirmNewPassword.isEmpty) {
                        Fluttertoast.showToast(
                          msg: 'Please fill in all fields',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                        return;
                      }

                      if (newPassword != confirmNewPassword) {
                        Fluttertoast.showToast(
                          msg: 'Passwords do not match',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                        return;
                      }

                      try {
                        final databasePath = await getDatabasesPath();
                        final path = Path.join(databasePath, 'session_data.db');
                        Database database = await openDatabase(path);
                        List<Map<String, dynamic>> sessionData =
                            await database.rawQuery('SELECT * FROM session');
                        String userId = sessionData[0]['user_id'] as String;

                        User? user = FirebaseAuth.instance.currentUser;
                        if (user != null && userId == user.uid) {
                          await user.updatePassword(newPassword);

                          Fluttertoast.showToast(
                            msg: 'Password changed successfully',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );

                          Navigator.pop(context); // Close the modal
                        } else {
                          Fluttertoast.showToast(
                            msg: 'User authentication failed',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                          );
                        }
                      } catch (error) {
                        if (kDebugMode) {
                          print('Error changing password: $error');
                        }
                        Fluttertoast.showToast(
                          msg: 'Failed to change password',
                          toastLength: Toast.LENGTH_SHORT,
                          gravity: ToastGravity.BOTTOM,
                        );
                      }
                    },
                    child: const Text('Change Password'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Account')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 250,
                    width: 250,
                    child: ClipRRect(
                      child: _profilePhoto != null && _profilePhoto!.isNotEmpty
                          ? Image.network(_profilePhoto!, fit: BoxFit.cover)
                          : const Icon(Icons.person, size: 80),
                    ),
                  ),
                  if (_isUploading) const CircularProgressIndicator(),
                ],
              ),
              const SizedBox(height: 30),
              ProfileField(label: 'Name', value: _name),
              const SizedBox(height: 10),
              ProfileField(label: 'Email', value: _email),
              const SizedBox(height: 10),
              ProfileField(label: 'Address', value: _address),
              const SizedBox(height: 10),
              ProfileField(label: 'Phone Number', value: _phoneNumber),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _uploadProfilePhoto,
                child: Text(
                  _profilePhoto != null ? 'Change Photo' : 'Upload Photo',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _showEditProfileModal,
                child: const Text('Change Profile Details'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _showChangePasswordModal(),
                child: const Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileField extends StatelessWidget {
  final String label;
  final String value;

  const ProfileField({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}

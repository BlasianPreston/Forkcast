import 'dart:io';
import 'package:calorie_app/macro_updating_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  bool imageError = false;
  String? imageErrorText;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isSigningOut = false;

  Future<void> _pickFromGallery(String uid) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });

      String uniqueFileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference referenceRoot = FirebaseStorage.instance.ref();
      Reference referenceDirImages = referenceRoot.child('images');
      Reference referenceImageToUpload = referenceDirImages.child(
        uniqueFileName,
      );

      try {
        await referenceImageToUpload.putFile(File(pickedFile.path));

        // 4. Get the download URL
        String downloadUrl = await referenceImageToUpload.getDownloadURL();
        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .set(
          {
            "profilePicture": downloadUrl,
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        imageError = true;
        imageErrorText = e.toString();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Check if uid is null and sign out if needed
    User? user = FirebaseAuth.instance.currentUser;
    String? uid = user?.uid;
    if (uid == null) {
      _isSigningOut = true;
      FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get current user and uid
    User? user = FirebaseAuth.instance.currentUser;
    String? uid = user?.uid;

    // If uid is null, sign out and show loading (AuthGate will handle redirect)
    if (uid == null || _isSigningOut) {
      if (!_isSigningOut) {
        _isSigningOut = true;
        FirebaseAuth.instance.signOut();
      }
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return FutureBuilder(
      future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: Text("Error loading user data"));
        }
        
        var dataMap = snapshot.data!.data();
        if (dataMap == null) {
          return const Center(child: Text("No user data found"));
        }
        
        // profilePicture is a URL string, not a file path, so we store it separately
        String? profilePictureUrl = dataMap['profilePicture'] as String?;
        
        return Scaffold(
          appBar: AppBar(
            title: Text("Account Page", style: TextStyle(fontSize: 24.0)),
            centerTitle: true,
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                children: [
                  SizedBox(height: 100),
                  ElevatedButton(
                    onPressed: () => _pickFromGallery(uid),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _imageFile != null
                        ? ClipOval(
                            child: Image.file(
                              _imageFile!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : profilePictureUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  profilePictureUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.account_circle,
                                      color: Colors.black,
                                      size: 100.0,
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.account_circle,
                                color: Colors.black,
                                size: 100.0,
                              ),
                  ),
                  SizedBox(height: 50),
                  Text(dataMap['name'] ?? ''),
                  SizedBox(height: 50),
                  Text(dataMap['email'] ?? ''),
                  SizedBox(height: 50),
                  MacroUpdatingTextField(
                    initialValue: dataMap['height']?.toString() ?? '',
                    label: 'Height',
                    unit: 'in',
                    profileField: 'height',
                    currentData: dataMap,
                  ),
                  SizedBox(height: 50),
                  MacroUpdatingTextField(
                    initialValue: dataMap['weight']?.toString() ?? '',
                    label: 'Weight',
                    unit: 'lbs',
                    profileField: 'weight',
                    currentData: dataMap,
                  ),
                  SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(255, 0, 0, 1),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                    ),
                    child: const Text(
                      "Sign Out",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

import 'dart:io';
import 'package:calorie_app/splash_page.dart';
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
  late User? user = FirebaseAuth.instance.currentUser;
  late String? uid = user?.uid;
  bool imageError = false;
  String? imageErrorText;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  Future<void> _pickFromGallery() async {
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
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "profilePicture": downloadUrl,
        });
      } catch (e) {
        imageError = true;
        imageErrorText = e.toString();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance.collection("users").doc(uid).get(),
      builder: (context, snapshot) {
        var data = snapshot.data!;
        _imageFile = File(data['profilePicture']);
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
                    onPressed: _pickFromGallery,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _imageFile == null
                        ? Icon(
                            Icons.account_circle,
                            color: Colors.black,
                            size: 100.0,
                          )
                        : ClipOval(
                            child: Image.file(
                              _imageFile!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                  SizedBox(height: 50),
                  Text(data['name']),
                  SizedBox(height: 50),
                  Text(data['email']),
                  SizedBox(height: 50),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => SplashPage()),
                      );
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

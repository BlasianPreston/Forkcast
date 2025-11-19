import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text("Account Page", style: TextStyle(fontSize: 24.0)),
        ),
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
              const Text("Name"),
              SizedBox(height: 50),
              const Text("Email"),
              SizedBox(height: 50),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromRGBO(255, 0, 0, 1),
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
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera_macos/camera_macos.dart';

class PhotoPicker {
  final ImagePicker _picker = ImagePicker();
  late CameraMacOSController? _macController;

  Future<String?> pickImage({required bool fromCamera}) async {
    if (Platform.isMacOS) {
      if (fromCamera) {
        // Use macOS camera
        CameraMacOSFile? file = await _macController?.takePicture();
        if (file != null) {
          return file.url;
        }
      } else {
        // Use gallery picker on macOS
        final XFile? file = await _picker.pickImage(
          source: ImageSource.gallery,
        );
        return file?.path;
      }
    } else {
      // iOS / Android
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? file = await _picker.pickImage(source: source);
      return file?.path;
    }
    return null;
  }
}

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

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
        title: Center(
          child: const Text("Camera Page", style: TextStyle(fontSize: 24.0)),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            children: [
              if (_imageFile != null) ...[
                SizedBox(height: 20),
                Image.file(_imageFile!, height: 250),
              ] else ...[
                SizedBox(height: 100),
                const Text('No image selected'),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _takePhoto,
                child: const Text('Take Photo'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFromGallery,
                child: const Text('Pick from Gallery'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                maxLines: 5, // makes it a multiline box
                minLines: 1,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: "Additional Comments (Optional)",
                  alignLabelWithHint:
                      true, // keeps label at top-left for multiline
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  hintText: "Enter any extra details here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blueAccent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    null;
                  }, // Change this after backend is done
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 32,
                    ),
                  ),
                  child: const Text(
                    "Submit Meal",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

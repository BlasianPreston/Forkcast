import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera_macos/camera_macos.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  File? _imageFile;
  final foodNameController = TextEditingController();
  final commentsController = TextEditingController();
  Map<String, dynamic>? nutritionData;
  bool isError = false;
  String? isErrorText;

  final ImagePicker _picker = ImagePicker();
  late CameraMacOSController? _macController;

  Future<String?> pickImage({required bool fromCamera}) async {
    if (Platform.isMacOS) {
      if (fromCamera) {
        // Use macOS camera
        CameraMacOSFile? file = await _macController?.takePicture();
        if (file != null) {
          setState(() {
            _imageFile = File(file.url!);
          });
        }
      } else {
        // Use gallery picker on macOS
        final XFile? file = await _picker.pickImage(
          source: ImageSource.gallery,
        );
        if (file != null) {
          setState(() {
            _imageFile = File(file.path);
          });
        }
      }
    } else {
      // iOS / Android
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? file = await _picker.pickImage(source: source);
      if (file != null) {
        setState(() {
          _imageFile = File(file.path);
        });
      }
    }
    return null;
  }

  void _clearScreen() {
    foodNameController.clear();
    commentsController.clear();

    setState(() {
      _imageFile = null;
      nutritionData = null;
      isError = false;
      isErrorText = null;
    });
  }

  Future<String?> askGeminiAboutImage(File imageFile) async {
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: dotenv.get('GEMINI_API_KEY'),
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
    );

    // 2. Prepare the image data
    // We read the file as bytes because Gemini needs raw data
    final imageBytes = await imageFile.readAsBytes();

    String promptText = """
      Analyze this food image. Return a JSON object with exactly these keys:
      - "meal_name" (string)
      - "calorie_estimate" (integer)
      - "protein_estimate" (integer)
      - "carb_estimate" (integer)
      - "fat_estimate" (integer)

      Do not wrap the response in markdown code blocks. Return raw JSON only.
      """;

    // 3. Define the content
    final content = [
      Content.multi([
        TextPart(promptText),
        DataPart('image/jpeg', imageBytes),
        TextPart(foodNameController.text.trim()),
        TextPart(commentsController.text.trim()),
      ]),
    ];

    try {
      // 4. Send the request
      final response = await model.generateContent(content);
      String? responseText = response.text;

      if (responseText == null) return null;

      // Handles AI adding backticks to response
      responseText = responseText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      setState(() {
        nutritionData = jsonDecode(responseText!);
      });
    } catch (e) {
      setState(() {
        isError = true;
        isErrorText = e.toString();
      });
    }

    late User? user = FirebaseAuth.instance.currentUser;
    late String? uid = user?.uid;

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid!)
          .child('meal_images')
          .child("$fileName.jpg");

      await storageRef.putFile(imageFile);

      // Get the public link (URL)
      String downloadUrl = await storageRef.getDownloadURL();

      Map<String, dynamic> mealData = {
        'name': foodNameController.text.trim(),
        'comments': commentsController.text.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'image_url': downloadUrl,
        ...?nutritionData,
      };

      await FirebaseFirestore.instance
          .collection('meals')
          .doc(uid)
          .collection('meals')
          .add(mealData);

      // Show success message or pop page
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Meal Saved!")));
      }
      _clearScreen();
    } catch (e) {
      isError = true;
      isErrorText = e.toString();
    }
    return null;
  }

  @override
  void dispose() {
    foodNameController.dispose();
    commentsController.dispose();
    super.dispose();
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
                onPressed: () {
                  pickImage(fromCamera: true);
                },
                child: const Text('Take Photo'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  pickImage(fromCamera: false);
                },
                child: const Text('Pick from Gallery'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                maxLines: 1,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: "Name of Meal",
                  alignLabelWithHint:
                      true, // keeps label at top-left for multiline
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  hintText: "Enter the name of your meal",
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
                    _imageFile != null
                        ? () async {
                            await askGeminiAboutImage(_imageFile!);
                          }
                        : null;
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

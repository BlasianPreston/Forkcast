import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
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
  XFile? _imageFile;
  final foodNameController = TextEditingController();
  final commentsController = TextEditingController();
  Map<String, dynamic>? nutritionData;
  bool isError = false;
  String? isErrorText;
  bool isProcessing = false;

  final ImagePicker _picker = ImagePicker();
  late CameraMacOSController? _macController;

  Future<String?> pickImage({required bool fromCamera}) async {
    if (kIsWeb) {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? file = await _picker.pickImage(source: source);
      if (file != null) {
        setState(() {
          _imageFile = file;
        });
      }
    } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      if (fromCamera) {
        CameraMacOSFile? file = await _macController?.takePicture();
        if (file != null && file.url != null) {
          setState(() {
            _imageFile = XFile(file.url!);
          });
        }
      } else {
        final XFile? file = await _picker.pickImage(
          source: ImageSource.gallery,
        );
        if (file != null) {
          setState(() {
            _imageFile = file;
          });
        }
      }
    } else {
      final source = fromCamera ? ImageSource.camera : ImageSource.gallery;
      final XFile? file = await _picker.pickImage(source: source);
      if (file != null) {
        setState(() {
          _imageFile = file;
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

  Future<String?> askGeminiAboutImage(XFile imageFile) async {
    setState(() {
      isProcessing = true;
      isError = false;
      isErrorText = null;
    });

    String? geminiApiKey;
    try {
      geminiApiKey = dotenv.get('GEMINI_API_KEY');
      if (geminiApiKey.isEmpty || geminiApiKey == 'YOUR_GEMINI_API_KEY') {
        geminiApiKey = null;
      }
    } catch (e) {
      geminiApiKey = null;
    }

    GenerativeModel? model;
    if (geminiApiKey != null) {
      model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: geminiApiKey,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );
    }

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

    final content = [
      Content.multi([
        TextPart(promptText),
        DataPart('image/jpeg', imageBytes),
        TextPart(foodNameController.text.trim()),
        TextPart(commentsController.text.trim()),
      ]),
    ];

    User? user = FirebaseAuth.instance.currentUser;
    String? uid = user?.uid;
    
    if (uid == null) {
      setState(() {
        isError = true;
        isErrorText = "User not authenticated";
      });
      return null;
    }

    if (model != null) {
      try {
        final response = await model.generateContent(content).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException("Gemini API request timed out");
          },
        );
        String? responseText = response.text;

        if (responseText != null) {
          responseText = responseText
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          setState(() {
            nutritionData = jsonDecode(responseText!);
          });
        }
      } catch (e) {
        setState(() {
          isError = true;
          isErrorText = "Failed to analyze image: ${e.toString()}";
        });
      }
    }

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(uid)
          .child('meal_images')
          .child("$fileName.jpg");

      final imageBytes = await imageFile.readAsBytes();
      
      final uploadTask = storageRef.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      
      final uploadSnapshot = await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          uploadTask.cancel();
          throw TimeoutException("Storage upload timed out");
        },
      );
      
      if (uploadSnapshot.state != TaskState.success) {
        throw Exception("Upload failed with state: ${uploadSnapshot.state}");
      }

      String downloadUrl = await storageRef.getDownloadURL().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("getDownloadURL timed out");
        },
      );
      
      if (downloadUrl.isEmpty) {
        throw Exception("Download URL is empty");
      }
      if (!downloadUrl.startsWith('http://') && !downloadUrl.startsWith('https://')) {
        throw Exception("Download URL is not a valid HTTP/HTTPS URL: $downloadUrl");
      }

      String foodName = foodNameController.text.trim();
      if (foodName.isEmpty) {
        foodName = nutritionData?['meal_name']?.toString() ?? "Unnamed Meal";
      }

      Map<String, dynamic> mealData = {
        'food_name': foodName,
        'comments': commentsController.text.trim(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'image_url': downloadUrl,
        'calorie_estimate': (nutritionData?['calorie_estimate'] as num?)?.toInt() ?? 0,
        'protein': (nutritionData?['protein_estimate'] as num?)?.toInt() ?? 0,
        'carbs': (nutritionData?['carb_estimate'] as num?)?.toInt() ?? 0,
        'fats': (nutritionData?['fat_estimate'] as num?)?.toInt() ?? 0,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meals')
          .add(mealData)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException("Firestore save timed out");
            },
          );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Meal Saved!")));
      }
      _clearScreen();
    } catch (e) {
      setState(() {
        isError = true;
        isErrorText = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving meal: ${e.toString()}")),
        );
      }
    } finally {
      setState(() {
        isProcessing = false;
      });
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
                FutureBuilder<Uint8List>(
                  future: _imageFile!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 250,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        height: 250,
                        fit: BoxFit.contain,
                      );
                    }
                    return const SizedBox(height: 250);
                  },
                ),
              ] else ...[
                SizedBox(height: 100),
                const Text('No image selected'),
              ],
              if (isError) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    isErrorText ?? "An error occurred",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
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
                controller: foodNameController,
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
                controller: commentsController,
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
                  onPressed: (_imageFile != null && !isProcessing)
                      ? () async {
                          await askGeminiAboutImage(_imageFile!);
                        }
                      : null,
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
                  child: isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
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

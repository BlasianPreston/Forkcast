import 'package:calorie_app/macro_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MacroUpdatingTextField extends StatefulWidget {
  final String initialValue;
  final String label;
  final String unit;
  final String profileField;
  final Map<String, dynamic> currentData;

  const MacroUpdatingTextField({
    super.key,
    required this.initialValue,
    required this.label,
    required this.unit,
    required this.profileField,
    required this.currentData,
  });

  @override
  State<MacroUpdatingTextField> createState() => _MacroUpdatingTextFieldState();
}

class _MacroUpdatingTextFieldState extends State<MacroUpdatingTextField> {
  late TextEditingController _controller;
  bool isEditing = false;
  late User? user = FirebaseAuth.instance.currentUser;
  late String? uid = user?.uid;

  Future<void> _updateHeightOrWeightAndMacros(String value) async {
    try {
      // Get current values
      double weightLbs = double.tryParse(widget.currentData['weight']?.toString() ?? '') ?? 0.0;
      double heightIn = double.tryParse(widget.currentData['height']?.toString() ?? '') ?? 0.0;
      int age = int.tryParse(widget.currentData['age']?.toString() ?? '') ?? 0;
      String sex = widget.currentData['sex']?.toString() ?? '';

      // Update the field that was changed
      if (widget.profileField == 'height') {
        heightIn = double.tryParse(value) ?? heightIn;
      } else if (widget.profileField == 'weight') {
        weightLbs = double.tryParse(value) ?? weightLbs;
      }

      // Only recalculate macros if we have all required data
      if (weightLbs > 0 && heightIn > 0 && age > 0 && sex.isNotEmpty) {
        MacroResult mr = calculateMacros(
          weightLbs: weightLbs,
          heightIn: heightIn,
          age: age,
          sex: sex,
        );

        // Update both the field and macros
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          widget.profileField: value,
          "daily_cals": mr.calories,
          "daily_protein": mr.protein,
          "daily_fats": mr.fat,
          "daily_carbs": mr.carbs,
        }, SetOptions(merge: true));
      } else {
        // If we don't have all data, just update the field
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          widget.profileField: value,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        isEditing
            ? TextField(
                controller: _controller,
                autofocus: true,
                onSubmitted: (value) {
                  setState(() {
                    isEditing = false;
                  });
                  _updateHeightOrWeightAndMacros(value);
                },
              )
            : GestureDetector(
                onTap: () => setState(() => isEditing = true),
                child: Text(
                  '${widget.label}: ${_controller.text} ${widget.unit}',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
      ],
    );
  }
}


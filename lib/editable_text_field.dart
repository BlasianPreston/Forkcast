import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditableTextField extends StatefulWidget {
  final String initialValue;
  final String label;
  final String profileField;
  final String unit;

  const EditableTextField({
    super.key,
    required this.initialValue,
    required this.label,
    required this.profileField,
    required this.unit,
  });

  @override
  State<EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  late User? user = FirebaseAuth.instance.currentUser;
  late String? uid = user?.uid;
  late TextEditingController _controller;
  bool isEditing = false;

  Future<void> onProfileSubmit(String databaseField, String value) async {
    isEditing = false;
    try {
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        databaseField: value,
      });
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
                  onProfileSubmit(widget.profileField, value);
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

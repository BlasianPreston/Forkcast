import 'package:flutter/material.dart';

class EditableTextField extends StatefulWidget {
  final String initialValue;
  final String label;

  const EditableTextField({
    super.key,
    required this.initialValue,
    required this.label,
  });

  @override
  State<EditableTextField> createState() => _EditableTextFieldState();
}

class _EditableTextFieldState extends State<EditableTextField> {
  late TextEditingController _controller;
  bool isEditing = false;

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
        Text(widget.label, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),

        isEditing
            ? TextField(
                controller: _controller,
                autofocus: true,
                onSubmitted: (value) {
                  setState(() => isEditing = false);
                },
              )
            : GestureDetector(
                onTap: () => setState(() => isEditing = true),
                child: Text(
                  _controller.text,
                  style: const TextStyle(fontSize: 18, color: Colors.black),
                ),
              ),
      ],
    );
  }
}

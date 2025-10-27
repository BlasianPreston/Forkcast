import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Center(child: const Text("AI Calorie Tracker"))),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Form(
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (value) {
                    if (value == null || !(value.contains("@"))) {
                      return "Please enter your email";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Name"),
                  validator: (value) {
                    if (value == null || value.length < 3) {
                      return "Please enter your name";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: "Password"),
                  validator: (value) {
                    if (value == null || value.length < 8) {
                      return "Please enter an 8 character long password at minimum";
                    }
                    return null;
                  }
                ),
                const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: null, // Change this when making frontend reaction
                    child: const Text("Sign Up")
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:calorie_app/login_page.dart';
import 'package:calorie_app/macro_result.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final ageController = TextEditingController();
  String? sex = "Male";
  bool logInError = false;
  String? logInErrorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
    ageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forkcast Sign Up", style: TextStyle(fontSize: 24.0)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Form(
            child: Column(
              children: [
                SizedBox(
                  height: 175,
                  width: double.infinity,
                  child: SvgPicture.asset(
                    'assets/transparent-logo.svg',
                    fit: BoxFit.contain,
                  ),
                ),
                if (logInError) ...[
                  SizedBox(height: 20),
                  Text(
                    logInErrorText ?? "Unknown Error",
                    style: const TextStyle(color: Colors.red),
                  ),
                ] else
                  ...[],
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: "Email"),
                        validator: (value) {
                          if (value == null || !(value.contains("@"))) {
                            return "Please enter your email";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: "Name"),
                        validator: (value) {
                          if (value == null || value.length < 3) {
                            return "Please enter your name";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: "Password",
                        ),
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return "Please enter an 8 character long password at minimum";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: heightController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: "Height (in inches)",
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Please enter a valid height";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: weightController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: "Weight (in pounds)",
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Please enter a valid weight";
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: "Age (in years)",
                        ),
                        validator: (value) {
                          if (value == null) {
                            return "Please enter your age";
                          }
                          return null;
                        },
                      ),
                      Center(
                        child: RadioGroup<String>(
                          groupValue: sex,
                          onChanged: (String? gender) {
                            setState(() {
                              sex = gender;
                            });
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Radio<String>(value: "Male"),
                              const Text("Male"),
                              SizedBox(width: 20),
                              Radio<String>(value: "Female"),
                              const Text("Female"),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }

                            if (sex == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please select a gender"),
                                ),
                              );
                              return;
                            }
                            try {
                              // 1. Create the user
                              UserCredential userCredential = await FirebaseAuth
                                  .instance
                                  .createUserWithEmailAndPassword(
                                    email: emailController.text.trim(),
                                    password: passwordController.text.trim(),
                                  );

                              // 2. Get the UID
                              String uid = userCredential.user!.uid;

                              MacroResult mr = calculateMacros(
                                weightLbs:
                                    double.tryParse(
                                      weightController.text.trim(),
                                    ) ??
                                    0.0,
                                heightIn:
                                    double.tryParse(
                                      heightController.text.trim(),
                                    ) ??
                                    0.0,
                                age:
                                    int.tryParse(ageController.text.trim()) ??
                                    0,
                                sex: sex!,
                              );

                              // 3. Save the name (and any other fields) in Firestore
                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(uid)
                                  .set({
                                    "name": nameController.text.trim(),
                                    "email": emailController.text.trim(),
                                    "height": heightController.text.trim(),
                                    "weight": weightController.text.trim(),
                                    "age": ageController.text.trim(),
                                    "sex": sex,
                                    "daily_cals": mr.calories,
                                    "daily_protein": mr.protein,
                                    "daily_fats": mr.fat,
                                    "daily_carbs": mr.carbs,
                                    "createdAt": Timestamp.now(),
                                  });

                              // Pop the signup page so AuthGate can show Navigation()
                              if (mounted) {
                                Navigator.of(context).popUntil((route) => route.isFirst);
                              }
                            } catch (e) {
                              setState(() {
                                logInError = true;
                                logInErrorText = e.toString();
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                          ), // Change this when making frontend reaction
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize: 24.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  children: [
                    const Text(
                      "Already have an account?",
                      style: TextStyle(fontSize: 18.0),
                    ),
                    SizedBox(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
                          );
                        },
                        child: const Text(
                          "Log In Here",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.blue,
                            color: Colors.blue,
                            fontSize: 18.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

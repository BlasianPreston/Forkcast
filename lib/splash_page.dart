import 'package:calorie_app/login_page.dart';
import 'package:calorie_app/signup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Padding(
        padding: EdgeInsetsGeometry.all(48.0),
        child: Column(
          children: [
            SizedBox(
              height: 400,
              width: double.infinity,
              child: SvgPicture.asset(
                'assets/transparent-logo.svg',
                fit: BoxFit.contain,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SignupPage()),
                );
              },
              child: const Text("Sign Up"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPage()),
                );
              },
              child: const Text("Log in"),
            ),
          ],
        ),
      ),
    );
  }
}

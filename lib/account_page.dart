import 'package:flutter/material.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Page", style: TextStyle(fontSize: 24.0)),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.account_circle,
              color: Colors.white,
              size: 48.0,
              semanticLabel: 'Profile Picture',
            ),
            Column(
              children: [
                const Text("Name"),
                const SizedBox(height: 20),
                const Text("Email"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

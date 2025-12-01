import 'package:calorie_app/meal_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MealsPage extends StatefulWidget {
  const MealsPage({super.key});

  @override
  State<MealsPage> createState() => _MealsPageState();
}

class _MealsPageState extends State<MealsPage> {
  late User? user = FirebaseAuth.instance.currentUser;
  late String? uid = user?.uid;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meals')
          .orderBy('timestamp', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var meals = snapshot.data!.docs;
        return Scaffold(
          appBar: AppBar(
            title: Text("Meal History", style: TextStyle(fontSize: 24.0)),
            centerTitle: true,
          ),
          body: Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) ...[
                      const Text("No meals in your history"),
                    ] else ...[
                      ...meals.map((document) {
                        // 2. Extract the data for THIS specific meal
                        Map<String, dynamic> data = document.data();
                
                        // 3. Return the widget
                        return MealCard(
                          label: data['food_name'] ?? 'Unknown Meal',
                          calories: data['calorie_estimate'] ?? 0,
                          imageUrl: data['image_url'],
                          protein: data['protein'],
                          carbs: data['carbs'],
                          fats: data['fats'],
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

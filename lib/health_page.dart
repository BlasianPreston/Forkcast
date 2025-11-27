import 'package:calorie_app/meal_card.dart';
import 'package:calorie_app/meals_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  late User? user = FirebaseAuth.instance.currentUser;
  late String? uid = user?.uid;
  late DateTime now = DateTime.now();
  late int startOfDay = DateTime(
    now.year,
    now.month,
    now.day,
  ).millisecondsSinceEpoch;
  late int endOfDay = DateTime(
    now.year,
    now.month,
    now.day + 1,
  ).millisecondsSinceEpoch;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meals')
          .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
          .where('timestamp', isLessThan: endOfDay)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        var meals = snapshot.data!.docs;
        return Scaffold(
          appBar: AppBar(
            title: const Center(
              child: Text("Account Page", style: TextStyle(fontSize: 24.0)),
            ),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: CircularProgressIndicator(
                            value: 2300 / 3000, // between 0 and 1
                            strokeWidth: 10,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation(Colors.blue),
                          ),
                        ),
                        SizedBox(width: 50),
                        Column(
                          children: [
                            SizedBox(
                              child: Center(
                                child: Column(
                                  children: [
                                    Text(
                                      "Calories Eaten Today:",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "2300",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              child: Center(
                                child: Column(
                                  children: [
                                    Text(
                                      "Meals Eaten Today:",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "2",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Column(
                      children: [
                        const Text(
                          "Today's Nutrition",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 20),
                        Column(
                          children: [
                            Text(
                              "Protein: 167 / 200",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            SizedBox(
                              width: double.infinity,
                              height: 15,
                              child: LinearProgressIndicator(
                                value: 167 / 200, // between 0 and 1
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation(Colors.red),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Column(
                          children: [
                            Text(
                              "Carbs: 124 / 150",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            SizedBox(
                              width: double.infinity,
                              height: 15,
                              child: LinearProgressIndicator(
                                value: 124 / 150, // between 0 and 1
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.yellow,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Column(
                          children: [
                            Text(
                              "Fat: 60 / 65",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            SizedBox(
                              width: double.infinity,
                              height: 15,
                              child: LinearProgressIndicator(
                                value: 60 / 65, // between 0 and 1
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 30),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            "Today's Meals",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ), // Map over this later when pulling data from database
                          SizedBox(height: 30),
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) ...[
                            const Text("No meals logged today"),
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
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MealsPage()),
                            );
                          },
                          child: const Text(
                            "View Meal History",
                            style: TextStyle(
                              fontSize: 18.0,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.blue,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 15.0,
                          color: Colors.blue,
                        ),
                      ],
                    ),
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

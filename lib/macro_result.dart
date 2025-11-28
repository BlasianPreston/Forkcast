class MacroResult {
  final double calories;
  final double protein; 
  final double fat; 
  final double carbs;  

  MacroResult({
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });
}

MacroResult calculateMacros({
  required double weightLbs,
  required double heightIn,
  required int age,
  required String sex,
  double activityMultiplier = 1.35,
}) {
  // Convert weight (lbs → kg)
  final weightKg = weightLbs / 2.20462;

  // Convert height (in → cm)
  final heightCm = heightIn * 2.54;

  // --- BMR using Mifflin–St Jeor ---
  double bmr = 10 * weightKg + 6.25 * heightCm - 5 * age;

  if (sex.toLowerCase() == "male") {
    bmr += 5;
  } else {
    bmr -= 161;
  }

  // Daily calories (TDEE)
  final calories = bmr * activityMultiplier;

  // --- Macros (based on weight in kg) ---
  final protein = 1.6 * weightKg; // grams
  final fat = 0.9 * weightKg;     // grams

  // Carbs fill remaining calories
  final carbs = (calories - (4 * protein + 9 * fat)) / 4;

  return MacroResult(
    calories: calories,
    protein: protein,
    fat: fat,
    carbs: carbs,
  );
}
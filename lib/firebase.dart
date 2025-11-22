import 'package:firebase_core/firebase_core.dart';
import 'package:calorie_app/firebase_options.dart';

// ...

await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
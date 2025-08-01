import 'package:flutter/material.dart';
import 'package:food_logger/pages/add_meal_page.dart';

import 'pages/home_page.dart';
import 'pages/image_upload_page.dart';
import 'pages/manual_entry_page.dart';
import 'pages/history_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(FoodLoggerApp());
}

class FoodLoggerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Logger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.white,
        textTheme: Theme.of(
          context,
        ).textTheme.apply(bodyColor: Colors.black, displayColor: Colors.black),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
        '/upload': (context) => ImageUploadPage(),
        '/manual': (context) => ManualEntryPage(),
        '/history': (context) => HistoryPage(),
        '/addMeal': (context) => AddMealPage(),
      },
    );
  }
}

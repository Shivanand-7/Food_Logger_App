import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreInitHelper {
  static Future<void> initializeDailyLog() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final docRef = FirebaseFirestore.instance
        .collection('food_logs')
        .doc(today);

    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) {
      await docRef.set({
        'meals': {'meal_1': []},
        'totals': {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0},
      });
      print("✅ Firestore: Daily log initialized for $today");
    } else {
      print("ℹ️ Firestore: Daily log already exists for $today");
    }
  }
}

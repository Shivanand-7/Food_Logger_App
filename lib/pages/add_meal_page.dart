import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddMealPage extends StatefulWidget {
  const AddMealPage({super.key});

  @override
  State<AddMealPage> createState() => _AddMealPageState();
}

class _AddMealPageState extends State<AddMealPage> {
  final TextEditingController mealNameController = TextEditingController();
  final TextEditingController foodNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  bool _isLoading = false;
  String? _responseText;

  Future<void> addMeal() async {
    final mealName = mealNameController.text.trim();
    final foodName = foodNameController.text.trim();
    final quantity = quantityController.text.trim();

    if (mealName.isEmpty || foodName.isEmpty || quantity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _responseText = null;
    });

    try {
      final response = await http.post(
        Uri.parse("https://nutrition-1-r9gm.onrender.com/describe/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"item_name": "$quantity $foodName"}),
      );

      if (response.statusCode == 200) {
        final description = json.decode(response.body)['result'];

        final calorieMatch = RegExp(r'(\d+)\s*kcal').firstMatch(description);
        double calories = calorieMatch != null
            ? double.parse(calorieMatch.group(1)!)
            : 0;

        final now = DateTime.now();
        final formattedDate =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

        await FirebaseFirestore.instance.collection('meals').add({
          'userId': 'test_user',
          'date': formattedDate,
          'mealName': mealName,
          'foodItems': [
            {'name': foodName, 'quantity': quantity},
          ],
          'calories': calories,
          'timestamp': FieldValue.serverTimestamp(),
        });

        setState(() {
          _responseText = description;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Meal added successfully!"),
            backgroundColor: Colors.green,
          ),
        );

        mealNameController.clear();
        foodNameController.clear();
        quantityController.clear();
      } else {
        throw Exception("Failed to get description");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    mealNameController.dispose();
    foodNameController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Meal"), backgroundColor: Colors.teal),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: mealNameController,
              decoration: InputDecoration(
                labelText: "Meal Name (e.g. Meal 2, Lunch)",
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: foodNameController,
              decoration: InputDecoration(
                labelText: "Food Name (e.g. Rice, Banana)",
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: "Quantity (e.g. 1 bowl, 2 pieces)",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : addMeal,
              icon: Icon(Icons.add),
              label: Text("Add Meal"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
            SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),
            if (_responseText != null) ...[
              Text(
                "Nutrition Info:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(_responseText!),
            ],
          ],
        ),
      ),
    );
  }
}

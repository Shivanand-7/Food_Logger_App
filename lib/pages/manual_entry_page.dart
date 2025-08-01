import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_logger/widgets/custom_button.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManualEntryPage extends StatefulWidget {
  @override
  _ManualEntryPageState createState() => _ManualEntryPageState();
}

class _ManualEntryPageState extends State<ManualEntryPage> {
  final TextEditingController foodController = TextEditingController();
  final String userId = "test_user";
  String _mealName = "Meal 1";
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;

  Future<void> getDescription() async {
    final itemName = foodController.text.trim();
    if (itemName.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://nutrition-1-r9gm.onrender.com/describe/"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"item_name": itemName}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body)['result'];

        setState(() {
          _items.add({'name': itemName, 'description': result, 'quantity': ''});
          foodController.clear();
        });
      }
    } catch (e) {
      print("❌ Error: $e");
    }

    setState(() => _isLoading = false);
  }

  Future<void> saveMealToFirestore() async {
    final now = DateTime.now();
    final date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    double totalCalories = 0;
    List<Map<String, dynamic>> foodItems = [];

    for (var item in _items) {
      final match = RegExp(r'(\d+)\s*kcal').firstMatch(item['description']);
      final calories = match != null ? double.parse(match.group(1)!) : 0;
      totalCalories += calories;

      foodItems.add({'name': item['name'], 'quantity': item['quantity']});
    }

    await FirebaseFirestore.instance.collection('meals').add({
      'userId': userId,
      'date': date,
      'mealName': _mealName,
      'foodItems': foodItems,
      'calories': totalCalories,
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Meal saved!")));

    setState(() {
      _items.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Manual Entry"),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Enter a Food Item",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            TextField(
              controller: foodController,
              decoration: InputDecoration(
                labelText: "Food Item Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            CustomButton(onPressed: getDescription, text: "Get Description"),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                labelText: "Meal Name (e.g. Meal 1)",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => _mealName = val,
            ),
            SizedBox(height: 20),
            if (_isLoading) ...[
              Center(child: CircularProgressIndicator()),
              SizedBox(height: 20),
            ],
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    children: [
                      ListTile(
                        title: Text(item['name']),
                        subtitle: Text(item['description']),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _items.removeAt(index);
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: "Quantity (e.g. 2 cups, 1 piece)",
                          ),
                          onChanged: (val) => item['quantity'] = val,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            SizedBox(height: 16),
            if (_items.isNotEmpty)
              ElevatedButton.icon(
                onPressed: saveMealToFirestore,
                icon: Icon(Icons.save),
                label: Text("Save Meal"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

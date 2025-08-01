import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  Future<void> deleteMeal(String docId, BuildContext context) async {
    await FirebaseFirestore.instance.collection('meals').doc(docId).delete();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text("Meal deleted")));
  }

  Future<void> deleteFoodItemsDialog(
    BuildContext context,
    String docId,
    List<Map<String, dynamic>> foodItems,
    double originalCalories,
  ) async {
    List<bool> selected = List.filled(foodItems.length, false);

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text("Delete Food Items"),
          content: StatefulBuilder(
            builder: (context, setState) => SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: foodItems.length,
                itemBuilder: (context, index) {
                  final item = foodItems[index];
                  return CheckboxListTile(
                    title: Text("${item['quantity']} ${item['name']}"),
                    value: selected[index],
                    onChanged: (val) => setState(() => selected[index] = val!),
                  );
                },
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                List<Map<String, dynamic>> updatedItems = [];
                for (int i = 0; i < foodItems.length; i++) {
                  if (!selected[i]) updatedItems.add(foodItems[i]);
                }

                double updatedCalories = 0;
                for (var item in updatedItems) {
                  final desc = item['description'] ?? '';
                  final match = RegExp(r'(\d+)\s*kcal').firstMatch(desc);
                  updatedCalories += match != null
                      ? double.parse(match.group(1)!)
                      : 0;
                }

                await FirebaseFirestore.instance
                    .collection('meals')
                    .doc(docId)
                    .update({
                      'foodItems': updatedItems,
                      'calories': updatedCalories,
                    });

                Navigator.of(context).pop();
              },
              child: Text("Delete"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Meal History"),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('meals')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(
              child: Text(
                "No meals found.",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
            );

          final meals = snapshot.data!.docs;

          // Group meals by date
          Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (var doc in meals) {
            final date = doc['date'] ?? 'Unknown';
            grouped.putIfAbsent(date, () => []).add(doc);
          }

          return ListView(
            padding: EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              final date = entry.key;
              final dayMeals = entry.value;

              final totalCaloriesForDay = dayMeals.fold<double>(
                0,
                (sum, meal) => sum + (meal['calories'] ?? 0.0),
              );

              return Card(
                elevation: 3,
                margin: EdgeInsets.only(bottom: 16),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.symmetric(horizontal: 16),
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "📅 $date",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal[800],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Total Calories: ${totalCaloriesForDay.toStringAsFixed(0)} kcal",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.teal[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  children: dayMeals.map((meal) {
                    final docId = meal.id;
                    final mealName = meal['mealName'] ?? 'Unnamed Meal';
                    final foodItems = List<Map<String, dynamic>>.from(
                      meal['foodItems'] ?? [],
                    );
                    final calories = meal['calories'] ?? 0;

                    return Column(
                      children: [
                        ListTile(
                          title: Text(
                            mealName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.teal[900],
                            ),
                          ),
                          subtitle: Text(
                            "🔥 Calories: $calories kcal",
                            style: TextStyle(
                              color: Colors.teal[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'delete_meal') {
                                deleteMeal(docId, context);
                              } else if (value == 'delete_items') {
                                deleteFoodItemsDialog(
                                  context,
                                  docId,
                                  foodItems,
                                  calories.toDouble(),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete_meal',
                                child: Text('Delete Meal'),
                              ),
                              PopupMenuItem(
                                value: 'delete_items',
                                child: Text('Delete Food Item(s)'),
                              ),
                            ],
                          ),
                        ),
                        ...foodItems.map((item) {
                          final name = item['name'].toString();
                          final quantity = item['quantity'].toString();
                          final formattedName = name.isNotEmpty
                              ? "${name[0].toUpperCase()}${name.substring(1)}"
                              : name;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 4,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "➤ ",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.teal[800],
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "$quantity $formattedName",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        Divider(),
                      ],
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

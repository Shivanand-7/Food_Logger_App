import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageUploadPage extends StatefulWidget {
  const ImageUploadPage({Key? key}) : super(key: key);

  @override
  State<ImageUploadPage> createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _image;
  List<Map<String, dynamic>> _foodDetails = [];
  bool _isLoading = false;
  String _mealName = "Meal 1";
  String userId = "test_user";

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _foodDetails = [];
      });
      await uploadImage(_image!);
    }
  }

  Future<void> uploadImage(File image) async {
    setState(() {
      _isLoading = true;
    });

    final uri = Uri.parse(
      'https://food-detection-model-yipd.onrender.com/predict/',
    );
    var request = http.MultipartRequest('POST', uri);
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        image.path,
        contentType: MediaType('image', 'jpeg'),
      ),
    );

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        dynamic decoded = json.decode(responseBody);
        if (decoded is String) decoded = json.decode(decoded);
        await fetchDescriptions(decoded);
      }
    } catch (e) {
      print('Upload error: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> fetchDescriptions(List<dynamic> predictions) async {
    final url = Uri.parse("https://nutrition-1-r9gm.onrender.com/describe/");
    List<Future<Map<String, dynamic>>> futures = predictions.map((p) async {
      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: json.encode({
            "item_name": p['name']
                .toString()
                .replaceAll('_', ' ')
                .split(' ')
                .map((w) => w[0].toUpperCase() + w.substring(1))
                .join(' '),
          }),
        );
        final result = json.decode(response.body)['result'];
        return {
          'name': p['name'],
          'confidence': p['confidence'],
          'description': result,
          'quantity': '',
        };
      } catch (e) {
        return {
          'name': p['name'],
          'confidence': p['confidence'],
          'description': 'Error occurred',
          'quantity': '',
        };
      }
    }).toList();

    final results = await Future.wait(futures);
    setState(() {
      _foodDetails = results;
    });
  }

  Future<void> saveMealToFirestore() async {
    final now = DateTime.now();
    final date =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    double totalCalories = 0;
    List<Map<String, dynamic>> foodItems = [];

    for (var item in _foodDetails) {
      final caloriesMatch = RegExp(
        r'(\d+)\s*kcal',
      ).firstMatch(item['description']);
      double calories = caloriesMatch != null
          ? double.parse(caloriesMatch.group(1)!)
          : 0;
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Image Upload'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: pickImage,
              icon: Icon(Icons.image),
              label: Text("Upload Image"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: "Meal Name (e.g. Meal 1)",
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => _mealName = val,
            ),
            SizedBox(height: 16),
            if (_isLoading) Center(child: CircularProgressIndicator()),
            if (_image != null) ...[
              SizedBox(height: 20),
              Image.file(_image!, height: 200),
            ],
            if (_foodDetails.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                "Detected Items",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
              SizedBox(height: 10),
              ..._foodDetails.asMap().entries.map((entry) {
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
                          subtitle: Text(
                            "Confidence: ${(item['confidence'] * 100).toStringAsFixed(2)}%\n${item['description']}",
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _foodDetails.removeAt(index);
                              });
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: "Quantity (e.g. 1 cup, 2 pieces)",
                            ),
                            onChanged: (val) => item['quantity'] = val,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: saveMealToFirestore,
                icon: Icon(Icons.save),
                label: Text("Save Meal"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

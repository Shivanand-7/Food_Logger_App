import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://food-detection-model-yipd.onrender.com';

  static Future<List<dynamic>> uploadImage(File imageFile) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/predict/'));
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    var response = await request.send();

    if (response.statusCode == 200) {
      var respStr = await response.stream.bytesToString();
      return jsonDecode(respStr);
    } else {
      throw Exception('Failed to get prediction');
    }
  }
}

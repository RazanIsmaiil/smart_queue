import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      "https://YOUR-BACKEND-URL.up.railway.app";

  static Future<Map<String, dynamic>> addCustomer(String name) async {
    final response = await http.post(
      Uri.parse("$baseUrl/queue/add"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"customer_name": name}),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getQueue() async {
    final response =
        await http.get(Uri.parse("$baseUrl/queue/list"));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> nextCustomer() async {
    final response =
        await http.post(Uri.parse("$baseUrl/queue/next"));
    return jsonDecode(response.body);
  }
}

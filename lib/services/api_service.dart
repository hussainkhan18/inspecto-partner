import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<http.Response> addSale(Map<String, dynamic> orderData) async {
    final url = Uri.parse('$baseUrl/api/add_sale');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );
      return response;
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<http.Response> getProducts(String refrelCode) async {
    final url = Uri.parse('$baseUrl/items/$refrelCode');
    try {
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      return response;
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<http.Response> getBanners(String refrelCode) async {
    final url = Uri.parse('$baseUrl/banners/$refrelCode');
    try {
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      return response;
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<dynamic> get(String endpoint) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      return response;
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data));
      return response;
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl$endpoint');
    try {
      final response = await http.put(url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(data));
      return response;
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }
  
  Future<dynamic> getOrder(String userId) async {
    final url = Uri.parse('$baseUrl/api/get_order/$userId');
    try {
      final response =
          await http.get(url, headers: {'Content-Type': 'application/json'});
      return response;
    } catch (e) {
      throw Exception('An error occurred: $e');
    }
  }


  // dynamic _processResponse(http.Response response) {
  //   final statusCode = response.statusCode;
  //   final body = response.body;

  //   print('Response Status Code: $statusCode');
  //   print('Response Body: $body');

  //   if (statusCode >= 200 && statusCode < 300) {
  //     return json.decode(body);
  //   } else {
  //     try {
  //       final responseData = json.decode(body);
  //       if (responseData is Map<String, dynamic> &&
  //           responseData.containsKey('errors')) {
  //         final errors = responseData['errors'] as Map<String, dynamic>;
  //         throw Exception(
  //             errors.entries.map((e) => '${e.key}: ${e.value}').join('\n'));
  //       }
  //       throw Exception('Error: $statusCode\n$body');
  //     } catch (e) {
  //       // Return a generic error message if the response format is unexpected
  //       return 'An error occurred: $e';
  //     }
  //   }
  // }
}

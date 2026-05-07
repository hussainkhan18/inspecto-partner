import 'package:flutter/material.dart';
import 'package:techno_shield/services/api_service.dart';

class MyOrderViewModel extends ChangeNotifier {
  final ApiService apiService;
  List<Item> orders = [];
  bool isLoading = false;
  String? errorMessage;

  MyOrderViewModel(this.apiService);

  Future<void> fetchOrders(String userId) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.getOrder(userId);
      if (response is List) {
        orders = response.map((data) => Item.fromJson(data)).toList();
      } else {
        errorMessage = 'Unexpected response format';
      }
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }
}

class Item {
  final String createdAt;
  final String status;
  final String totalAmount;

  Item(
      {required this.createdAt,
      required this.status,
      required this.totalAmount});

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      createdAt: json['created_at'],
      status: json['status'],
      totalAmount: json['total_amount'],
    );
  }
}

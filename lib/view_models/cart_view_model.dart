import 'package:flutter/material.dart';
import 'package:techno_shield/models/user_model.dart';
import 'package:techno_shield/repositories/cart_repository.dart';
import 'package:techno_shield/services/api_service.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

class CartViewModel with ChangeNotifier {
  final CartRepository _cartRepository = CartRepository();

  Map<Item, int> _items = {};
  final ApiService apiService = ApiService(
    baseUrl: 'https://inspecto-partner.stageserverofbss.com',
  );

  Map<Item, int> get items => _items;

  Future<void> loadCartItems(int userId) async {
    try {
      print('Loading cart items for user $userId');
      final cartData = await _cartRepository.getCartItems(userId);
      _items = {}; // Clear current items

      for (var item in cartData) {
        _items[Item(
          id: item["productId"],
          name: item['name'],
          itemImg: item['itemImg'],
          salePrice: item['salePrice'],
        )] = item['quantity'];
      }

      print('Cart items loaded: $_items');
      notifyListeners();
    } catch (e) {
      print('Error loading cart items: $e');
    }
  }

  Future<void> addItemWithQuantity(Item item, int quantity, int userId) async {
    _items[item] = (_items[item] ?? 0) + quantity;
    await _cartRepository.addItemToCart(item, _items[item]!, userId);
    notifyListeners();
  }

  Future<void> removeItem(Item item, int userId) async {
    if (_items.containsKey(item) && _items[item]! > 0) {
      _items[item] = _items[item]! - 1;
      if (_items[item] == 0) {
        _items.remove(item);
      }
      await _cartRepository.removeItemFromCart(item, userId);
      notifyListeners();
    }
  }

  Future<void> clearCart(int userId) async {
    _items.clear();
    await _cartRepository.clearCart(userId);
    notifyListeners();
  }

  double get totalPrice {
    return _items.entries
        .map((e) => (double.tryParse(e.key.salePrice) ?? 0.0) * e.value)
        .fold(0.0, (previous, current) => previous + current);
  }

  Future<void> placeOrder(
    BuildContext context,
    int userId,
    int emptyBottleCount,
    String createdBy,
    String address,
  ) async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;
    print("user latitude ${user!.latitude}");
    try {
      final itemIds = <String>[];
      final buyingQtys = <String>[];
      final unitPrices = <String>[];
      final buyingPrices = <String>[];
      double totalBuyingPrice = 0.0;

      _items.forEach((item, quantity) {
        if (item.id != null) {
          itemIds.add(item.id!.toString());
        }
        buyingQtys.add(quantity.toString());
        unitPrices.add(item.salePrice);
        double itemBuyingPrice =
            (double.tryParse(item.salePrice) ?? 0.0) * quantity;
        buyingPrices.add(itemBuyingPrice.toString());
        totalBuyingPrice += itemBuyingPrice;
      });

      final requestBody = {
        'customer_id': userId.toString(),
        'item_id': itemIds.join(', '),
        'buying_qty': buyingQtys.join(', '),
        'unit_price': unitPrices.join(', '),
        'buying_price': buyingPrices.join(', '),
        'total_amount': totalBuyingPrice.toString(),
        'bottles': emptyBottleCount.toString(),
        'payment': 'cash',
        "created_by": createdBy,
        "address": address,
        "latitude": user.latitude,
        "longitude": user.longitude,
      };

      print("Request Body: $requestBody");
      final response = await apiService.addSale(requestBody);
      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        // Order is considered successful since the status code is 200
        print('Order placed successfully');
        _items.clear();
        await _cartRepository.clearCart(
          userId,
        ); // Ensure local storage is cleared
        notifyListeners();
      } else {
        final errorMessage = response.body;
        print('Failed to place order: $errorMessage');
        throw Exception('Failed to place order: $errorMessage');
      }
    } catch (e) {
      print('Error placing order: $e');
      throw Exception('Error placing order: $e');
    }
  }
}

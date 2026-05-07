import 'package:techno_shield/helper/database_helper.dart';
import 'package:techno_shield/models/user_model.dart' as user_model;

class CartRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<void> addItemToCart(
      user_model.Item item, int quantity, int userId) async {
    final databaseItem = DatabaseItem(
      id: item.id,
      name: item.name,
      itemImg: item.itemImg,
      salePrice: item.salePrice,
    );
    await _databaseHelper.insertCartItem(databaseItem, quantity, userId);
  }

  Future<List<Map<String, dynamic>>> getCartItems(int userId) async {
    return await _databaseHelper.getCartItems(userId);
  }

  Future<void> clearCart(int userId) async {
    await _databaseHelper.clearCart(userId);
  }

  Future<void> removeItemFromCart(user_model.Item item, int userId) async {
    await _databaseHelper.removeCartItem(item.name, userId);
  }
}

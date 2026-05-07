import 'package:flutter/material.dart';
import 'package:techno_shield/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:techno_shield/view_models/cart_view_model.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import '/helper/style.dart' as style;

class CartPage extends StatefulWidget {
  static const String page_id = 'Cart';

  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<void> _cartFuture;

  @override
  void initState() {
    super.initState();
    final cartViewModel = Provider.of<CartViewModel>(context, listen: false);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;

    if (user != null) {
      final userId = user.id;
      if (userId != null) {
        _cartFuture = cartViewModel.loadCartItems(userId);
      } else {
        _cartFuture = Future.error('Invalid user ID');
      }
    } else {
      _cartFuture = Future.error('User not logged in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartViewModel = Provider.of<CartViewModel>(context);
    final userViewModel = Provider.of<UserViewModel>(context);
    final user = userViewModel.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
        ),
        body: const Center(child: Text('Please log in to view your cart')),
      );
    }

    final userId = user.id;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
        ),
        body: const Center(child: Text('Invalid user ID')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: FutureBuilder(
        future: _cartFuture,
        builder: (context, snapshot) {
          print('FutureBuilder state: ${snapshot.connectionState}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('Error in FutureBuilder: ${snapshot.error}');
            return const Center(child: Text('Error loading cart items'));
          }

          if (cartViewModel.items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartViewModel.items.length,
                  itemBuilder: (context, index) {
                    final item = cartViewModel.items.keys.elementAt(index);
                    final quantity = cartViewModel.items[item]!;
                    return ListTile(
                      leading: Image.network(item.itemImg),
                      title: Text(item.name),
                      subtitle: Text(
                          'Rs. ${(double.tryParse(item.salePrice) ?? 0.0).toStringAsFixed(2)} x $quantity'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle),
                            onPressed: () {
                              cartViewModel.removeItem(item, userId);
                            },
                          ),
                          Text('$quantity'),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: () {
                              cartViewModel.addItemWithQuantity(
                                  item, 1, userId);
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _buildCheckoutSection(context, cartViewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCheckoutSection(
      BuildContext context, CartViewModel cartViewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(0, -1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 18, fontFamily: 'medium'),
              ),
              Text(
                'RS ${cartViewModel.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, fontFamily: 'medium'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRoutes.checkoutPage,
              );
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: style.appColor,
              textStyle: const TextStyle(fontFamily: 'medium'),
            ),
            child: Text('Checkout'),
          ),
        ],
      ),
    );
  }
}

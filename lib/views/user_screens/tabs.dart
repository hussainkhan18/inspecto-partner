import 'package:flutter/material.dart';
import 'package:techno_shield/models/user_model.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import 'package:techno_shield/views/user_screens/account.dart';
import 'package:techno_shield/views/user_screens/cart.dart';
import 'package:techno_shield/views/user_screens/order.dart';
import 'package:techno_shield/views/user_screens/shop.dart';
import 'package:provider/provider.dart';
import '/helper/style.dart' as style;

class UserTabs extends StatefulWidget {
  final int initialIndex;
  const UserTabs({super.key, Title? title, this.initialIndex = 0});

  final String title = '';
  static const String page_id = 'Tabs';

  @override
  _TabsExampleState createState() => _TabsExampleState();
}

class _TabsExampleState extends State<UserTabs> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);
    final user = userViewModel.currentUser;

    return DefaultTabController(
      length: 4,
      initialIndex: _currentIndex, // Setting initial index
      child: Scaffold(
        bottomNavigationBar: TabBar(
          labelColor: style.appColor,
          indicatorPadding: const EdgeInsets.symmetric(horizontal: 0),
          unselectedLabelColor: const Color.fromARGB(255, 122, 122, 122),
          indicatorColor: Colors.transparent,
          labelPadding: const EdgeInsets.all(0),
          labelStyle: const TextStyle(
            fontFamily: 'regular',
            fontSize: 10,
          ),
          onTap: (int index) => setState(() => _currentIndex = index),
          tabs: const [
            Tab(icon: Icon(Icons.storefront_outlined), text: 'Shop'),
            Tab(icon: Icon(Icons.shopping_bag_outlined), text: 'Cart'),
            Tab(icon: Icon(Icons.local_mall_outlined), text: 'My Order'),
            Tab(icon: Icon(Icons.people_outline), text: 'Account'),
          ],
        ),
        body: _buildBody(user),
      ),
    );
  }

  Widget _buildBody(User? user) {
    if (user == null) {
      return const Center(child: Text('No user data available'));
    }
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ShopPage(),
        CartPage(),
        OrderPage(
            // userId: user.id.toString(),
            ),
        AccountPage(),
      ],
    );
  }
}

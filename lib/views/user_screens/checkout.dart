import 'package:flutter/material.dart';
import 'package:techno_shield/helper/style.dart';
import 'package:techno_shield/routes/app_routes.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import 'package:techno_shield/view_models/cart_view_model.dart';
import 'package:provider/provider.dart';
import '/helper/style.dart' as style;

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, Title? title});
  final String title = '';

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int emptyBottleCount = 0; // Initialize empty bottle count to 0
  final TextEditingController _addressController = TextEditingController();
  @override
  void initState() {
    super.initState();
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    _addressController.text = userViewModel.currentUser!.address;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(color: style.appColor),
        title: const Text('Checkout'),
        centerTitle: false,
        titleTextStyle: style.pageTitle(),
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomContainer(context),
    );
  }

  Widget _buildBody() {
    final cartViewModel = Provider.of<CartViewModel>(context);
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
                    'RS ${(double.tryParse(item.salePrice) ?? 0.0).toStringAsFixed(2)} x $quantity'),
              );
            },
          ),
        ),
        _buildAddressField(),
        _buildPaymentMethod(),
        _buildEmptyBottleCounter(),
      ],
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
      child: TextField(
        controller: _addressController,
        decoration: InputDecoration(
          labelText: 'Delivery Address',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Material(
        elevation: 1.0,
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black38,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                activeColor: Colors.green,
                title: const Row(
                  children: [
                    Icon(
                      Icons.attach_money,
                      color: Colors.green,
                    ),
                    Text(
                      'Cash on Delivery',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                value: true, // Permanently checked
                onChanged: (value) {
                  // Do nothing since we want it to be permanently checked
                },
              ),
              const CheckboxListTile(
                title: Row(
                  children: [
                    Icon(Icons.card_membership_rounded),
                    Text('Card Payment'),
                  ],
                ),
                value: false, // Permanently unchecked
                onChanged: null, // Disable the onChanged callback
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyBottleCounter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(
              color: Colors.black38,
            ),
            borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            SizedBox(
              width: 110, // Adjust the width as needed
              height: 50, // Adjust the height as needed
              child: Stack(
                children: List.generate(
                  emptyBottleCount,
                  (index) => Positioned(
                    left: index * 10.0, // Adjust spacing between images
                    child: Image.asset(
                      'assets/images/empty_bottle.png', // Update this path to the correct path for your image
                      width: 50,
                      height: 50,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Text('Empty Bottles:'),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                setState(() {
                  if (emptyBottleCount > 0) {
                    emptyBottleCount--;
                  }
                });
              },
            ),
            Text('$emptyBottleCount', style: const TextStyle(fontSize: 18)),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  if (emptyBottleCount < 9) {
                    emptyBottleCount++;
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(icn, text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              Icon(icn, color: style.appColor),
              const SizedBox(width: 16),
              Expanded(child: Text('$text')),
            ],
          ),
        ),
        const Icon(Icons.keyboard_arrow_right, color: style.appColor)
      ],
    );
  }

  boldLabel() {
    return const TextStyle(fontSize: 18, fontFamily: 'semi-bold');
  }

  Widget _buildBottomContainer(BuildContext context) {
    final cartViewModel = Provider.of<CartViewModel>(context);
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final int userId = userViewModel.currentUser?.id ?? 0;
    final user = userViewModel.currentUser;
    final String userAddress = user!.address;
    final String createdBy =
        userViewModel.currentUser?.createdBy.toString() ?? "";

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
            onPressed: () async {
              await cartViewModel.placeOrder(context, userId, emptyBottleCount,
                  createdBy, _addressController.text);
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.orderSuccessPage,
              );
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: style.appColor,
              textStyle: const TextStyle(fontFamily: 'medium'),
            ),
            child: Text('Place Order'),
          ),
        ],
      ),
    );
  }
}

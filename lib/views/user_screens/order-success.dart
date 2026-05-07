import 'package:flutter/material.dart';
import 'package:techno_shield/routes/app_routes.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import 'package:techno_shield/views/user_screens/tabs.dart';
import 'package:provider/provider.dart';
import '/helper/style.dart' as style;

class OrderSuccessPage extends StatefulWidget {
  const OrderSuccessPage({super.key, Title? title});
  final String title = '';
  static const String page_id = 'Order Success';
  
  @override
  State<OrderSuccessPage> createState() => _OrderSuccessPageState();
}

class _OrderSuccessPageState extends State<OrderSuccessPage> {
  late double deviceHeight;
  late double deviceWidth;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    deviceHeight = MediaQuery.of(context).size.height;
    deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;
    return SizedBox(
      height: deviceHeight,
      width: deviceWidth,
      child: Stack(
        children: [
          Container(
            color: style.appColor,
            width: double.infinity,
            height: deviceHeight - 160,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/checked.png', width: 70),
                const SizedBox(height: 40),
                Text(
                  '${user?.name}, your order \n has been successful',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'semi-bold'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Check your order status in My Order \n about next steps information.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: deviceHeight - 180,
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 180,
              width: deviceWidth,
              decoration: radiusContainer(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Preparing your order',
                    style: TextStyle(fontFamily: 'medium', fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your order will be prepared and will come soon',
                    style: TextStyle(color: Colors.grey),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        int index = 2;
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          AppRoutes.userTabs,
                          (Route<dynamic> route) => false,
                          arguments: {
                            'index': index,
                            'orderDetails': {
                              'name': 'Example Product',
                              'totalPrice': 100.0,
                              'status': 'On Process',
                            },
                          },
                        );
                      },
                      style: style.simpleButton(),
                      child: Text('Track My Order'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration radiusContainer() {
    return const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(25.0),
        topRight: Radius.circular(25.0),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '/helper/style.dart' as style;
import '/views/user_screens/order.dart';

class OrderDetailPage extends StatelessWidget {
  final Order order;

  const OrderDetailPage({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: style.appColor),
        title: Text('Order ID: ${order.orderId}'),
        centerTitle: false,
        titleTextStyle: style.pageTitle(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: style.bottomBorder(),
              child: Text(order.orderDate),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: style.bottomBorder(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBoldTitle('Order Status'),
                  const SizedBox(height: 10),
                  Image.asset(
                    getStatusImage(order.status),
                    height: 200,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    getStatusMessage(order.status),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: style.bottomBorder(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBoldTitle('Destination'),
                  const SizedBox(height: 10),
                  Text(
                    order.address,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: style.bottomBorder(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBoldTitle('Total Cost'),
                  const SizedBox(height: 10),
                  Text(
                    'Rs.${order.totalAmount}',
                    style: const TextStyle(
                      fontFamily: 'semi-bold',
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You can check your order detail here. Thank you for ordering.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoldTitle(val) {
    return Text(
      '$val',
      style: const TextStyle(
        fontFamily: 'medium',
        fontSize: 16,
      ),
    );
  }

  String getStatusImage(int status) {
    switch (status) {
      case 0:
        return 'assets/images/1.gif';
      case 1:
        return 'assets/images/2.gif';
      case 2:
        return 'assets/images/3.gif';
      case 3:
        return 'assets/images/4.gif';
      case 4:
        return 'assets/images/5.gif';
      default:
        return 'assets/images/default.gif';
    }
  }

  String getStatusMessage(int status) {
    switch (status) {
      case 0:
        return 'Ordered';
      case 1:
        return 'Order Assigned to Rider';
      case 2:
        return 'In Process';
      case 3:
        return 'Delivering';
      case 4:
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }
}

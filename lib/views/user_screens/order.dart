import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:techno_shield/view_models/auth/user_view_model.dart';
import 'package:techno_shield/views/user_screens/order_details.dart';
import 'package:provider/provider.dart';
import '/helper/style.dart' as style;
import 'package:http/http.dart' as http;

class OrderPage extends StatefulWidget {
  const OrderPage({super.key, Title? title});
  final String title = '';
  static const String page_id = 'Order';

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  List<Order>? orders;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final userViewModel = Provider.of<UserViewModel>(context, listen: false);
    final user = userViewModel.currentUser;

    if (user == null) {
      return;
    }

    final url = 'https://jalmanagementsystem.com/api/get_sale/${user.id}';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final parsed = jsonDecode(response.body);
      List<dynamic> data = parsed['data'];
      setState(() {
        orders = data.map((order) => Order.fromJson(order)).toList();
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  String tabID = 'Ongoing';

  Map<String, dynamic>? orderDetails;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && args.containsKey('orderDetails')) {
      orderDetails = args['orderDetails'] as Map<String, dynamic>?;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: const Text('My Orders'),
        centerTitle: false,
        titleTextStyle: style.pageTitle(),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (orders == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final DateTime now = DateTime.now();
    final ongoingOrders = orders!.where((order) {
      if (order.status != 4) {
        return true; // Include orders that are not delivered
      }
      if (order.deliveredAt == null) {
        return true; // Include orders without a deliveredAt timestamp
      }
      return now.difference(order.deliveredAt!).inSeconds < 30;
    }).toList();

    final historyOrders = orders!.where((order) {
      if (order.status != 4 || order.deliveredAt == null) {
        return false; // Exclude orders that are not delivered or without a deliveredAt timestamp
      }
      return now.difference(order.deliveredAt!).inSeconds >= 30;
    }).toList();

    return RefreshIndicator(
      onRefresh: fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: style.bottomBorder(),
                child: Row(
                  children: [
                    Expanded(child: _buildSingleSegment('Ongoing')),
                    Expanded(child: _buildSingleSegment('History'))
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: ListView.builder(
                  reverse: true,
                  physics: const ScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: tabID == 'Ongoing'
                      ? ongoingOrders.length
                      : historyOrders.length,
                  itemBuilder: (context, index) {
                    final order = tabID == 'Ongoing'
                        ? ongoingOrders[index]
                        : historyOrders[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailPage(order: order),
                          ),
                        ); // Navigate to order detail page if needed
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: style.shadowContainer(),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: order.getStatusColor(),
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(4)),
                                  ),
                                  child: Text(
                                    order.getStatusMessage(),
                                    style: TextStyle(
                                      color: order.getStatusTextColor(),
                                    ),
                                  ),
                                ),
                                Text(
                                  order.orderDate,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Order ID', style: greyText()),
                                      Text(order.orderId),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Delivered to', style: greyText()),
                                      Text(order.address),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Total Payment', style: greyText()),
                                      Text('Rs.${order.totalAmount}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (orderDetails != null) ...[
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Product Name', style: greyText()),
                                        Text(orderDetails!['name']),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Total Price', style: greyText()),
                                        Text(
                                            '\$${orderDetails!['totalPrice']}'),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Status', style: greyText()),
                                        Text(orderDetails!['status']),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSegment(val) {
    return InkWell(
      onTap: () {
        setState(() {
          tabID = val;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: singleSegment(val),
        child: Text(
          '$val',
          textAlign: TextAlign.center,
          style: segmentText(val),
        ),
      ),
    );
  }

  BoxDecoration singleSegment(val) {
    return BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: val == tabID ? style.appColor : Colors.transparent,
          width: 2,
        ),
      ),
    );
  }

  TextStyle segmentText(val) {
    return TextStyle(
      fontSize: 16,
      fontFamily: 'medium',
      color: val == tabID ? style.appColor : Colors.grey,
    );
  }

  TextStyle greyText() {
    return const TextStyle(fontSize: 12, color: Colors.grey);
  }
}

class Order {
  final String totalAmount;
  final int status;
  final String orderDate;
  final String orderId;
  final String address;
  final DateTime? deliveredAt; // Add this field

  Order({
    required this.orderDate,
    required this.address,
    required this.totalAmount,
    required this.status,
    required this.orderId,
    this.deliveredAt, // Initialize it here
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final parsedDate = DateTime.parse(json['created_at']);
    final formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);

    DateTime? deliveredAt;
    if (json['updated_at'] != null) {
      deliveredAt = DateTime.parse(json['updated_at']);
    }

    return Order(
      totalAmount: json['total_amount'] ?? 'N/A',
      orderDate: formattedDate,
      status: int.tryParse(json['status'].toString()) ?? 0,
      orderId: json['id'].toString(),
      address: json['address'].toString(),
      deliveredAt: deliveredAt,
    );
  }

  String getStatusMessage() {
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

  Color getStatusColor() {
    switch (status) {
      case 0:
        return const Color.fromARGB(255, 237, 255, 229); // Ordered
      case 1:
        return const Color.fromARGB(
            255, 229, 242, 255); // Order Assigned to Rider
      case 2:
        return const Color.fromARGB(255, 255, 243, 229); // In Process
      case 3:
        return const Color.fromARGB(255, 255, 229, 229); // Delivering
      case 4:
        return const Color.fromARGB(255, 229, 255, 242); // Delivered
      default:
        return Colors.grey; // Unknown status
    }
  }

  Color getStatusTextColor() {
    switch (status) {
      case 0:
        return const Color.fromARGB(255, 41, 204, 114); // Ordered
      case 1:
        return const Color.fromARGB(
            255, 64, 143, 255); // Order Assigned to Rider
      case 2:
        return const Color.fromARGB(255, 255, 194, 76); // In Process
      case 3:
        return const Color.fromARGB(255, 255, 56, 56); // Delivering
      case 4:
        return const Color.fromARGB(255, 56, 204, 113); // Delivered
      default:
        return Colors.grey; // Unknown status
    }
  }
}

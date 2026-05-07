import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:techno_shield/models/staff_model.dart';
import 'package:techno_shield/view_models/staff_view_model.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  Future<List<Order>>? futureOrders;
  bool _isLoading = false;
  String? _localImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final staffViewModel =
          Provider.of<StaffViewModel>(context, listen: false);
      final user = staffViewModel.currentStaff;
      if (user != null) {
        setState(() {
          futureOrders = fetchOrders(user.id.toString());
          // saveCompanyImageUrl(user.companyImg);
        });
        // Preload the company image
        // _localImagePath = await _preloadCompanyImage();
      } else {
        setState(() {
          futureOrders = Future.error('User is not logged in');
        });
      }
    });
  }

  Future<List<Order>> fetchOrders(String staffId) async {
    final response = await http.get(
        Uri.parse('https://jalmanagementsystem.com/api/get_orders/$staffId'));

    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success']) {
        List<dynamic> data = json['data'];
        return data.map((order) => Order.fromJson(order)).toList();
      } else {
        throw Exception('Failed to load orders');
      }
    } else {
      throw Exception('Failed to load orders');
    }
  }

  // Future<String?> _preloadCompanyImage() async {
  //   String? imageUrl = await getCompanyImageUrl();
  //   if (imageUrl != null) {
  //     File imageFile = await downloadAndSaveImage(imageUrl, 'company_logo.png');
  //     return imageFile.path;
  //   }
  //   return null;
  // }

  @override
  Widget build(BuildContext context) {
    final staffViewModel = Provider.of<StaffViewModel>(context, listen: false);
    final staff = staffViewModel.currentStaff;
    double buttonWidth = MediaQuery.of(context).size.width * 0.25;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: Stack(
        children: [
          FutureBuilder<List<Order>>(
            future: futureOrders,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No orders found'));
              } else {
                // Filter the orders to only include completed ones
                List<Order> completedOrders =
                    snapshot.data!.where((order) => order.status == 4).toList();
                if (completedOrders.isEmpty) {
                  return const Center(child: Text('No completed orders found'));
                }

                // Sort completedOrders by deliveredAt in descending order
                completedOrders.sort((a, b) {
                  // Handle null cases
                  if (a.deliveredAt == null && b.deliveredAt == null) {
                    return 0;
                  } else if (a.deliveredAt == null) {
                    return 1; // a is considered greater (should come after) if a.deliveredAt is null
                  } else if (b.deliveredAt == null) {
                    return -1; // b is considered greater (should come after) if b.deliveredAt is null
                  } else {
                    // Compare deliveredAt normally
                    return b.deliveredAt!.compareTo(a.deliveredAt!);
                  }
                });

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: const Text(
                          'Completed Orders',
                          style: TextStyle(
                            fontSize: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...completedOrders
                          .map((order) =>
                              _buildOrderCard(context, order, buttonWidth))
                          ,
                    ],
                  ),
                );
              }
            },
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(
      BuildContext context, Order order, double buttonWidth) {
    String deliveredDate = '';
    if (order.deliveredAt != null) {
      deliveredDate = DateFormat.yMd().format(order.deliveredAt!);
    }
    return InkWell(
      onTap: () {
        _showOrderDialog(context, order);
      },
      child: Card(
        elevation: 4,
        color: order.getStatusColor(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Date $deliveredDate',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],),
                
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: order.itemNames!.asMap().entries.map((entry) {
                    int index = entry.key;
                    String itemName = entry.value;
                    double itemPrice = order.unitPrices![index];
                    return Text(
                      '$itemName: Rs.${itemPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  'Address: ${order.address}',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Text(
                  'Customer Empty Bottles: ${order.bottles}',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const SizedBox(height: 8),
              Text(
                'Total Amount: Rs.${order.totalAmount!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              Text(
                'Received Amount: Rs.${order.cashReceived!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              Text(
                'Balance: Rs.${order.balance!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDialog(BuildContext context, Order order) {
    final staffViewModel = Provider.of<StaffViewModel>(context, listen: false);
    final staff = staffViewModel.currentStaff;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Order #${order.id}'),
          content: const Text('Would you like to make a PDF of this order?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });
                Navigator.of(context).pop(); // Close the dialog first
                await _makePdf(order, staff);
                setState(() {
                  _isLoading = false;
                });
              },
              child: const Text('Make PDF'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _makePdf(Order order, Staff? staff) async {
    final doc = pw.Document();
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final dateFormatter2 = DateFormat('yyyy-MM-dd hh:mm a');
    final deliveredDate = order.deliveredAt != null
        ? dateFormatter.format(order.deliveredAt!)
        : '';
    final deliveryTime = order.deliveredAt != null
        ? dateFormatter2.format(order.deliveredAt!)
        : '';
  List<String> quantities = order.quantity!.split(',').map((q) => q.trim()).toList();

    // Fetch the network image
    final imageUrl = staff!.profileImg;
    final response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      final Uint8List imageData = response.bodyBytes;
      final image = pw.MemoryImage(imageData);
    
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // pw.SizedBox(height: 5),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(staff.companyName,
                        style: const pw.TextStyle(fontSize: 28)),
                    pw.Center(
                      child: pw.Container(
                        width: 120,
                        height: 120,
                        child: pw.Image(image),
                      ),
                    ),
                  ],
                ),
                // pw.SizedBox(height: 5),
                pw.Text('Order #${order.id}',
                    style: const pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 6),
                pw.Text('Address: ${order.address}',
                    style: const pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 2),
        
                pw.Text('Customer Name: ${order.customerName}',
                    style: const pw.TextStyle(fontSize: 20)),
                    
                pw.Text('Delivered By: ${staff.name}',
                    style: const pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 2),
                pw.Text('Customer Empty Bottles: ${order.bottles}',
                    style: const pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 2),
                pw.Text('Delivered At: $deliveredDate',
                    style: const pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 2),
                pw.Text('Delivery Time: $deliveryTime',
                    style: const pw.TextStyle(fontSize: 20)),
                pw.SizedBox(height: 2),
                pw.Text('Order Details:',
                    style: pw.TextStyle(
                        fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Table.fromTextArray(
                  headers: [
                    'Item Name',
                    'Qty',
                    'Unit Price',
                     ],
                                           
                  data: List.generate(
                    order.itemNames!.length,
                      (index) {
                      return [
                      order.itemNames![index],
                         quantities[index], // Use the parsed quantity list

                      'Rs.${order.unitPrices![index].toStringAsFixed(2)}',
                      // order.q[index],
                    ];
                  }),

                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 28),
                  cellStyle: const pw.TextStyle(fontSize: 28),),
                pw.SizedBox(height: 5) ,
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Build Amount : ',
                        style: const pw.TextStyle(fontSize: 26)),
                    // pw.Text('Rs.${order.cashReceived.toStringAsFixed(2)}',
                    pw.Text('Rs.${order.totalAmount!.toStringAsFixed(2)}',

                        style: const pw.TextStyle(fontSize: 26)),
                  ],
                   ),
                
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Received Amount: ',
                        style: const pw.TextStyle(fontSize: 26)),
                    // pw.Text('Rs.${order.balance.toStringAsFixed(2)}',
                     pw.Text('Rs.${order.cashReceived!.toStringAsFixed(2)}',

                        style: const pw.TextStyle(fontSize: 26)),
                  ],
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Balance: ',
                        style: pw.TextStyle(
                            fontSize: 26, fontWeight: pw.FontWeight.bold)),
                    // pw.Text('Rs.${order.totalAmount.toStringAsFixed(2)}',
                      pw.Text('Rs.${order.balance!.toStringAsFixed(2)}',

                        style: pw.TextStyle(
                            fontSize: 26, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            );
          },
        ),
      );
    
      // Save and share the PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/order_${order.id}.pdf');
      await file.writeAsBytes(await doc.save());
      await Printing.sharePdf(
          bytes: await doc.save(), filename: 'order_${order.id}.pdf');
    } else {
      print('Failed to load image');
    }
  }

  // Future<pw.ImageProvider?> _loadCompanyLogo() async {
  //   String? companyImageUrl = await getCompanyImageUrl();
  //   if (companyImageUrl != null) {
  //     final response = await http.get(Uri.parse(companyImageUrl));
  //     if (response.statusCode == 200) {
  //       return pw.MemoryImage(response.bodyBytes);
  //     }
  //   }
  //   return null;
  // }

  // Future<String?> getCompanyImageUrl() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   return prefs.getString('companyImageUrl');
  // }

  // Future<void> saveCompanyImageUrl(String url) async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   await prefs.setString('companyImageUrl', url);
  // }

  // Future<File> downloadAndSaveImage(String url, String filename) async {
  //   final response = await http.get(Uri.parse(url));
  //   final documentDirectory = await getApplicationDocumentsDirectory();
  //   final file = File('${documentDirectory.path}/$filename');
  //   file.writeAsBytesSync(response.bodyBytes);
  //   return file;
  // }
}

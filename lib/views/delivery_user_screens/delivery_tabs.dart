import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:techno_shield/views/delivery_user_screens/completed_task.dart';
import 'package:techno_shield/views/delivery_user_screens/ongoing_orders.dart';
import 'package:techno_shield/views/delivery_user_screens/orders_history.dart';
import 'package:techno_shield/views/delivery_user_screens/staff_account.dart';
import 'package:techno_shield/views/delivery_user_screens/staff_expense.dart';

import '/helper/style.dart' as style;

class DeliveryTabs extends StatefulWidget {
  const DeliveryTabs({super.key, Title? title});
  final String title = '';
  static const String page_id = 'Tabs';

  @override
  _TabsExampleState createState() => _TabsExampleState();
}

class _TabsExampleState extends State<DeliveryTabs> {
  int _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        bottomNavigationBar: (TabBar(
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
            Tab(icon: Icon(Icons.assignment_turned_in), text: 'Ongoing Tasks'),
            // Tab(icon: Icon(Icons.history), text: 'History'),
            // // Tab(icon: Icon(Icons.local_mall_outlined), text: 'My Order'),
            Tab(
                icon: FaIcon(FontAwesomeIcons.tasksAlt),
                text: 'Completed Tasks'),
            Tab(icon: Icon(Icons.people_outline), text: 'Account'),
          ],
        )),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: [
            OngoingOrders(),
            // OrderHistoryPage(),
            // ExpensesPage(),
            const CompletedTaskScreen(),
            const StaffAccountPage(),
          ],
        ),
      ),
    );
  }
}

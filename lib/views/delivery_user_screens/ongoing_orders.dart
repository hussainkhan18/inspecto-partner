import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:techno_shield/models/staff_model.dart';
import 'package:techno_shield/models/technician_task_model.dart';
import 'package:techno_shield/view_models/staff_view_model.dart';
import 'package:techno_shield/views/delivery_user_screens/orders_history.dart';
import 'package:techno_shield/views/delivery_user_screens/technitian_checklist.dart';
import 'package:techno_shield/views/login_signup_screens/login.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class OngoingOrders extends StatefulWidget {
  const OngoingOrders({super.key});

  @override
  State<OngoingOrders> createState() => _OngoingOrdersState();
}

class _OngoingOrdersState extends State<OngoingOrders> {
  Future<List<TaskModel>>? futureTasks;
  List<TaskModel> deliveredTasks = [];
  late StreamSubscription<Position> _positionStreamSubscription;
  final bool _isDispatching = false;
  double? _latitude;
  double? _longitude;
  Timer? locationUpdateTimer;

  late StreamSubscription<Position> _positionStream;

  @override
  void initState() {
    super.initState();
    final staffViewModel = Provider.of<StaffViewModel>(context, listen: false);
    final user = staffViewModel.currentStaff;
    if (user != null) {
      futureTasks = fetchTask(user.id.toString());
    } else {
      futureTasks = Future.error('User is not logged in');
    }
  }

  Future<List<TaskModel>> fetchTask(String staffId) async {
    final response = await http.get(
      Uri.parse(
        'https://inspecto-partner.stageserverofbss.com/api/task_assign/$staffId',
      ),
    );
    print(staffId);
    if (response.statusCode == 200) {
      Map<String, dynamic> json = jsonDecode(response.body);
      if (json['success']) {
        List<dynamic> data = json['data'];
        return data.map((task) => TaskModel.fromJson(task)).toList();
      } else {
        return [];
      }
    } else {
      return [];
    }
  }

  void refreshPage() {
    setState(() {
      futureTasks = fetchTask(
        Provider.of<StaffViewModel>(
          context,
          listen: false,
        ).currentStaff!.id.toString(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        shadowColor: Colors.black12,
        title: Text(
          'My Tasks',
          style: TextStyle(
            color: Colors.black,
            fontSize: sw * 0.05,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: refreshPage,
            icon: const Icon(Icons.refresh_rounded, color: Colors.black54),
          ),
        ],
      ),
      body: FutureBuilder<List<TaskModel>>(
        future: futureTasks,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00897B)),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No tasks found',
                style: TextStyle(fontSize: sw * 0.04, color: Colors.grey),
              ),
            );
          } else {
            List<TaskModel> tasks = snapshot.data!.reversed.toList();
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.038,
                vertical: sh * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      left: sw * 0.01,
                      bottom: sh * 0.018,
                    ),
                    child: Text(
                      'Ongoing Tasks',
                      style: TextStyle(
                        fontSize: sw * 0.058,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ),
                  ...tasks.map(
                    (task) => _buildTaskCard(context, task, sw: sw, sh: sh),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context,
    TaskModel task, {
    required double sw,
    required double sh,
  }) {
    print(task.equipmentName);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: sh * 0.018),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.032),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(sw * 0.032),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.042),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Task # and Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Tasks # ${task.caseNo}',
                      style: TextStyle(
                        fontSize: sw * 0.042,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ),
                  SizedBox(width: sw * 0.02),
                  Text(
                    task.inspectionDate,
                    style: TextStyle(
                      fontSize: sw * 0.033,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF666666),
                    ),
                  ),
                ],
              ),

              // Divider
              Padding(
                padding: EdgeInsets.symmetric(vertical: sh * 0.014),
                child: const Divider(
                  color: Color(0xFFF0F0F0),
                  height: 1,
                  thickness: 1,
                ),
              ),

              // Fields
              _buildField(
                  label: 'Equipment Name', value: task.equipmentName, sw: sw),
              SizedBox(height: sh * 0.010),
              _buildField(
                  label: 'Equipment Area', value: task.equipmentArea, sw: sw),
              SizedBox(height: sh * 0.010),
              _buildField(
                  label: 'Equipment Location',
                  value: task.equipmentLocatoin,
                  sw: sw),
              SizedBox(height: sh * 0.010),
              _buildField(
                  label: 'Failed Checklist Key',
                  value: task.failedChecklistKey,
                  sw: sw),

              SizedBox(height: sh * 0.018),

              // Update Status Button
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TechnitianChecklist(
                          equipmentID: task.id.toString(),
                          caseNo: task.caseNo,
                          equipmentName: task.equipmentName,
                          EquipmentArea: task.equipmentArea,
                          EquipmentLocation: task.equipmentLocatoin,
                          failedChecklistKey: task.failedChecklistKey,
                          technician1: task.technicianName,
                          technician2:
                              task.newtechnicianName ?? 'No Any Technician',
                          status: task.status,
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFDDDDDD)),
                    backgroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.07,
                      vertical: sh * 0.012,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(sw * 0.02),
                    ),
                    shadowColor: Colors.black12,
                    elevation: 1,
                  ),
                  child: Text(
                    'Update Status',
                    style: TextStyle(
                      fontSize: sw * 0.035,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF222222),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String value,
    required double sw,
  }) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: sw * 0.037,
          color: const Color(0xFF333333),
          height: 1.4,
        ),
        children: [
          TextSpan(
            text: '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: sw * 0.037,
              color: const Color(0xFF111111),
            ),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

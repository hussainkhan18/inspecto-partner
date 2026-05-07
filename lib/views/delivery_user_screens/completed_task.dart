import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:techno_shield/models/completed_task_model.dart';
import 'package:techno_shield/view_models/staff_view_model.dart';
import 'package:techno_shield/views/delivery_user_screens/completedTaskDetails.dart';
import 'package:provider/provider.dart';

class CompletedTaskScreen extends StatefulWidget {
  const CompletedTaskScreen({super.key});

  @override
  State<CompletedTaskScreen> createState() => _CompletedTaskScreenState();
}

class _CompletedTaskScreenState extends State<CompletedTaskScreen> {
  Future<List<CompletedTasksModel>>? futureCompletedTask;

  Future<List<CompletedTasksModel>> fetchCompletedTasks(String staffId) async {
    final response = await http.get(
      Uri.parse(
        'https://inspecto-partner.stageserverofbss.com/api/history/$staffId',
      ),
    );
    print(staffId);

    if (response.statusCode == 200) {
      print(response.statusCode);
      Map<String, dynamic> json = jsonDecode(response.body);
      print(json);
      if (json['success']) {
        List<dynamic> data = json['data'];
        return data.map((task) => CompletedTasksModel.fromJson(task)).toList();
      } else {
        return [];
      }
    } else {
      return [];
    }
  }

  void refreshPage() {
    setState(() {
      futureCompletedTask = fetchCompletedTasks(
        Provider.of<StaffViewModel>(
          context,
          listen: false,
        ).currentStaff!.id.toString(),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    final staffViewModel = Provider.of<StaffViewModel>(context, listen: false);
    final user = staffViewModel.currentStaff;
    if (user != null) {
      futureCompletedTask = fetchCompletedTasks(user.id.toString());
    } else {
      futureCompletedTask = Future.error('User is not logged in');
    }
  }

  showStatus(int status, String taskStatus) {
    if (status == 2) {
      return 'Not Resolved';
    } else if (status == 3) {
      return 'Approved  By Admin';
    } else if (status == 1) {
      return 'Not Approved  By Admin';
    } else if (status == 5) {
      return taskStatus;
    } else {
      return "Not Defined";
    }
  }

  showTechnicianName(technician, newTechnician, status, taskStatus) {
    if (status == 5 && taskStatus == 'Not Resolved') {
      return technician;
    } else if (status == 5 && taskStatus == 'Resolved') {
      return newTechnician;
    } else {
      return technician;
    }
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
          'Completed Tasks',
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
      body: FutureBuilder<List<CompletedTasksModel>>(
        future: futureCompletedTask,
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
            List<CompletedTasksModel> completedTasks = snapshot.data!;

            // ✅ Sort by updated_at in descending order (latest first)
            completedTasks.sort((a, b) {
              final dateA =
                  DateTime.tryParse(a.updatedAt ?? '') ?? DateTime(2000);
              final dateB =
                  DateTime.tryParse(b.updatedAt ?? '') ?? DateTime(2000);
              return dateB.compareTo(dateA); // Latest first
            });

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.038,
                vertical: sh * 0.02,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section title
                  Padding(
                    padding: EdgeInsets.only(
                      left: sw * 0.01,
                      bottom: sh * 0.018,
                    ),
                    child: Text(
                      'Completed Tasks',
                      style: TextStyle(
                        fontSize: sw * 0.058,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111111),
                      ),
                    ),
                  ),

                  // Task cards
                  ...completedTasks.map(
                    (task) => _buildOrderCard(context, task, sw, sh),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    CompletedTasksModel task,
    double sw,
    double sh,
  ) {
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
              // Header: Task # and Status
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
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.025,
                      vertical: sh * 0.005,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status, task.taskStatus),
                      borderRadius: BorderRadius.circular(sw * 0.015),
                    ),
                    child: Text(
                      showStatus(task.status, task.taskStatus),
                      style: TextStyle(
                        fontSize: sw * 0.03,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
                label: 'Equipment Name',
                value: task.companyEquipmentName,
                sw: sw,
              ),
              SizedBox(height: sh * 0.010),
              _buildField(
                label: 'Equipment Area',
                value: task.area,
                sw: sw,
              ),
              SizedBox(height: sh * 0.010),
              _buildField(
                label: 'Equipment Location',
                value: task.location,
                sw: sw,
              ),
              SizedBox(height: sh * 0.010),
              _buildField(
                label: 'Failed Checklist Key',
                value: task.badFactorName,
                sw: sw,
              ),

              SizedBox(height: sh * 0.018),

              // View Button
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    print('🔊 Voice URL: ${task.voice}');
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => Completedtaskdetails(
                          eqipmentName: task.companyEquipmentName,
                          department: task.department,
                          area: task.area,
                          location: task.location,
                          inspectorName: task.inspectorName,
                          badFactorName: task.badFactorName,
                          resolveImage: task.resolveImage,
                          voiceUrl: task.voice, // ✅ NEW: Pass voice URL
                          inspectionDate: task.inspectionDate,
                          note: task.note,
                          caseNo: task.caseNo,
                          technicianName: task.technicianName,
                          newTechnicianName: task.newTechnicianName ?? '',
                          status: task.status,
                          taskStatus: task.taskStatus,
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
                    'View',
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

  // Reusable field
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

  // Status badge color
  Color _getStatusColor(int status, String taskStatus) {
    if (status == 2) return const Color(0xFFE53935); // Not Resolved — red
    if (status == 3) return const Color(0xFF43A047); // Approved — green
    if (status == 1) return const Color(0xFFFB8C00); // Not Approved — orange
    if (status == 5 && taskStatus == 'Resolved')
      return const Color(0xFF43A047); // Resolved — green
    if (status == 5 && taskStatus == 'Not Resolved')
      return const Color(0xFFE53935); // Not Resolved — red
    return const Color(0xFF8A96A3); // Default — grey
  }
}

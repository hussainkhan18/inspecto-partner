import 'package:flutter/material.dart';
import 'package:techno_shield/widgets/audio_Player_Widget.dart';
import '/helper/style.dart' as style;

class Completedtaskdetails extends StatefulWidget {
  final String eqipmentName;
  final String department;
  final String area;
  final String location;
  final String inspectorName;
  final String badFactorName;
  final String resolveImage;
  final String? voiceUrl; // ✅ NEW: Voice URL parameter
  final String inspectionDate;
  final String note;
  final String caseNo;
  final String technicianName;
  final String? newTechnicianName;
  final int status;
  final String taskStatus;

  const Completedtaskdetails({
    super.key,
    required this.eqipmentName,
    required this.department,
    required this.area,
    required this.location,
    required this.inspectorName,
    required this.badFactorName,
    required this.resolveImage,
    this.voiceUrl, // ✅ NEW: Optional voice URL
    required this.inspectionDate,
    required this.note,
    required this.caseNo,
    required this.technicianName,
    required this.newTechnicianName,
    required this.status,
    required this.taskStatus,
  });

  @override
  State<Completedtaskdetails> createState() => _CompletedtaskdetailsState();
}

class _CompletedtaskdetailsState extends State<Completedtaskdetails> {
  showTechnicianName(technician, newTechnician, status, taskStatus) {
    if (status == 5 && taskStatus == 'Not Resolved') {
      return technician ?? '';
    } else if (status == 5 && taskStatus == 'Resolved') {
      return newTechnician ?? '';
    } else if (status == 3 || status == 1) {
      return technician;
    } else {
      return technician;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    print('new technician ${widget.newTechnicianName}');
    print('status ${widget.status}');
    print('task status ${widget.taskStatus}');
    print('technician name ${widget.technicianName}');
    print('voice url ${widget.voiceUrl}'); // ✅ NEW: Log voice URL

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        iconTheme: const IconThemeData(
          color: style.appColor,
        ),
        title: Text('Task No. ${widget.caseNo}'),
        centerTitle: false,
        titleTextStyle: style.pageTitle(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 12.0 : 16.0,
            vertical: 16.0,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════════════
              // IMAGE SECTION
              // ═══════════════════════════════════════════════════════
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.resolveImage,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 250,
                        color: Colors.grey.shade200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Image not available',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ═══════════════════════════════════════════════════════
              // AUDIO PLAYER SECTION (NEW)
              // ═══════════════════════════════════════════════════════
              if (widget.voiceUrl != null && widget.voiceUrl!.isNotEmpty)
                Column(
                  children: [
                    AudioPlayerWidget(voiceUrl: widget.voiceUrl!),
                    const SizedBox(height: 24),
                  ],
                ),

              // ═══════════════════════════════════════════════════════
              // DETAILS SECTION
              // ═══════════════════════════════════════════════════════
              Text(
                'Task Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 12),

              _buildDataRow(
                context,
                label: 'Equipment Name',
                value: widget.eqipmentName,
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),

              _buildDataRow(
                context,
                label: 'Area',
                value: widget.area,
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),

              _buildDataRow(
                context,
                label: 'Location',
                value: widget.location,
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),

              _buildDataRow(
                context,
                label: 'Department',
                value: widget.department,
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),

              _buildDataRow(
                context,
                label: 'Bad Factor',
                value: widget.badFactorName,
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),

              _buildDataRow(
                context,
                label: 'Inspector Name',
                value: widget.inspectorName,
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),

              _buildDataRow(
                context,
                label: 'Technician Name',
                value: showTechnicianName(
                  widget.technicianName,
                  widget.newTechnicianName,
                  widget.status,
                  widget.taskStatus,
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),

              _buildDataRow(
                context,
                label: 'Inspection Date',
                value: widget.inspectionDate,
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),

              _buildDataRow(
                context,
                label: 'Note by Technician',
                value: widget.note,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

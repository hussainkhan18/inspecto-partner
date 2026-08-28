import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/LanguageTranslate/app_localizations.dart';
import 'package:inspecto_shield_partner/services/complaints_service.dart';
import 'package:inspecto_shield_partner/services/record_service.dart';
import 'package:intl/intl.dart';
// ⬇ Add this import for detail screen
import 'complaint_detail_screen.dart';

class MyRecords extends StatefulWidget {
  final int id;
  const MyRecords({super.key, required this.id});

  @override
  State<MyRecords> createState() => _MyRecordsState();
}

class _MyRecordsState extends State<MyRecords>
    with SingleTickerProviderStateMixin {
  List<dynamic> recordList = [];
  List<dynamic> complaintList = [];
  bool isLoadingRecords = true;
  bool isLoadingComplaints = false;

  static const primaryColor = Color(0xff0DC5B9);
  static const complaintColor = Color(0xffFF6B35);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChange);
    getRecordList();
  }

  void _onTabChange() {
    if (_tabController.index == 1 &&
        complaintList.isEmpty &&
        !isLoadingComplaints) {
      getComplaintsList();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> getRecordList() async {
    try {
      final records = await RecordService.getRecordList(widget.id);
      if (!mounted) return;
      setState(() {
        recordList = records.reversed.toList();
        isLoadingRecords = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingRecords = false);
    }
  }

  Future<void> getComplaintsList() async {
    if (!mounted) return;
    setState(() => isLoadingComplaints = true);

    try {
      final response = await ComplaintService.getComplaintsList(widget.id);
      if (!mounted) return;

      if (response['success'] == true) {
        setState(() {
          complaintList = response['data'] ?? [];
          isLoadingComplaints = false;
        });
      } else {
        if (mounted) {
          setState(() => isLoadingComplaints = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(response['message'] ?? 'Error loading complaints')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingComplaints = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2FAFA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(8, 10, 20, 10),
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CupertinoButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.chevron_back, size: 25),
                        SizedBox(width: 2),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.translate("My Records"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff1C2B2B),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // ── Tab Bar ──────────────────────────────────────
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: primaryColor,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: primaryColor,
                indicatorWeight: 3,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 6),
                        const Text(
                          'Inspections',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (!isLoadingRecords && recordList.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${recordList.length}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assignment_outlined, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          'Complaints',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (!isLoadingComplaints &&
                            complaintList.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: complaintColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${complaintList.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: complaintColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ── Tab Content ──────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // ── TAB 1: RECORDS ──────────────────────────
                  _buildRecordsTab(),

                  // ── TAB 2: COMPLAINTS ──────────────────────
                  _buildComplaintsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── RECORDS TAB ──────────────────────────────────────────
  Widget _buildRecordsTab() {
    return isLoadingRecords
        ? const Center(
            child: CircularProgressIndicator(
              color: primaryColor,
              strokeWidth: 2.5,
            ),
          )
        : recordList.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.folder_open_outlined,
                        size: 44, color: primaryColor.withOpacity(0.35)),
                    const SizedBox(height: 10),
                    Text(
                      AppLocalizations.of(context)!
                          .translate("No Records Found"),
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                itemCount: recordList.length,
                itemBuilder: (context, index) {
                  return _buildRecordCard(index);
                },
              );
  }

  // ── COMPLAINTS TAB ──────────────────────────────────────
  Widget _buildComplaintsTab() {
    return isLoadingComplaints
        ? const Center(
            child: CircularProgressIndicator(
              color: complaintColor,
              strokeWidth: 2.5,
            ),
          )
        : complaintList.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 44, color: complaintColor.withOpacity(0.35)),
                    const SizedBox(height: 10),
                    Text(
                      'No Complaints',
                      style:
                          TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                itemCount: complaintList.length,
                itemBuilder: (context, index) {
                  return _buildComplaintCard(index);
                },
              );
  }

  // ── RECORD CARD ──────────────────────────────────────────
  Widget _buildRecordCard(int index) {
    String datetimeStr = recordList[index][1].toString();
    DateTime datetime = DateTime.parse(
            datetimeStr.contains('Z') ? datetimeStr : '${datetimeStr}Z')
        .toLocal();
    String formattedDate = DateFormat('dd MMM yy').format(datetime);
    String formattedTime = DateFormat('hh:mm a').format(datetime);

    String equipmentText = recordList[index][0].toString();
    String locationText = recordList[index][2].toString();
    String areaText = recordList[index][4].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.28),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              equipmentText,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 1,
              color: Colors.white.withOpacity(0.25),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _cardCell(
                      label: "WHEN",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.80),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _vDivider(),
                  Expanded(
                    flex: 4,
                    child: _cardCell(
                      label: "LOCATION",
                      child: Text(
                        locationText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                  _vDivider(),
                  Expanded(
                    flex: 4,
                    child: _cardCell(
                      label: "AREA",
                      child: Text(
                        areaText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── COMPLAINT CARD (Tap to open detail screen) ───────────
  Widget _buildComplaintCard(int index) {
    final complaint = complaintList[index] as Map<String, dynamic>;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ComplaintDetailScreen(complaint: complaint),
          ),
        );
      },
      child: _complaintCardContent(complaint),
    );
  }

  Widget _complaintCardContent(Map<String, dynamic> complaint) {
    String datetimeStr = complaint['created_at'].toString();
    DateTime datetime = DateTime.parse(
            datetimeStr.contains('Z') ? datetimeStr : '${datetimeStr}Z')
        .toLocal();
    String formattedDate = DateFormat('dd MMM yy').format(datetime);
    String formattedTime = DateFormat('hh:mm a').format(datetime);

    String complaintNumber = complaint['complaint_number'].toString();
    String priority = complaint['priority'].toString().toLowerCase();
    String status = complaint['status'].toString().toLowerCase();
    String remarks = complaint['remarks']?.toString() ?? 'No remarks';

    Color priorityColor;
    if (priority == 'high') {
      priorityColor = Colors.red.shade600;
    } else if (priority == 'medium') {
      priorityColor = Colors.orange.shade600;
    } else {
      priorityColor = Colors.yellow.shade700;
    }

    List<dynamic> images = complaint['images'] ?? [];
    bool hasVoiceNote = complaint['voice_note'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: complaintColor, width: 4),
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: Number | Priority Badge | Status ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    complaintNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xff1C2B2B),
                    ),
                  ),
                ),
                // Priority badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: priorityColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: complaintColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: complaintColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Remarks ────────────────────────────────────
            Text(
              remarks,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 10),

            // ── Images + Voice preview ──────────────────────
            Row(
              children: [
                if (images.isNotEmpty)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${images.length} image${images.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hasVoiceNote)
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.mic_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Voice note',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Date + Time ────────────────────────────────
            Text(
              '$formattedDate · $formattedTime',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardCell({required String label, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.65),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      color: Colors.white.withOpacity(0.25),
    );
  }
}

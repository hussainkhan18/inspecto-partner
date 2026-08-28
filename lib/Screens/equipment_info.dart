import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/LanguageTranslate/app_localizations.dart';
import 'package:inspecto_shield_partner/Screens/view_certificate.dart';
import 'package:inspecto_shield_partner/services/equipment_service.dart';
import 'package:loading_icon_button/loading_icon_button.dart';

class EquipementInfo extends StatefulWidget {
  final Map data;

  const EquipementInfo({super.key, required this.data});

  @override
  State<EquipementInfo> createState() => _EquipementInfoState();
}

class _EquipementInfoState extends State<EquipementInfo> {
  String certificateImgUrl = "";
  bool _isLoading = true;
  Map<String, dynamic>? _equipmentData;

  // ─── Brand color ───
  static const Color _teal = Color(0xff0DC5B9);

  Future<Map<String, dynamic>?> fetchEquipmentData(String reportId) async {
    return await EquipmentService.fetchEquipmentData(reportId);
  }

  Future<void> _fetchEquipmentData() async {
    try {
      final data =
          await fetchEquipmentData(widget.data["report_id"].toString());
      setState(() {
        _equipmentData = data;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching equipment data: $error');
    }
  }

  Future<void> getCertificateData() async {
    try {
      final imageUrl = await EquipmentService.getCertificateData(
        widget.data["report_id"].toString(),
      );
      if (imageUrl != null) {
        setState(() {
          certificateImgUrl = imageUrl;
        });
      }
    } catch (e) {
      print({"error": e.toString()});
    }
  }

  @override
  void initState() {
    super.initState();
    getCertificateData();
    _fetchEquipmentData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F8FA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: _teal,
                strokeWidth: 2.5,
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),

                  // ─── Equipment Image Card ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 28, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Equipment image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _equipmentData?["equipment_img"] ??
                                  "https://hashbaqala.bssstageserverforpanels.xyz/upload/profileImage/user.png",
                              fit: BoxFit.contain,
                              height: MediaQuery.of(context).size.height / 6,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // View Certificate Button
                          ArgonButton(
                            width: 190,
                            height: 46,
                            borderRadius: 10.0,
                            elevation: 4,
                            color: _teal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.verified_outlined,
                                    color: Colors.white, size: 16),
                                const SizedBox(width: 7),
                                Text(
                                  AppLocalizations.of(context)!
                                      .translate("View Certificate"),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                            onTap: (startLoading, stopLoading, btnState) {
                              startLoading();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenImageView(
                                    imageUrl: certificateImgUrl,
                                  ),
                                ),
                              ).then((_) => stopLoading());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── Main Info Card ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          _buildSectionHeader(
                              Icons.info_outline, "Equipment Details"),
                          const SizedBox(height: 12),

                          _buildDataRow(
                            label: "EQUIPMENT NAME",
                            value: _equipmentData?["equipment_name"],
                          ),
                          _buildDataRow(
                            label: "LOCATION",
                            value: _equipmentData?["location_description"],
                          ),
                          _buildDataRow(
                            label: "CATEGORY",
                            value: _equipmentData?["equipment_sub_category"],
                          ),
                          _buildDataRow(
                            label: "TYPE",
                            value: _equipmentData?["equipment_type"],
                          ),
                          _buildDataRow(
                            label: "FAMILY",
                            value: _equipmentData?["equipment_category"],
                          ),
                          _buildDataRow(
                            label: "LAST INSPECTION",
                            value: _equipmentData?["last_inspection_date"] ??
                                "Not Available",
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Accordion: Purchase & Warranty Details ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          colorScheme: Theme.of(context).colorScheme.copyWith(
                                surface: Colors.white,
                              ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            childrenPadding: EdgeInsets.zero,
                            iconColor: _teal,
                            collapsedIconColor: _teal,
                            backgroundColor: Colors.white,
                            collapsedBackgroundColor: Colors.white,
                            title: Row(
                              children: const [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  color: _teal,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Purchase & Warranty Details",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _teal,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              // thin separator line
                              Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: Colors.grey.shade100),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                child: Column(
                                  children: [
                                    _buildDataRow(
                                      label: "PURCHASE DATE",
                                      value: _equipmentData?["purchase_date"],
                                    ),
                                    _buildDataRow(
                                      label: "PURCHASE PRICE",
                                      value: _equipmentData?[
                                                  "purchase_price"] !=
                                              null
                                          ? "PKR ${_equipmentData!["purchase_price"]}"
                                          : null,
                                    ),
                                    _buildDataRow(
                                      label: "WARRANTY EXPIRY",
                                      value: _equipmentData?[
                                          "warranty_expiry_date"],
                                    ),
                                    _buildInvoiceRow(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ─── Section header ───
  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: _teal, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _teal,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ─── Reusable label + value row ───
  Widget _buildDataRow({
    required String label,
    String? value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label
              SizedBox(
                width: 140,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Value
              Expanded(
                child: Text(
                  value ?? "—",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff1A1A2E),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
      ],
    );
  }

  // ─── Invoice row with tappable "View Invoice" link ───
  Widget _buildInvoiceRow() {
    final invoiceUrl = _equipmentData?["invoice_attachment"];
    final hasInvoice = invoiceUrl != null && invoiceUrl.toString().isNotEmpty;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 140,
                child: Text(
                  "INVOICE",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: hasInvoice
                    ? GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FullScreenImageView(imageUrl: invoiceUrl),
                            ),
                          );
                        },
                        child: const Text(
                          "View Invoice",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _teal,
                            decoration: TextDecoration.underline,
                            decorationColor: _teal,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      )
                    : Text(
                        "—",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade400,
                        ),
                        textAlign: TextAlign.right,
                      ),
              ),
            ],
          ),
        ),
        // No divider after last row
      ],
    );
  }
}

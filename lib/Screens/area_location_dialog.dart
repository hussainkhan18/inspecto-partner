import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/models/offline_data_model.dart';
import 'package:inspecto_shield_partner/services/offline_equipment_service.dart';

Future<Map<String, String>?> showAreaLocationDialog(BuildContext context) {
  return showDialog<Map<String, String>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _AreaLocationDialogContent(),
  );
}

class _AreaLocationDialogContent extends StatefulWidget {
  const _AreaLocationDialogContent();

  @override
  State<_AreaLocationDialogContent> createState() =>
      _AreaLocationDialogContentState();
}

class _AreaLocationDialogContentState
    extends State<_AreaLocationDialogContent> {
  List<OfflineAreaModel> _areas = [];
  List<OfflineLocationModel> _locations = [];

  OfflineAreaModel? _selectedArea;
  OfflineLocationModel? _selectedLocation;

  bool _isLoadingAreas = true;
  bool _isLoadingLocations = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAreas();
  }

  Future<void> _loadAreas() async {
    setState(() {
      _isLoadingAreas = true;
      _errorMessage = null;
    });

    final areas = await OfflineEquipmentService.fetchOfflineAreas();

    if (!mounted) return;
    setState(() {
      _areas = areas;
      _isLoadingAreas = false;
      _errorMessage =
          areas.isEmpty ? 'Could not load areas. Check your connection.' : null;
    });
  }

  Future<void> _onAreaSelected(OfflineAreaModel? area) async {
    setState(() {
      _selectedArea = area;
      _selectedLocation = null;
      _locations = [];
    });

    if (area == null) return;

    setState(() => _isLoadingLocations = true);
    final locations =
        await OfflineEquipmentService.fetchOfflineLocations(area.id);
    if (!mounted) return;
    setState(() {
      _locations = locations;
      _isLoadingLocations = false;
    });
  }

  bool get _canProceed => _selectedArea != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: _buildContent(),
            ),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Color(0xFF0DC5B9).withOpacity(0.06),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFF0DC5B9).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wifi_off_rounded,
                color: Color(0xFF0DC5B9), size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Go Offline',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A))),
                SizedBox(height: 2),
                Text('Choose where you will be inspecting',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoadingAreas) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.4, color: Color(0xFF0DC5B9)),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 28),
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF0DC5B9)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _loadAreas,
              icon: const Icon(Icons.refresh_rounded,
                  size: 16, color: Color(0xFF0DC5B9)),
              label: const Text('Retry',
                  style: TextStyle(color: Color(0xFF0DC5B9))),
            ),
          ),
        ],
      );
    }

    if (_areas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Text('No areas available.',
            style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Area', required: true),
        const SizedBox(height: 6),
        _dropdownShell(
          isFilled: _selectedArea != null,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<OfflineAreaModel>(
              value: _selectedArea,
              isExpanded: true,
              hint: Text('Select an area',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF0DC5B9)),
              items: _areas
                  .map((a) => DropdownMenuItem(
                        value: a,
                        child: Text(a.name,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0F172A))),
                      ))
                  .toList(),
              onChanged: _onAreaSelected,
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: _selectedArea == null
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _fieldLabel('Select Location'),
                      const SizedBox(height: 6),
                      if (_isLoadingLocations)
                        Container(
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF0DC5B9)),
                          ),
                        )
                      else if (_locations.isNotEmpty)
                        _dropdownShell(
                          isFilled: _selectedLocation != null,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<OfflineLocationModel>(
                              value: _selectedLocation,
                              isExpanded: true,
                              hint: Text('Select a location',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 13)),
                              icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Color(0xFF0DC5B9)),
                              items: _locations
                                  .map((l) => DropdownMenuItem(
                                        value: l,
                                        child: Text(l.name,
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF0F172A))),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedLocation = val),
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded,
                                  size: 15, color: Colors.grey.shade500),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No specific locations — area-level data will be used.',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String label, {bool required = false, String? hint}) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A))),
        if (required) ...[
          const SizedBox(width: 3),
          const Text('*',
              style: TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
        ],
        if (hint != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(hint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500)),
          ),
        ],
      ],
    );
  }

  Widget _dropdownShell({required Widget child, bool isFilled = false}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFilled ? Color(0xFF0DC5B9) : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
                backgroundColor: Color(0xFF0DC5B9),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _canProceed
                  ? () {
                      Navigator.of(context).pop({
                        'areaId': _selectedArea!.id,
                        'areaName': _selectedArea!.name,
                        if (_selectedLocation != null)
                          'locationId': _selectedLocation!.id,
                        if (_selectedLocation != null)
                          'locationName': _selectedLocation!.name,
                      });
                    }
                  : null,
              child: const Text('Continue',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

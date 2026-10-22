import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/services/gemba_walk_service.dart';

class InlineCapaForm extends StatefulWidget {
  final Map<String, dynamic> gembaData;
  final List<Map<String, dynamic>> questions;
  final List<int> nonCompliantIds;

  const InlineCapaForm({
    super.key,
    required this.gembaData,
    required this.questions,
    required this.nonCompliantIds,
  });

  @override
  State<InlineCapaForm> createState() => InlineCapaFormState();
}

class InlineCapaFormState extends State<InlineCapaForm> {
  static const Color _teal = Color(0xff0DC5B9);
  static const Color _ink = Color(0xff1E293B);
  static const Color _muted = Color(0xff64748B);
  static const Color _bg = Color(0xffF8FAFC);
  static const Color _border = Color(0xffE2E8F0);

  final GembaWalkService _service = GembaWalkService();

  bool _isLoadingOptions = true;
  bool _isSubmitting = false;
  String? _optionsError;

  String _adminLabel = 'Admin can assign';
  String _adminHint = 'Refer this CAPA to Branch Admin';

  List<Map<String, dynamic>> _inspectors = [];
  List<Map<String, dynamic>> _points = [];

  int? _selectedInspectorId;
  bool _adminAssign = false;

  final Map<int, TextEditingController> _capaDescriptions = {};
  final Set<int> _selectedQuestionIds = {};

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    final walkId = widget.gembaData['id'] as int?;
    if (walkId == null) {
      setState(() {
        _optionsError = 'Invalid walk id';
        _isLoadingOptions = false;
      });
      return;
    }

    final result = await _service.fetchCapaOptions(walkId);
    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;
      final points = (data['points'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((p) => p['response'] == 'non_compliance')
          .toList();

      final inspectors = (data['inspectors'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      final adminOpt = data['admin_can_assign_option'];
      if (adminOpt is Map) {
        _adminLabel = adminOpt['label']?.toString() ?? _adminLabel;
        _adminHint = adminOpt['hint']?.toString() ?? _adminHint;
      }

      final meInspector = inspectors.firstWhere(
        (i) => i['is_me'] == true,
        orElse: () =>
            inspectors.isNotEmpty ? inspectors.first : <String, dynamic>{},
      );

      final dynamic rawId = meInspector['id'];
      final int? parsedId =
          rawId is int ? rawId : int.tryParse('${rawId ?? ''}');

      setState(() {
        _points = points;
        _inspectors = inspectors;
        _selectedInspectorId = parsedId;
        _isLoadingOptions = false;
      });
    } else {
      setState(() {
        _optionsError = result['message']?.toString() ?? 'Failed';
        _isLoadingOptions = false;
      });
    }
  }

  @override
  void dispose() {
    for (var c in _capaDescriptions.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submitCapa() async {
    if (_selectedQuestionIds.isEmpty) {
      _snack('Please select at least one question', Colors.red);
      return;
    }

    for (var qId in _selectedQuestionIds) {
      final desc = _capaDescriptions[qId]?.text.trim() ?? '';
      if (desc.isEmpty) {
        _snack(
            'Please write description for all selected questions', Colors.red);
        return;
      }
    }

    if (!_adminAssign && _selectedInspectorId == null) {
      _snack('Please select an inspector', Colors.red);
      return;
    }

    final walkId = widget.gembaData['id'] as int?;
    if (walkId == null) return;

    final capas = _selectedQuestionIds.map((qId) {
      final Map<String, dynamic> item = {
        'checklist_item_id': qId,
        'description': _capaDescriptions[qId]?.text.trim() ?? '',
      };
      if (_adminAssign) {
        item['refer_to_admin'] = true;
      } else {
        item['assigned_to'] = _selectedInspectorId;
      }
      return item;
    }).toList();

    setState(() => _isSubmitting = true);

    final result = await _service.submitCapas(walkId: walkId, capas: capas);
    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      _snack(result['message']?.toString() ?? 'CAPA created', Colors.green);
      for (var c in _capaDescriptions.values) {
        c.dispose();
      }
      setState(() {
        _capaDescriptions.clear();
        _selectedQuestionIds.clear();
      });
    } else {
      _snack(result['message']?.toString() ?? 'Failed', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingOptions) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }

    if (_optionsError != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(_optionsError!, style: const TextStyle(color: _muted)),
        ),
      );
    }

    final area = widget.gembaData['area']?.toString() ?? 'N/A';
    final purpose = widget.gembaData['purpose']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _teal.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Area', area),
          const SizedBox(height: 8),
          _buildInfoRow('Walk Type', purpose),
          const SizedBox(height: 16),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 14),
          const Text('SELECT QUESTIONS',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                  letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                hint: const Text('Choose a question',
                    style: TextStyle(fontSize: 13, color: _muted)),
                value: null,
                items: _points
                    .where((p) =>
                        !_selectedQuestionIds.contains(p['checklist_item_id']))
                    .map((p) => DropdownMenuItem<int>(
                          value: p['checklist_item_id'] as int,
                          child: Text(p['item']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12.5),
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selectedQuestionIds.add(val);
                    _capaDescriptions[val] = TextEditingController();
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._selectedQuestionIds.map((qId) {
            final p = _points.firstWhere(
              (e) => e['checklist_item_id'] == qId,
              orElse: () => <String, dynamic>{'item': ''},
            );
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(p['item']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: _ink)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _selectedQuestionIds.remove(qId);
                          _capaDescriptions[qId]?.dispose();
                          _capaDescriptions.remove(qId);
                        }),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _capaDescriptions[qId],
                    maxLines: 3,
                    style: const TextStyle(fontSize: 12.5, color: _ink),
                    decoration: InputDecoration(
                      hintText: 'Describe the corrective action...',
                      hintStyle: const TextStyle(fontSize: 11.5, color: _muted),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade400),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _teal, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 15),
          const Text('ASSIGN CAPA',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _muted,
                  letterSpacing: 1.0)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _adminAssign ? Colors.grey.shade200 : _bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                hint: const Text('Select Mobile Inspector',
                    style: TextStyle(fontSize: 13, color: _muted)),
                value: _adminAssign ? null : _selectedInspectorId,
                items: _inspectors
                    .map((ins) => DropdownMenuItem<int>(
                          value: ins['id'] as int,
                          child: Text(ins['name']?.toString() ?? '',
                              style: const TextStyle(fontSize: 12.5)),
                        ))
                    .toList(),
                onChanged: _adminAssign
                    ? null
                    : (val) => setState(() => _selectedInspectorId = val),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: CheckboxListTile(
              value: _adminAssign,
              onChanged: (val) {
                setState(() {
                  _adminAssign = val ?? false;
                  if (_adminAssign) _selectedInspectorId = null;
                });
              },
              activeColor: _teal,
              title: Text(_adminLabel,
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _ink)),
              subtitle: Text(_adminHint,
                  style: const TextStyle(fontSize: 10.5, color: _muted)),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitCapa,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                _isSubmitting ? 'SUBMITTING...' : 'SUBMIT CAPA',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade400,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11.5, color: _muted, fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
                fontSize: 12.5, color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

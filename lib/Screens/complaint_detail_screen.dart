import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inspecto_shield_partner/Screens/audio_player_widget.dart';
import 'package:intl/intl.dart';

class ComplaintDetailScreen extends StatefulWidget {
  final Map<String, dynamic> complaint;
  const ComplaintDetailScreen({super.key, required this.complaint});

  @override
  State<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends State<ComplaintDetailScreen> {
  static const complaintColor = Color(0xffFF6B35);

  late PageController _imagePageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  String _formatDateTime(String datetimeStr) {
    try {
      DateTime datetime = DateTime.parse(
              datetimeStr.contains('Z') ? datetimeStr : '${datetimeStr}Z')
          .toLocal();
      String formattedDate = DateFormat('dd MMM yyyy').format(datetime);
      String formattedTime = DateFormat('hh:mm a').format(datetime);
      return '$formattedDate at $formattedTime';
    } catch (e) {
      return datetimeStr;
    }
  }

  Color _getPriorityColor(String priority) {
    priority = priority.toLowerCase();
    if (priority == 'high') {
      return Colors.red.shade600;
    } else if (priority == 'medium') {
      return Colors.orange.shade600;
    } else {
      return Colors.yellow.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final complaintNumber = complaint['complaint_number'].toString();
    final priority = complaint['priority'].toString();
    final status = complaint['status'].toString().toLowerCase();
    final remarks = complaint['remarks']?.toString() ?? 'No remarks';
    final images = complaint['images'] as List<dynamic>? ?? [];

    // ✅ DEBUG: Print full complaint data
    print('🔍 COMPLAINT DATA: $complaint');
    print('📋 Has voice_note key: ${complaint.containsKey('voice_note')}');
    print('🔊 Voice note value: ${complaint['voice_note']}');

    final voiceNote = complaint['voice_note'] as Map<String, dynamic>?;
    final createdAt = complaint['created_at'].toString();

    return Scaffold(
      backgroundColor: const Color(0xffF2FAFA),
      body: SafeArea(
        child: Column(
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
                      'Complaint Details',
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

            // ── Content ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Complaint Header Card ───────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border(
                          left: BorderSide(color: complaintColor, width: 4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Number
                          Text(
                            complaintNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff1C2B2B),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Badges
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(priority)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Priority: ${priority.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _getPriorityColor(priority),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: complaintColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Status: ${status.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: complaintColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Created at
                          Text(
                            'Created: ${_formatDateTime(createdAt)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Remarks ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.12),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Remarks',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff1C2B2B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            remarks,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Images Gallery ──────────────────────────
                    if (images.isNotEmpty) ...[
                      _buildImagesGallery(images),
                      const SizedBox(height: 16),
                    ],

                    // ── Voice Note Player (✅ SHOW VOICE) ───────
                    if (voiceNote != null && voiceNote.isNotEmpty) ...[
                      _buildAudioPlayer(voiceNote),
                      const SizedBox(height: 16),
                    ] else if (complaint.containsKey('voice_note') &&
                        complaint['voice_note'] != null) ...[
                      // Fallback if voiceNote parsing had issues
                      _buildAudioPlayerFallback(complaint['voice_note']),
                      const SizedBox(height: 16),
                    ],

                    // ── DEBUG INFO (Remove in Production) ───────
                    if (voiceNote == null &&
                        !complaint.containsKey('voice_note'))
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.yellow.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.yellow.withOpacity(0.3)),
                        ),
                        child: Text(
                          'ℹ️ No voice note in this complaint',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Images Gallery ───────────────────────────────────────
  Widget _buildImagesGallery(List<dynamic> images) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Images (${images.length})',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xff1C2B2B),
              ),
            ),
          ),

          // Image carousel
          Container(
            height: 300,
            color: const Color(0xffF5F5F5),
            child: PageView.builder(
              controller: _imagePageController,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index] as Map<String, dynamic>;
                final imageUrl = image['url'].toString();

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => FullScreenImage(
                          imageUrl: imageUrl,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: complaintColor,
                              strokeWidth: 2.5,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade300,
                            child: const Center(
                              child: Icon(Icons.image_not_supported_outlined,
                                  size: 40, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Indicator + Navigation
          Container(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentImageIndex + 1} / ${images.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                Row(
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      onPressed: _currentImageIndex > 0
                          ? () => _imagePageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      child: Icon(
                        CupertinoIcons.chevron_back,
                        size: 18,
                        color: _currentImageIndex > 0
                            ? complaintColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      onPressed: _currentImageIndex < images.length - 1
                          ? () => _imagePageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              )
                          : null,
                      child: Icon(
                        CupertinoIcons.chevron_forward,
                        size: 18,
                        color: _currentImageIndex < images.length - 1
                            ? complaintColor
                            : Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Real Audio Player (✅ FULLY WORKING) ────────────────
  Widget _buildAudioPlayer(Map<String, dynamic> voiceNote) {
    final audioUrl = voiceNote['url']?.toString() ?? '';

    if (audioUrl.isEmpty) {
      return _buildErrorCard('No audio URL found');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voice Note',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff1C2B2B),
            ),
          ),
          const SizedBox(height: 12),
          // ✅ USE REAL AUDIO PLAYER
          RealAudioPlayerWidget(
            audioUrl: audioUrl,
            fileName: 'Voice Note',
          ),
        ],
      ),
    );
  }

  // ── Fallback Audio Player (handles any format) ──────────
  Widget _buildAudioPlayerFallback(dynamic voiceNoteData) {
    String audioUrl = '';

    if (voiceNoteData is Map) {
      audioUrl = voiceNoteData['url']?.toString() ?? '';
    } else if (voiceNoteData is String) {
      audioUrl = voiceNoteData;
    }

    if (audioUrl.isEmpty) {
      return _buildErrorCard('No audio URL available');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Voice Note',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xff1C2B2B),
            ),
          ),
          const SizedBox(height: 12),
          RealAudioPlayerWidget(
            audioUrl: audioUrl,
            fileName: 'Voice Note',
          ),
        ],
      ),
    );
  }

  // ── Error Card ──────────────────────────────────────────
  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.red.shade600, fontSize: 12),
      ),
    );
  }
}

// ── Full Screen Image Viewer ────────────────────────────────
class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: const Color(0xffFF6B35),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: CupertinoButton(
                padding: const EdgeInsets.all(8),
                color: Colors.white.withOpacity(0.2),
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(
                  CupertinoIcons.xmark,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

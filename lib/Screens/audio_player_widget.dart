import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class RealAudioPlayerWidget extends StatefulWidget {
  final String audioUrl;
  final String fileName;

  const RealAudioPlayerWidget({
    super.key,
    required this.audioUrl,
    this.fileName = 'Voice Note',
  });

  @override
  State<RealAudioPlayerWidget> createState() => _RealAudioPlayerWidgetState();
}

class _RealAudioPlayerWidgetState extends State<RealAudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = true;
  bool _isSeeking = false; // ✨ Prevent jank while seeking
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      print('🎵 Loading audio from: ${widget.audioUrl}');

      await _audioPlayer.setUrl(widget.audioUrl);
      print('✅ Audio loaded successfully');

      // Set initial duration
      _duration = _audioPlayer.duration ?? Duration.zero;

      // Listen to position changes for smooth real-time updates ✨
      _audioPlayer.positionStream.listen((position) {
        if (mounted && !_isSeeking) {
          setState(() {
            _position = position;
          });
        }
      });

      // Listen to playing state changes
      _audioPlayer.playingStream.listen((isPlaying) {
        if (mounted) {
          setState(() {
            _isPlaying = isPlaying;
          });
        }
      });

      // Fallback: listen to duration updates
      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
          });
        }
      });

      // Update UI after loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading audio: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load audio: ${e.toString()}';
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xffFF6B35),
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Text(
          _errorMessage!,
          style: TextStyle(color: Colors.red.shade600, fontSize: 12),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xffFF6B35).withOpacity(0.08),
            const Color(0xffFF6B35).withOpacity(0.04),
          ],
        ),
        border: Border.all(
          color: const Color(0xffFF6B35).withOpacity(0.15),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // ── Player Controls ──────────────────────────────
          Row(
            children: [
              // Play/Pause Button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xffFF6B35),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xffFF6B35).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Progress Bar + Duration
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Slider
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 5,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6,
                          elevation: 2,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10,
                        ),
                        inactiveTrackColor: Colors.grey.shade300,
                        activeTrackColor: const Color(0xffFF6B35),
                        thumbColor: const Color(0xffFF6B35),
                      ),
                      child: Slider(
                        min: 0,
                        max: _duration.inSeconds.toDouble() > 0
                            ? _duration.inSeconds.toDouble()
                            : 1,
                        value: _position.inSeconds
                            .toDouble()
                            .clamp(0, _duration.inSeconds.toDouble()),
                        onChangeStart: (value) {
                          _isSeeking = true;
                        },
                        onChanged: (value) {
                          setState(() {
                            _position = Duration(seconds: value.toInt());
                          });
                        },
                        onChangeEnd: (value) async {
                          await _seek(Duration(seconds: value.toInt()));
                          _isSeeking = false;
                        },
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Duration Display
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── File Info ────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.audio_file_rounded,
                color: const Color(0xffFF6B35),
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${widget.fileName} • ${_formatDuration(_duration)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

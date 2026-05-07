import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String voiceUrl;

  const AudioPlayerWidget({
    super.key,
    required this.voiceUrl,
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isSeeking = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      setState(() => _isLoading = true);

      // ✅ Direct use karo, double slash fix ke saath
      final String audioUrl = widget.voiceUrl.replaceAll('//voice/', '/voice/');

      await _audioPlayer.setUrl(audioUrl);

      _audioPlayer.playerStateStream.listen((playerState) {
        if (!mounted) return;
        setState(() {
          _isPlaying = playerState.playing;
        });
      });

      _audioPlayer.durationStream.listen((duration) {
        if (!mounted) return;
        setState(() => _duration = duration ?? Duration.zero);
      });

      _audioPlayer.positionStream.listen((position) {
        if (!mounted || _isSeeking) return;
        setState(() => _position = position);
      });

      setState(() => _isLoading = false);
    } catch (e) {
      print('🔴 Audio Error: $e'); // ✅ YE ADD KARO
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load audio';
      });
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
      setState(() => _errorMessage = 'Playback error');
    }
  }

  Future<void> _seekAudio(double seconds) async {
    try {
      await _audioPlayer.seek(Duration(seconds: seconds.toInt()));
      if (!_isPlaying) {
        await _audioPlayer.play();
      }
    } catch (e) {
      setState(() => _errorMessage = 'Seek error');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: const Color(0xFFEF4444).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Color(0xFFEF4444),
              size: 20.0,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xff0DC5B9).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: const Color(0xff0DC5B9).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with mic icon and label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xff0DC5B9).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  color: Color(0xff0DC5B9),
                  size: 20.0,
                ),
              ),
              const SizedBox(width: 12.0),
              const Expanded(
                child: Text(
                  'Voice Note',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),

          // Player controls row
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _isLoading ? null : _togglePlayPause,
                child: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: const Color(0xff0DC5B9),
                    shape: BoxShape.circle,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 20.0,
                        ),
                ),
              ),
              const SizedBox(width: 12.0),

              // Progress bar and time display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slider for seeking
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 6.0,
                          elevation: 2.0,
                        ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10.0,
                        ),
                      ),
                      child: Slider(
                        value: _duration.inMilliseconds > 0
                            ? _position.inMilliseconds
                                .toDouble()
                                .clamp(0.0, _duration.inMilliseconds.toDouble())
                            : 0.0,
                        max: _duration.inMilliseconds.toDouble(),
                        activeColor: const Color(0xff0DC5B9),
                        inactiveColor: const Color(0xff0DC5B9).withOpacity(0.2),
                        onChanged: (value) {
                          setState(() {
                            _isSeeking = true;
                            _position = Duration(milliseconds: value.toInt());
                          });
                        },
                        onChangeEnd: (value) {
                          _seekAudio(value / 1000);
                          setState(() => _isSeeking = false);
                        },
                      ),
                    ),
                    const SizedBox(height: 4.0),

                    // Time display
                    Text(
                      '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

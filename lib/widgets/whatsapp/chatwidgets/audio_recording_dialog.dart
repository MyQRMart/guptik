import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecordingDialog extends StatefulWidget {
  final Function(String?) onSendAudio;
  
  const AudioRecordingDialog({
    super.key,
    required this.onSendAudio,
  });

  @override
  State<AudioRecordingDialog> createState() => _AudioRecordingDialogState();
}

class _AudioRecordingDialogState extends State<AudioRecordingDialog> {
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;
  Duration _recordingDuration = Duration.zero;
  Duration _playbackPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  Timer? _recordingTimer;
  Timer? _playbackTimer;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Made final

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playbackPosition = Duration.zero;
        });
      }
      _playbackTimer?.cancel();
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _playbackPosition = position;
        });
      }
    });
    
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _audioDuration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final hasPermission = await Permission.microphone.isGranted;
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      }
      return;
    }

    try {
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/audio_$timestamp.m4a';
      
      setState(() {
        _isRecording = true;
        _audioPath = path;
        _recordingDuration = Duration.zero;
      });
      
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordingDuration += const Duration(seconds: 1);
          });
        }
      });
      
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    
    if (mounted) {
      setState(() {
        _isRecording = false;
      });
    }
    
    // Create a dummy audio file for testing
    if (_audioPath != null) {
      final file = File(_audioPath!);
      await file.writeAsBytes([0]); // Dummy audio data
    }
  }

  Future<void> _playAudio() async {
    if (_audioPath == null || !File(_audioPath!).existsSync()) return;
    
    try {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
      if (mounted) {
        setState(() {
          _isPlaying = true;
        });
      }
      
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!_isPlaying) {
          timer.cancel();
        }
      });
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
    _playbackTimer?.cancel();
  }

  Future<void> _sendAudio() async {
    if (mounted) {
      Navigator.pop(context);
      widget.onSendAudio(_audioPath);
    }
  }

  void _deleteAudio() {
    if (_audioPath != null && File(_audioPath!).existsSync()) {
      File(_audioPath!).delete();
    }
    if (mounted) {
      setState(() {
        _audioPath = null;
        _isPlaying = false;
        _playbackPosition = Duration.zero;
        _audioDuration = Duration.zero;
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Audio Message'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isRecording)
            Column(
              children: [
                const Icon(Icons.mic, size: 50, color: Colors.red),
                const SizedBox(height: 10),
                Text(
                  'Recording... ${_formatDuration(_recordingDuration)}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
            )
          else if (_audioPath != null)
            Column(
              children: [
                Icon(
                  _isPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 50,
                  color: Colors.green,
                ),
                const SizedBox(height: 10),
                if (_audioDuration > Duration.zero)
                  Slider(
                    value: _playbackPosition.inMilliseconds.toDouble(),
                    min: 0,
                    max: _audioDuration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                Text(
                  '${_formatDuration(_playbackPosition)} / ${_formatDuration(_audioDuration)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            )
          else
            const Column(
              children: [
                Icon(Icons.mic_none, size: 50, color: Colors.grey),
                SizedBox(height: 10),
                Text('Tap to start recording'),
              ],
            ),
        ],
      ),
      actions: [
        if (_audioPath != null)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteAudio,
            tooltip: 'Delete',
          ),
        TextButton(
          onPressed: () {
            if (mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Cancel'),
        ),
        if (_audioPath == null)
          ElevatedButton(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRecording ? Colors.red : Colors.green,
            ),
            child: Text(
              _isRecording ? 'Stop' : 'Record',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        if (_audioPath != null && !_isRecording)
          ElevatedButton(
            onPressed: _isPlaying ? _pauseAudio : _playAudio,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text(
              _isPlaying ? 'Pause' : 'Play',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        if (_audioPath != null)
          ElevatedButton(
            onPressed: _sendAudio,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              'Send',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }
}
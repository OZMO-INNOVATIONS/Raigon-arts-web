import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';

class AudioRecordData {
  const AudioRecordData({
    required this.bytes,
    required this.durationSeconds,
    this.localPath,
  });

  final Uint8List bytes;
  final int durationSeconds;
  final String? localPath;
}

class ReminderAudioService {
  ReminderAudioService() {
    _initPlayerListeners();
  }

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  bool _isRecording = false;
  DateTime? _recordStartTime;
  Timer? _recordTimer;
  int _recordingSeconds = 0;

  bool get isRecording => _isRecording;
  int get recordingSeconds => _recordingSeconds;

  PlayerState _playerState = PlayerState.stopped;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _currentlyPlayingId;

  PlayerState get playerState => _playerState;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  String? get currentlyPlayingId => _currentlyPlayingId;
  bool get isPlaying => _playerState == PlayerState.playing;

  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _recordSecondsController = StreamController<int>.broadcast();

  Stream<PlayerState> get onPlayerStateChanged => _playerStateController.stream;
  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<int> get onRecordSecondsChanged => _recordSecondsController.stream;

  void _safeAdd<T>(StreamController<T> controller, T event) {
    if (_isDisposed) return;
    if (controller.isClosed) return;
    try {
      controller.add(event);
    } catch (_) {}
  }

  void _initPlayerListeners() {
    _playerStateSub = _player.onPlayerStateChanged.listen((state) {
      if (_isDisposed) return;
      _playerState = state;
      if (state == PlayerState.completed) {
        _currentlyPlayingId = null;
        _currentPosition = Duration.zero;
      }
      _safeAdd(_playerStateController, state);
    });

    _positionSub = _player.onPositionChanged.listen((pos) {
      if (_isDisposed) return;
      _currentPosition = pos;
      _safeAdd(_positionController, pos);
    });

    _durationSub = _player.onDurationChanged.listen((dur) {
      if (_isDisposed) return;
      _totalDuration = dur;
      _safeAdd(_durationController, dur);
    });
  }

  Future<bool> startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) return false;

      final config = const RecordConfig(encoder: AudioEncoder.opus);
      await _recorder.start(config, path: '');

      _isRecording = true;
      _recordStartTime = DateTime.now();
      _recordingSeconds = 0;
      _safeAdd(_recordSecondsController, 0);

      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_isDisposed) return;
        if (_recordStartTime != null) {
          _recordingSeconds = DateTime.now().difference(_recordStartTime!).inSeconds;
          _safeAdd(_recordSecondsController, _recordingSeconds);
        }
      });

      return true;
    } catch (e) {
      debugPrint('[ReminderAudioService] startRecording error: $e');
      _isRecording = false;
      return false;
    }
  }

  Future<AudioRecordData?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      _recordTimer?.cancel();
      _isRecording = false;
      final path = await _recorder.stop();
      final durationSec = mathMax(1, _recordingSeconds);

      if (path != null && path.isNotEmpty) {
        Uint8List bytes = Uint8List(0);
        if (path.startsWith('data:')) {
          try {
            final commaIdx = path.indexOf(',');
            if (commaIdx != -1) {
              bytes = base64Decode(path.substring(commaIdx + 1));
            }
          } catch (e) {
            debugPrint('[ReminderAudioService] Decode data URI error: $e');
          }
        } else if (kIsWeb || path.startsWith('blob:') || path.startsWith('http')) {
          try {
            final res = await http.get(Uri.parse(path));
            if (res.statusCode == 200) {
              bytes = res.bodyBytes;
            }
          } catch (e) {
            debugPrint('[ReminderAudioService] Fetch blob error: $e');
          }
        }
        return AudioRecordData(
          bytes: bytes,
          durationSeconds: durationSec,
          localPath: path,
        );
      }
    } catch (e) {
      debugPrint('[ReminderAudioService] stopRecording error: $e');
    }
    return null;
  }

  Future<void> cancelRecording() async {
    try {
      _recordTimer?.cancel();
      _isRecording = false;
      _recordingSeconds = 0;
      await _recorder.cancel();
    } catch (_) {}
  }

  Future<void> playBytes(Uint8List bytes, {String? mediaId}) async {
    if (_isDisposed) return;
    try {
      await _player.stop();
      if (_isDisposed) return;
      _currentlyPlayingId = mediaId;
      await _player.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('[ReminderAudioService] playBytes error: $e');
    }
  }

  Future<void> playUrl(String url, {String? mediaId}) async {
    if (_isDisposed) return;
    try {
      await _player.stop();
      if (_isDisposed) return;
      _currentlyPlayingId = mediaId;
      await _player.play(UrlSource(url));
    } catch (e) {
      debugPrint('[ReminderAudioService] playUrl error: $e');
    }
  }

  Future<void> pause() async {
    if (_isDisposed) return;
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (_isDisposed) return;
    try {
      await _player.resume();
    } catch (_) {}
  }

  Future<void> stop() async {
    if (_isDisposed) return;
    try {
      await _player.stop();
    } catch (_) {}
    _currentlyPlayingId = null;
    _currentPosition = Duration.zero;
  }

  Future<void> seek(Duration position) async {
    if (_isDisposed) return;
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('[ReminderAudioService] seek error: $e');
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _recordTimer?.cancel();
    _recordTimer = null;

    try {
      _playerStateSub?.cancel();
    } catch (_) {}
    _playerStateSub = null;

    try {
      _positionSub?.cancel();
    } catch (_) {}
    _positionSub = null;

    try {
      _durationSub?.cancel();
    } catch (_) {}
    _durationSub = null;

    try {
      _player.stop();
    } catch (_) {}

    try {
      _player.dispose();
    } catch (_) {}

    try {
      _recorder.dispose();
    } catch (_) {}

    if (!_playerStateController.isClosed) {
      try {
        _playerStateController.close();
      } catch (_) {}
    }
    if (!_positionController.isClosed) {
      try {
        _positionController.close();
      } catch (_) {}
    }
    if (!_durationController.isClosed) {
      try {
        _durationController.close();
      } catch (_) {}
    }
    if (!_recordSecondsController.isClosed) {
      try {
        _recordSecondsController.close();
      } catch (_) {}
    }
  }

  static int mathMax(int a, int b) => a > b ? a : b;
}


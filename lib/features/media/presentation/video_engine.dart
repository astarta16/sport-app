import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../domain/media_access.dart';

/// Snapshot of the player state the controls render.
@immutable
class VideoState {
  const VideoState({
    this.initialized = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.playing = false,
    this.buffering = false,
    this.hasError = false,
    this.aspectRatio = 16 / 9,
  });

  final bool initialized;
  final Duration position;
  final Duration duration;
  final bool playing;
  final bool buffering;
  final bool hasError;
  final double aspectRatio;

  /// Seeking is meaningful only once the metadata (duration) is known.
  bool get canSeek => initialized && duration > Duration.zero && !hasError;

  bool get completed => canSeek && position >= duration && !playing;
}

/// Thin seam over the platform player so widget tests can drive a fake.
abstract class VideoEngine extends ChangeNotifier {
  VideoState get state;
  Future<void> initialize();
  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);
  Widget view();
}

typedef VideoEngineFactory = VideoEngine Function(PlaybackSource source);

/// Overridden in tests with a fake engine.
final videoEngineFactoryProvider = Provider<VideoEngineFactory>((_) => VideoPlayerEngine.new);

/// video_player implementation. The URL is short-lived and private: it is
/// never logged and errors are reported without it.
class VideoPlayerEngine extends VideoEngine {
  VideoPlayerEngine(PlaybackSource source)
    : _c = source.assetPath != null
          ? VideoPlayerController.asset(source.assetPath!)
          : VideoPlayerController.networkUrl(Uri.parse(source.url!)) {
    _c.addListener(_onValue);
  }

  final VideoPlayerController _c;
  VideoState _state = const VideoState();
  bool _disposed = false;

  @override
  VideoState get state => _state;

  void _onValue() {
    final v = _c.value;
    _state = VideoState(
      initialized: v.isInitialized,
      position: v.position,
      duration: v.duration,
      playing: v.isPlaying,
      buffering: v.isBuffering,
      hasError: v.hasError,
      aspectRatio: v.isInitialized && v.aspectRatio > 0 ? v.aspectRatio : 16 / 9,
    );
    if (!_disposed) notifyListeners();
  }

  @override
  Future<void> initialize() async {
    await _c.initialize();
    _onValue();
  }

  @override
  Future<void> play() async {
    if (_state.completed) await _c.seekTo(Duration.zero);
    await _c.play();
  }

  @override
  Future<void> pause() => _c.pause();

  @override
  Future<void> seekTo(Duration position) => _c.seekTo(position);

  @override
  Widget view() => VideoPlayer(_c);

  @override
  void dispose() {
    _disposed = true;
    _c.removeListener(_onValue);
    _c.dispose();
    super.dispose();
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sport_parent_app/features/media/domain/media_access.dart';
import 'package:sport_parent_app/features/media/presentation/video_engine.dart';

/// Deterministic stand-in for the platform player (widget tests have no
/// video plugin). Records the sources it was created for.
class FakeVideoEngine extends VideoEngine {
  FakeVideoEngine(this.source) {
    created.add(this);
  }

  static final created = <FakeVideoEngine>[];

  /// Next initialize() fails (e.g. an expired URL) when true.
  static bool failNextInit = false;
  static Duration length = const Duration(seconds: 42);

  final PlaybackSource source;
  VideoState _s = const VideoState();
  bool disposed = false;
  final seeks = <Duration>[];

  @override
  VideoState get state => _s;

  void _set(VideoState s) {
    _s = s;
    if (!disposed) notifyListeners();
  }

  VideoState _copy({Duration? position, bool? playing, bool? buffering, bool? hasError}) => VideoState(
    initialized: _s.initialized,
    position: position ?? _s.position,
    duration: _s.duration,
    playing: playing ?? _s.playing,
    buffering: buffering ?? _s.buffering,
    hasError: hasError ?? _s.hasError,
    aspectRatio: _s.aspectRatio,
  );

  @override
  Future<void> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (failNextInit) {
      failNextInit = false;
      throw StateError('init failed');
    }
    _set(VideoState(initialized: true, duration: length));
  }

  /// Simulates the network stalling.
  void setBuffering(bool v) => _set(_copy(buffering: v));

  /// Simulates a runtime playback error.
  void fail() => _set(_copy(hasError: true, playing: false));

  @override
  Future<void> play() async => _set(_copy(playing: true));

  @override
  Future<void> pause() async => _set(_copy(playing: false));

  @override
  Future<void> seekTo(Duration position) async {
    if (!_s.initialized) throw StateError('seek before metadata');
    seeks.add(position);
    _set(_copy(position: position));
  }

  @override
  Widget view() => const ColoredBox(key: Key('fake-video-surface'), color: Colors.black);

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

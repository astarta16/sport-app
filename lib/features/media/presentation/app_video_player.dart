import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/media_access.dart';
import 'video_engine.dart';

String formatVideoTime(Duration d) {
  final s = d.inSeconds.clamp(0, 359999);
  final h = s ~/ 3600, m = (s % 3600) ~/ 60, sec = s % 60;
  String two(int n) => n.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '$m:${two(sec)}';
}

enum _Phase { loading, ready, error }

/// Video player with play/pause, ±10 s, an interactive progress bar, times,
/// fullscreen, loading/buffering states and retry. [resolve] asks the
/// backend for a (short-lived) source; it is called again on retry or when
/// the source has expired, so authorization is re-checked every time.
class AppVideoPlayer extends ConsumerStatefulWidget {
  const AppVideoPlayer({super.key, required this.resolve});

  final Future<PlaybackSource> Function() resolve;

  static const skip = Duration(seconds: 10);

  @override
  ConsumerState<AppVideoPlayer> createState() => _AppVideoPlayerState();
}

class _AppVideoPlayerState extends ConsumerState<AppVideoPlayer> with WidgetsBindingObserver {
  VideoEngine? _engine;
  PlaybackSource? _source;
  _Phase _phase = _Phase.loading;
  Duration _resumeAt = Duration.zero;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _engine?.removeListener(_onEngine);
    _engine?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Never keep playing in the background.
    if (state != AppLifecycleState.resumed && (_engine?.state.playing ?? false)) _engine?.pause();
  }

  Future<void> _load({bool refreshSource = true}) async {
    final gen = ++_generation;
    final old = _engine;
    if (old != null) {
      _resumeAt = old.state.position;
      old.removeListener(_onEngine);
      _engine = null;
      old.dispose();
    }
    setState(() => _phase = _Phase.loading);
    try {
      final now = ref.read(clockProvider)();
      var source = _source;
      if (refreshSource || source == null || source.isExpired(now)) source = await widget.resolve();
      if (!mounted || gen != _generation) return;
      _source = source;
      final engine = ref.read(videoEngineFactoryProvider)(source);
      await engine.initialize().timeout(const Duration(seconds: 30));
      if (!mounted || gen != _generation) {
        engine.dispose();
        return;
      }
      if (_resumeAt > Duration.zero && engine.state.canSeek) {
        await engine.seekTo(_resumeAt < engine.state.duration ? _resumeAt : Duration.zero);
      }
      engine.addListener(_onEngine);
      setState(() {
        _engine = engine;
        _phase = engine.state.hasError ? _Phase.error : _Phase.ready;
      });
    } catch (_) {
      // Deliberately not logged: the error may contain the private URL.
      if (mounted && gen == _generation) setState(() => _phase = _Phase.error);
    }
  }

  void _onEngine() {
    if (!mounted) return;
    final e = _engine;
    if (e != null && e.state.hasError) {
      setState(() => _phase = _Phase.error);
    } else {
      setState(() {});
    }
  }

  Future<void> _toggle() async {
    final e = _engine;
    if (e == null || !e.state.initialized) return;
    e.state.playing ? await e.pause() : await e.play();
  }

  Future<void> _seekBy(Duration delta) async {
    final e = _engine;
    if (e == null || !e.state.canSeek) return;
    await _seek(e.state.position + delta);
  }

  Future<void> _seek(Duration to) async {
    final e = _engine;
    if (e == null || !e.state.canSeek) return;
    final d = e.state.duration;
    await e.seekTo(to < Duration.zero ? Duration.zero : (to > d ? d : to));
  }

  /// A failed or expired authorization is refreshed before retrying.
  void _retry() => _load(refreshSource: true);

  Future<void> _fullscreen() async {
    final e = _engine;
    if (e == null) return;
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideo(
          engine: e,
          controls: (ctx) => _Controls(
            state: e.state,
            onToggle: _toggle,
            onSeekBy: _seekBy,
            onSeek: _seek,
            fullscreen: true,
            onFullscreen: () => Navigator.of(ctx).pop(),
          ),
        ),
      ),
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final e = _engine;
    final ratio = e?.state.aspectRatio ?? 16 / 9;
    return ClipRRect(
      key: const Key('video-player'),
      borderRadius: BorderRadius.circular(16),
      child: ColoredBox(
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: ratio.clamp(0.5, 2.4),
          child: switch (_phase) {
            _Phase.loading => _Overlay(
              key: const Key('video-loading'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.white),
                  const SizedBox(height: 8),
                  Text(l.videoLoading, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
            _Phase.error => _Overlay(
              key: const Key('video-error'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white, size: 40),
                  const SizedBox(height: 8),
                  Text(
                    l.videoError,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    key: const Key('video-retry'),
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l.retry),
                  ),
                ],
              ),
            ),
            _Phase.ready => Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(onTap: _toggle, child: e!.view()),
                if (e.state.buffering)
                  const Center(
                    key: Key('video-buffering'),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _Controls(
                    state: e.state,
                    onToggle: _toggle,
                    onSeekBy: _seekBy,
                    onSeek: _seek,
                    onFullscreen: _fullscreen,
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child),
  );
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.state,
    required this.onToggle,
    required this.onSeekBy,
    required this.onSeek,
    required this.onFullscreen,
    this.fullscreen = false,
  });

  final VideoState state;
  final VoidCallback onToggle;
  final void Function(Duration) onSeekBy;
  final void Function(Duration) onSeek;
  final VoidCallback onFullscreen;
  final bool fullscreen;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  /// While dragging, the thumb follows the finger; the seek happens on release.
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.state;
    final total = s.duration.inMilliseconds.toDouble();
    final pos = s.position.inMilliseconds.clamp(0, s.duration.inMilliseconds).toDouble();
    const white = Colors.white;
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xCC000000)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
              ),
              child: Semantics(
                label: l.videoPosition,
                child: Slider(
                  key: const Key('video-progress'),
                  value: _drag ?? (total > 0 ? pos : 0),
                  max: total > 0 ? total : 1,
                  activeColor: AppColors.volt,
                  inactiveColor: Colors.white38,
                  onChanged: s.canSeek ? (v) => setState(() => _drag = v) : null,
                  onChangeEnd: s.canSeek
                      ? (v) {
                          setState(() => _drag = null);
                          widget.onSeek(Duration(milliseconds: v.round()));
                        }
                      : null,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  key: const Key('video-play'),
                  tooltip: s.playing ? l.videoPause : l.videoPlay,
                  color: white,
                  onPressed: s.initialized ? widget.onToggle : null,
                  icon: Icon(s.playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                ),
                IconButton(
                  key: const Key('video-back'),
                  tooltip: l.videoBack10,
                  color: white,
                  onPressed: s.canSeek ? () => widget.onSeekBy(-AppVideoPlayer.skip) : null,
                  icon: const Icon(Icons.replay_10_rounded),
                ),
                IconButton(
                  key: const Key('video-forward'),
                  tooltip: l.videoForward10,
                  color: white,
                  onPressed: s.canSeek ? () => widget.onSeekBy(AppVideoPlayer.skip) : null,
                  icon: const Icon(Icons.forward_10_rounded),
                ),
                Expanded(
                  child: Text(
                    '${formatVideoTime(_drag == null ? s.position : Duration(milliseconds: _drag!.round()))} / '
                    '${formatVideoTime(s.duration)}',
                    key: const Key('video-time'),
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: const TextStyle(color: white, fontFeatures: [FontFeature.tabularFigures()]),
                  ),
                ),
                IconButton(
                  key: Key(widget.fullscreen ? 'video-exit-fullscreen' : 'video-fullscreen'),
                  tooltip: widget.fullscreen ? l.videoExitFullscreen : l.videoFullscreen,
                  color: white,
                  onPressed: widget.onFullscreen,
                  icon: Icon(widget.fullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fullscreen page sharing the same engine (no second download).
class _FullscreenVideo extends StatefulWidget {
  const _FullscreenVideo({required this.engine, required this.controls});

  final VideoEngine engine;
  final Widget Function(BuildContext) controls;

  @override
  State<_FullscreenVideo> createState() => _FullscreenVideoState();
}

class _FullscreenVideoState extends State<_FullscreenVideo> {
  @override
  void initState() {
    super.initState();
    widget.engine.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.engine.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.engine.state;
    return Scaffold(
      key: const Key('video-fullscreen-page'),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(aspectRatio: s.aspectRatio.clamp(0.5, 2.4), child: widget.engine.view()),
            ),
            if (s.buffering) const Center(child: CircularProgressIndicator(color: Colors.white)),
            Align(alignment: Alignment.bottomCenter, child: widget.controls(context)),
          ],
        ),
      ),
    );
  }
}

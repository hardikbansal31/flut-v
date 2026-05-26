import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/features/library/library_providers.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:window_manager/window_manager.dart';


/// Fullscreen player screen using media_kit and window_manager.
class PlayerScreen extends ConsumerStatefulWidget {
  final MediaFile mediaFile;

  const PlayerScreen({super.key, required this.mediaFile});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final Player player = Player(
    configuration: const PlayerConfiguration(
      // Use libass for native subtitle rendering so that ASS/SSA styles
      // embedded in the video file (e.g. anime fansubs) are preserved.
      libass: true,
    ),
  );
  late final VideoController controller = VideoController(
    player,
    configuration: const VideoControllerConfiguration(
      enableHardwareAcceleration: true,
    ),
  );

  StreamSubscription? _positionSub;
  StreamSubscription? _durationSub;
  StreamSubscription? _playingSub;

  int _currentPosition = 0;
  int _maxValidPosition = 0;
  int _currentDuration = 0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _initPlayer();
    _enterFullscreen();
  }

  Future<void> _initPlayer() async {
    final initialPosition = widget.mediaFile.positionMillis ?? 0;

    // ── Subtitle configuration (mpv properties via NativePlayer) ──
    // • sub-ass-override=no  → honour styles baked into ASS/SSA tracks.
    // • The sub-font / sub-border-size / sub-margin-y values are the
    //   fallback style used when a track has NO embedded styling (e.g.
    //   plain SRT).  They do NOT override ASS styles.
    if (player.platform is NativePlayer) {
      final native = player.platform as NativePlayer;
      await native.setProperty('sub-ass-override', 'no');

      // Fallback style for unstyled subs (SRT, VTT, etc.)
      await native.setProperty('sub-font', 'Arial');
      await native.setProperty('sub-font-size', '48');
      await native.setProperty('sub-color', '#FFFFFFFF');
      await native.setProperty('sub-border-size', '4');
      await native.setProperty('sub-border-color', '#FF000000');
      await native.setProperty('sub-shadow-offset', '0');
      await native.setProperty('sub-margin-y', '22');
    }

    _durationSub = player.stream.duration.listen((duration) {
      _currentDuration = duration.inMilliseconds;
    });

    _positionSub = player.stream.position.listen((position) {
      _currentPosition = position.inMilliseconds;
      if (_currentPosition > 0 && _currentPosition > _maxValidPosition) {
        _maxValidPosition = _currentPosition;
      }
    });

    // Event-driven save on pause
    _playingSub = player.stream.playing.listen((isPlaying) {
      if (!isPlaying) _saveWatchProgress();
      _isPlaying = isPlaying;
    });

    await player.open(Media(widget.mediaFile.filePath), play: false);

    // Wait for the media to become seekable before resuming position.
    // player.open() resolves before mpv finishes demuxing, so an
    // immediate seek is silently dropped.  Waiting for a non-zero
    // duration guarantees the file is loaded and seekable.
    if (initialPosition > 0) {
      await player.stream.duration.firstWhere((d) => d > Duration.zero);
      await player.seek(Duration(milliseconds: initialPosition));
    }

    await player.play();
  }

  Future<void> _enterFullscreen() async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await windowManager.setFullScreen(true);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }


  Future<void> _showSubtitleDialog() async {
    final tracks = player.state.tracks.subtitle;
    final currentTrack = player.state.track.subtitle;

    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      await player.pause();
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Subtitles'),
          backgroundColor: Colors.grey[900],
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: tracks.map((track) {
                final isSelected = track == currentTrack;
                final trackName = track.id == 'no' 
                    ? 'None' 
                    : (track.title ?? track.language ?? track.id);
                
                return ListTile(
                  title: Text(
                    trackName,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                  onTap: () {
                    player.setSubtitleTrack(track);
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );

    if (wasPlaying) {
      await player.play();
    }
  }

  Future<void> _saveWatchProgress() async {
    // If stream emitted 0 right before closing, use the highest cached position
    final positionToSave = _currentPosition > 0 ? _currentPosition : _maxValidPosition;
    if (positionToSave > 0 && _currentDuration > 0) {
      final db = ref.read(databaseProvider);
      await db.updateWatchProgress(widget.mediaFile.id, positionToSave, _currentDuration);
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();
    
    WindowManager.instance.setFullScreen(false); // always exit fullscreen on dispose
    player.dispose(); // full dispose, not pause or stop
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveWatchProgress();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: MaterialDesktopVideoControlsTheme(
        normal: MaterialDesktopVideoControlsThemeData(
          topButtonBar: [
            const BackButton(color: Colors.white),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.subtitles, color: Colors.white),
              onPressed: _showSubtitleDialog,
            ),
          ],
        ),
        fullscreen: MaterialDesktopVideoControlsThemeData(
          topButtonBar: [
            const BackButton(color: Colors.white),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.subtitles, color: Colors.white),
              onPressed: _showSubtitleDialog,
            ),
          ],
        ),
        child: MaterialVideoControlsTheme(
          normal: MaterialVideoControlsThemeData(
            topButtonBar: [
              const BackButton(color: Colors.white),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.subtitles, color: Colors.white),
                onPressed: _showSubtitleDialog,
              ),
            ],
          ),
          fullscreen: MaterialVideoControlsThemeData(
            topButtonBar: [
              const BackButton(color: Colors.white),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.subtitles, color: Colors.white),
                onPressed: _showSubtitleDialog,
              ),
            ],
          ),
          child: Video(
            controller: controller,
            // Flutter-side fallback style — only applies when libass is
            // NOT handling rendering (rare).  Matches the mpv fallback:
            // Arial, 3 pt uniform border, positioned near the bottom.
            subtitleViewConfiguration: SubtitleViewConfiguration(
              style: TextStyle(
                height: 1.4,
                fontSize: 48.0,
                fontFamily: 'Arial',
                letterSpacing: 0.0,
                wordSpacing: 0.0,
                color: Colors.white,
                fontWeight: FontWeight.normal,
                backgroundColor: Colors.transparent,
                shadows: [
                  // Simulates a uniform 4 px border with 8-directional shadows.
                  Shadow(offset: Offset(4.0, 0.0), blurRadius: 0.0, color: Colors.black),
                  Shadow(offset: Offset(-4.0, 0.0), blurRadius: 0.0, color: Colors.black),
                  Shadow(offset: Offset(0.0, 4.0), blurRadius: 0.0, color: Colors.black),
                  Shadow(offset: Offset(0.0, -4.0), blurRadius: 0.0, color: Colors.black),
                  Shadow(offset: Offset(2.8, 2.8), blurRadius: 0.0, color: Colors.black),
                  Shadow(offset: Offset(-2.8, 2.8), blurRadius: 0.0, color: Colors.black),
                  Shadow(offset: Offset(2.8, -2.8), blurRadius: 0.0, color: Colors.black),
                  Shadow(offset: Offset(-2.8, -2.8), blurRadius: 0.0, color: Colors.black),
                ],
              ),
              padding: const EdgeInsets.only(bottom: 22.0),
            ),
          ),
        ),
      ),
    ));
  }
}

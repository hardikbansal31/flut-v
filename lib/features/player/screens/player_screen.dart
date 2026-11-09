import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_video/core/database/database.dart';
import 'package:flutter_video/core/save_state_provider.dart';
import 'package:flutter_video/core/theme/app_theme.dart';
import 'package:flutter_video/features/browse/models/series_item.dart';
import 'package:flutter_video/features/library/library_providers.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
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
  Timer? _periodicSaveTimer;

  int _currentPosition = 0;
  int _maxValidPosition = 0;
  int _currentDuration = 0;
  int _lastSavedPosition = -1;
  bool _isPlaying = true;
  bool _isDisposed = false;
  bool _hasInitError = false;
  String? _errorMessage;

  late final AppDatabase _db;
  late final SaveStateNotifier _saveStateNotifier;

  @override
  void initState() {
    super.initState();
    _db = ref.read(databaseProvider);
    _saveStateNotifier = ref.read(saveStateProvider.notifier);
    _initPlayer();
    _enterFullscreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveStateNotifier.setCallback(_saveWatchProgress);
    });

    // Periodically save progress every ~10 seconds while playing
    _periodicSaveTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isPlaying && !_isDisposed) {
        _saveWatchProgress();
      }
    });
  }

  Future<void> _initPlayer() async {
    try {
      // Guard: verify the file still exists on disk
      final file = File(widget.mediaFile.filePath);
      if (!await file.exists()) {
        if (!mounted || _isDisposed) return;
        await _db.removeMediaFileByPath(widget.mediaFile.filePath);
        if (!mounted || _isDisposed) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File not found: ${widget.mediaFile.fileName}'),
            backgroundColor: AppTheme.errorSnackbar,
          ),
        );
        Navigator.of(context).pop();
        return;
      }
      if (!mounted || _isDisposed) return;

      final initialPosition = widget.mediaFile.positionMillis ?? 0;

      // Subtitle configuration (mpv properties via NativePlayer)
      if (player.platform is NativePlayer) {
        final native = player.platform as NativePlayer;
        await native.setProperty('sub-ass-override', 'no');
        if (!mounted || _isDisposed) return;

        // Fallback style for unstyled subs (SRT, VTT, etc.)
        await native.setProperty('sub-font', 'Arial');
        await native.setProperty('sub-font-size', '48');
        await native.setProperty('sub-color', '#FFFFFFFF');
        await native.setProperty('sub-border-size', '4');
        await native.setProperty('sub-border-color', '#FF000000');
        await native.setProperty('sub-shadow-offset', '0');
        await native.setProperty('sub-margin-y', '22');
        if (!mounted || _isDisposed) return;
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
      if (!mounted || _isDisposed) return;

      if (initialPosition > 0) {
        try {
          await player.stream.duration
              .firstWhere((d) => d > Duration.zero)
              .timeout(const Duration(seconds: 10));
          if (!mounted || _isDisposed) return;
          await player.seek(Duration(milliseconds: initialPosition));
        } catch (e) {
          developer.log(
            'Could not resume initial position: $e',
            name: 'PlayerScreen',
          );
        }
      }
      if (!mounted || _isDisposed) return;

      await player.play();
      if (!mounted || _isDisposed) return;

      await controller.waitUntilFirstFrameRendered;
      if (!mounted || _isDisposed) return;

      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final physicalSize = view.physicalSize;
      if (physicalSize.width > 0 && physicalSize.height > 0) {
        await controller.setSize(
          width: physicalSize.width.round(),
          height: physicalSize.height.round(),
        );
      }
    } catch (e, stack) {
      developer.log(
        'Player initialization error: $e',
        name: 'PlayerScreen',
        error: e,
        stackTrace: stack,
        level: 900,
      );
      if (mounted && !_isDisposed) {
        setState(() {
          _hasInitError = true;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Playback failed: $e'),
            backgroundColor: AppTheme.errorSnackbar,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
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
          backgroundColor: AppTheme.subtitlesDialogBackground,
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(PhosphorIcons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
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

  Future<void> _showAudioDialog() async {
    final tracks = player.state.tracks.audio;
    final currentTrack = player.state.track.audio;

    final wasPlaying = _isPlaying;
    if (wasPlaying) {
      await player.pause();
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Audio'),
          backgroundColor: AppTheme.subtitlesDialogBackground,
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
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : AppTheme.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(PhosphorIcons.check,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    player.setAudioTrack(track);
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

  Future<void> _handleEscape() async {
    final nav = Navigator.of(context);
    final isFullscreen = await windowManager.isFullScreen();
    if (isFullscreen) {
      await windowManager.setFullScreen(false);
    }
    if (mounted) nav.maybePop();
  }

  /// Saves watch progress to SQLite. Throttled so repeated calls with the same
  /// position do not trigger redundant database writes.
  Future<void> _saveWatchProgress({bool force = false}) async {
    final positionToSave =
        _currentPosition > 0 ? _currentPosition : _maxValidPosition;
    if (positionToSave <= 0 || _currentDuration <= 0) return;
    if (!force && positionToSave == _lastSavedPosition) return;

    _lastSavedPosition = positionToSave;
    try {
      await _db.updateWatchProgress(
        widget.mediaFile.id,
        positionToSave,
        _currentDuration,
      );
    } catch (e) {
      developer.log(
        'Failed to save watch progress: $e',
        name: 'PlayerScreen',
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _periodicSaveTimer?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveStateNotifier.setCallback(null);
    });

    _positionSub?.cancel();
    _durationSub?.cancel();
    _playingSub?.cancel();

    WindowManager.instance.setFullScreen(false);
    player.dispose();
    super.dispose();
  }

  Widget _buildTitle() {
    final file = widget.mediaFile;

    final showName = SeriesItem.seriesTitleFor(file);
    final epLabel = SeriesItem.episodeLabelFor(file);
    final epName = SeriesItem.episodeNameFor(file);

    if (epLabel != null) {
      final subTitle = [epLabel, epName]
          .where((e) => e != null && e.isNotEmpty)
          .join(' - ');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            showName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subTitle.isNotEmpty)
            Text(
              subTitle,
              style: TextStyle(
                color: AppTheme.textPrimary.withAlpha(179),
                fontSize: 13,
              ),
            ),
        ],
      );
    }

    return Text(
      file.tmdbTitle ?? file.fileName,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasInitError) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: AppTheme.transparent,
          leading: const BackButton(color: AppTheme.textPrimary),
          title: Text(widget.mediaFile.fileName),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(PhosphorIcons.warningCircle,
                    size: 48, color: AppTheme.errorSnackbar),
                const SizedBox(height: 16),
                const Text(
                  'Failed to play video',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppTheme.textPrimary.withAlpha(179),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(PhosphorIcons.arrowLeft),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor,
                    foregroundColor: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final nav = Navigator.of(context);
        await _saveWatchProgress(force: true);
        if (mounted) nav.pop();
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            final key = event.logicalKey;

            // Discrete actions on initial key press only
            if (event is KeyDownEvent) {
              if (key == LogicalKeyboardKey.keyP ||
                  key == LogicalKeyboardKey.space) {
                player.playOrPause();
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.keyM) {
                player.setVolume(player.state.volume == 0 ? 100.0 : 0.0);
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.keyC) {
                final tracks = player.state.tracks.subtitle;
                final current = player.state.track.subtitle;
                if (tracks.length > 1) {
                  final currentIndex = tracks.indexOf(current);
                  final nextIndex = (currentIndex + 1) % tracks.length;
                  player.setSubtitleTrack(tracks[nextIndex]);
                }
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.keyF) {
                windowManager.isFullScreen().then((isFullscreen) {
                  windowManager.setFullScreen(!isFullscreen);
                });
                return KeyEventResult.handled;
              } else if (key == LogicalKeyboardKey.escape) {
                _handleEscape();
                return KeyEventResult.handled;
              }

              // Number keys 0-9 for seeking
              final label = key.keyLabel;
              if (label.length == 1) {
                final digit = int.tryParse(label);
                if (digit != null) {
                  final pos = player.state.duration * (digit / 10.0);
                  player.seek(pos);
                  return KeyEventResult.handled;
                }
              }
            }

            // Continuous actions on both KeyDownEvent and KeyRepeatEvent
            if (key == LogicalKeyboardKey.arrowLeft) {
              final pos = player.state.position - const Duration(seconds: 10);
              player.seek(pos < Duration.zero ? Duration.zero : pos);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowRight) {
              final pos = player.state.position + const Duration(seconds: 10);
              player.seek(
                pos > player.state.duration ? player.state.duration : pos,
              );
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowUp) {
              final vol = (player.state.volume + 10.0).clamp(0.0, 100.0);
              player.setVolume(vol);
              return KeyEventResult.handled;
            } else if (key == LogicalKeyboardKey.arrowDown) {
              final vol = (player.state.volume - 10.0).clamp(0.0, 100.0);
              player.setVolume(vol);
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Scaffold(
          backgroundColor: AppTheme.backgroundBlack,
          body: MaterialDesktopVideoControlsTheme(
            normal: MaterialDesktopVideoControlsThemeData(
              hideMouseOnControlsRemoval: true,
              topButtonBar: [
                const BackButton(color: AppTheme.textPrimary),
                const SizedBox(width: 8),
                _buildTitle(),
                const Spacer(),
                IconButton(
                  icon: Icon(PhosphorIcons.speakerHigh,
                      color: AppTheme.textPrimary),
                  onPressed: _showAudioDialog,
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.subtitles,
                      color: AppTheme.textPrimary),
                  onPressed: _showSubtitleDialog,
                ),
              ],
            ),
            fullscreen: MaterialDesktopVideoControlsThemeData(
              hideMouseOnControlsRemoval: true,
              topButtonBar: [
                const BackButton(color: AppTheme.textPrimary),
                const SizedBox(width: 8),
                _buildTitle(),
                const Spacer(),
                IconButton(
                  icon: Icon(PhosphorIcons.speakerHigh,
                      color: AppTheme.textPrimary),
                  onPressed: _showAudioDialog,
                ),
                IconButton(
                  icon: Icon(PhosphorIcons.subtitles,
                      color: AppTheme.textPrimary),
                  onPressed: _showSubtitleDialog,
                ),
              ],
            ),
            child: MaterialVideoControlsTheme(
              normal: MaterialVideoControlsThemeData(
                topButtonBar: [
                  const BackButton(color: AppTheme.textPrimary),
                  const SizedBox(width: 8),
                  _buildTitle(),
                  const Spacer(),
                  IconButton(
                    icon: Icon(PhosphorIcons.speakerHigh,
                        color: AppTheme.textPrimary),
                    onPressed: _showAudioDialog,
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.subtitles,
                        color: AppTheme.textPrimary),
                    onPressed: _showSubtitleDialog,
                  ),
                ],
              ),
              fullscreen: MaterialVideoControlsThemeData(
                topButtonBar: [
                  const BackButton(color: AppTheme.textPrimary),
                  const SizedBox(width: 8),
                  _buildTitle(),
                  const Spacer(),
                  IconButton(
                    icon: Icon(PhosphorIcons.speakerHigh,
                        color: AppTheme.textPrimary),
                    onPressed: _showAudioDialog,
                  ),
                  IconButton(
                    icon: Icon(PhosphorIcons.subtitles,
                        color: AppTheme.textPrimary),
                    onPressed: _showSubtitleDialog,
                  ),
                ],
              ),
              child: Video(
                controller: controller,
                filterQuality: FilterQuality.high,
                subtitleViewConfiguration: SubtitleViewConfiguration(
                  style: TextStyle(
                    height: 1.4,
                    fontSize: 48.0,
                    fontFamily: 'Arial',
                    letterSpacing: 0.0,
                    wordSpacing: 0.0,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.normal,
                    backgroundColor: AppTheme.transparent,
                    shadows: [
                      Shadow(
                          offset: const Offset(4.0, 0.0),
                          blurRadius: 0.0,
                          color: AppTheme.backgroundBlack),
                      Shadow(
                          offset: const Offset(-4.0, 0.0),
                          blurRadius: 0.0,
                          color: AppTheme.backgroundBlack),
                      Shadow(
                          offset: const Offset(0.0, 4.0),
                          blurRadius: 0.0,
                          color: AppTheme.backgroundBlack),
                      Shadow(
                          offset: const Offset(0.0, -4.0),
                          blurRadius: 0.0,
                          color: AppTheme.backgroundBlack),
                      Shadow(
                          offset: const Offset(2.8, 2.8),
                          blurRadius: 0.0,
                          color: AppTheme.backgroundBlack),
                      Shadow(
                          offset: const Offset(-2.8, 2.8),
                          blurRadius: 0.0,
                          color: AppTheme.backgroundBlack),
                      Shadow(
                          offset: const Offset(2.8, -2.8),
                          blurRadius: 0.0,
                          color: AppTheme.backgroundBlack),
                      Shadow(
                          offset: const Offset(-2.8, -2.8),
                          blurRadius: 0.0,
                          color: AppTheme.backgroundBlack),
                    ],
                  ),
                  padding: const EdgeInsets.only(bottom: 22.0),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

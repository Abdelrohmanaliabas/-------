import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../domain/models/song.dart';
import 'download_service.dart';
import 'full_audio_resolver.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  List<Song> _queue = [];
  int _currentIndex = -1;

  final _currentSongController = StreamController<Song?>.broadcast();
  final _queueController = StreamController<List<Song>>.broadcast();

  AudioPlayerService() {
    _initAudioSession();
    _initSubscriptions();
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.5);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              _player.pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              _player.play();
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });
      session.becomingNoisyEventStream.listen((_) {
        _player.pause();
      });
    } catch (e) {
      debugPrint('AudioSession init error: $e');
    }
  }

  AudioPlayer get player => _player;
  List<Song> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  Song? get currentSong =>
      (_currentIndex >= 0 && _currentIndex < _queue.length) ? _queue[_currentIndex] : null;

  Stream<Song?> get currentSongStream => _currentSongController.stream;
  Stream<List<Song>> get queueStream => _queueController.stream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;

  void _initSubscriptions() {
    _player.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < _queue.length) {
        _currentIndex = index;
        _currentSongController.add(_queue[index]);
      }
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        // Just_audio handles loop/next according to playlist source
      }
    });
  }

  Future<AudioSource> _createAudioSource(Song song) async {
    // 1. Check if song already has localFilePath specified and file exists
    if (song.localFilePath != null && File(song.localFilePath!).existsSync()) {
      return AudioSource.uri(
        Uri.file(song.localFilePath!),
        tag: _buildMediaItem(song),
      );
    }

    // 2. Check if cached in offline folder
    try {
      final offlinePath = await DownloadService.getExpectedOfflinePath(song.id);
      if (File(offlinePath).existsSync()) {
        return AudioSource.uri(
          Uri.file(offlinePath),
          tag: _buildMediaItem(song),
        );
      }
    } catch (_) {}

    // 3. Resolve Full Audio Stream (for 100% complete song duration)
    var finalAudioUrl = song.audioUrl;
    var finalDuration = song.duration;

    if (song.duration.inSeconds <= 45 ||
        song.audioUrl.contains('preview') ||
        song.audioUrl.contains('soundhelix') ||
        song.audioUrl.contains('youtube.com')) {
      try {
        final resolved = await FullAudioResolver.resolveFullAudioStream(song.title, song.artist);
        if (resolved != null) {
          finalAudioUrl = resolved.url;
          finalDuration = resolved.duration;
        }
      } catch (e) {
        debugPrint('Could not resolve full audio stream: $e');
      }
    }

    final enrichedSong = song.copyWith(
      audioUrl: finalAudioUrl,
      duration: finalDuration,
    );

    // Update queue element if present so player slider & UI gets real full duration
    final qIndex = _queue.indexWhere((s) => s.id == song.id);
    if (qIndex != -1) {
      _queue[qIndex] = enrichedSong;
      if (_currentIndex == qIndex) {
        _currentSongController.add(enrichedSong);
      }
    }

    return AudioSource.uri(
      Uri.parse(finalAudioUrl),
      tag: _buildMediaItem(enrichedSong),
    );
  }

  MediaItem _buildMediaItem(Song song) {
    return MediaItem(
      id: song.id,
      album: song.album,
      title: song.title,
      artist: song.artist,
      artUri: Uri.tryParse(song.artworkUrl),
      duration: song.duration,
      playable: true,
      displayTitle: song.title,
      displaySubtitle: song.artist,
      displayDescription: song.album,
    );
  }

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    final list = (playlist != null && playlist.isNotEmpty) ? playlist : [song];
    final index = list.indexWhere((s) => s.id == song.id);
    await playPlaylist(list, initialIndex: index >= 0 ? index : 0);
  }

  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    _queue = List.from(songs);
    _currentIndex = (initialIndex >= 0 && initialIndex < songs.length) ? initialIndex : 0;
    _queueController.add(_queue);
    _currentSongController.add(_queue[_currentIndex]);

    try {
      final audioSources = await Future.wait(_queue.map(_createAudioSource));
      await _player.setAudioSources(
        audioSources,
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );
      await _player.play();
    } catch (e) {
      debugPrint('Error loading audio: $e');
      rethrow;
    }
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> playOrPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_queue.isNotEmpty && _currentIndex < _queue.length - 1) {
      _currentIndex++;
      _currentSongController.add(_queue[_currentIndex]);
      await _player.seek(Duration.zero, index: _currentIndex);
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }

    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_queue.isNotEmpty && _currentIndex > 0) {
      _currentIndex--;
      _currentSongController.add(_queue[_currentIndex]);
      await _player.seek(Duration.zero, index: _currentIndex);
    }
  }

  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      _currentSongController.add(_queue[_currentIndex]);
      await _player.seek(Duration.zero, index: index);
      if (!_player.playing) {
        await _player.play();
      }
    }
  }

  Future<void> toggleShuffle() async {
    final enable = !_player.shuffleModeEnabled;
    if (enable) {
      await _player.shuffle();
    }
    await _player.setShuffleModeEnabled(enable);
  }

  Future<void> toggleLoopMode() async {
    final current = _player.loopMode;
    LoopMode next;
    switch (current) {
      case LoopMode.off:
        next = LoopMode.all;
        break;
      case LoopMode.all:
        next = LoopMode.one;
        break;
      case LoopMode.one:
        next = LoopMode.off;
        break;
    }
    await _player.setLoopMode(next);
  }

  void addToQueue(Song song) {
    _queue.add(song);
    _queueController.add(_queue);
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (_currentIndex >= _queue.length) {
        _currentIndex = _queue.length - 1;
      }
      _queueController.add(_queue);
      if (_currentIndex >= 0 && _currentIndex < _queue.length) {
        _currentSongController.add(_queue[_currentIndex]);
      } else {
        _currentSongController.add(null);
      }
    }
  }

  Future<void> stop() async {
    await _player.stop();
    _currentSongController.add(null);
  }

  Future<void> dispose() async {
    await _player.dispose();
    await _currentSongController.close();
    await _queueController.close();
  }
}

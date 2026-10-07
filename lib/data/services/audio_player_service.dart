import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import '../../domain/models/song.dart';
import '../mock/sample_music_data.dart';
import 'audio_streaming_proxy.dart';
import 'download_service.dart';
import 'listening_history_service.dart';
import 'song_audio_resolver.dart';

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
      if (index != null && index >= 0 && index < _queue.length && index != _currentIndex) {
        _currentIndex = index;
        final current = _queue[index];
        _currentSongController.add(current);
        ListeningHistoryService.recordSongPlayed(current);
        _preloadNextSong();
      }
    });

    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_currentIndex >= 0 && _currentIndex < _queue.length) {
          ListeningHistoryService.recordSongCompleted(_queue[_currentIndex]);
        }
        if (_player.loopMode == LoopMode.one) {
          _player.seek(Duration.zero);
          _player.play();
        } else if (_player.hasNext) {
          skipToNext();
        } else if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
          skipToIndex(0);
        }
      }
    });

    _player.positionStream.listen((pos) {
      final dur = _player.duration;
      if (dur != null && dur.inSeconds > 30 && pos.inSeconds >= (dur.inSeconds * 0.70)) {
        if (_currentIndex >= 0 && _currentIndex < _queue.length) {
          ListeningHistoryService.recordSongCompleted(_queue[_currentIndex]);
        }
      }
    });
  }

  Future<AudioSource> _createAudioSource(Song song, {bool isFallback = false}) async {
    // 1. Check if song has an existing offline file on device (favorites/downloads)
    final offlinePath = await DownloadService.findOfflinePathForSong(song);
    if (offlinePath != null && File(offlinePath).existsSync()) {
      debugPrint('⚡ Playing local offline file: $offlinePath');
      final localSong = song.copyWith(
        localFilePath: offlinePath,
        isDownloaded: true,
      );
      return AudioSource.uri(
        Uri.file(offlinePath),
        tag: _buildMediaItem(localSong),
      );
    }

    if (isFallback) {
      SongAudioResolver.clearCache(song);
    }

    // 2. Resolve audio info (videoId, url, duration) via YouTube
    final resolvedAudio = await SongAudioResolver.resolveAudio(
      song,
      forceFresh: isFallback,
      isFallback: isFallback,
    );
    final enrichedSong = song.copyWith(
      audioUrl: resolvedAudio.url,
      duration: (resolvedAudio.duration != null && resolvedAudio.duration!.inSeconds > 0)
          ? resolvedAudio.duration!
          : song.duration,
    );

    // Update queue element so UI slider & mini-player reflect real duration
    final qIndex = (_currentIndex >= 0 && _currentIndex < _queue.length && _queue[_currentIndex].id == song.id)
        ? _currentIndex
        : _queue.indexWhere((s) => s.id == song.id);
    if (qIndex != -1) {
      _queue[qIndex] = enrichedSong;
      if (_currentIndex == qIndex) {
        _currentSongController.add(enrichedSong);
      }
    }

    // 3. Direct Full Stream / CDN (SoundCloud full MP3, Archive, Apple CDN, Deezer, etc.)
    // Plays instantly without proxy, without YouTube, and without 403 Forbidden!
    if (resolvedAudio.url.isNotEmpty &&
        (resolvedAudio.source == 'soundcloud_full' ||
            resolvedAudio.source == 'direct_full' ||
            resolvedAudio.source == 'direct_cdn' ||
            resolvedAudio.source == 'itunes_cdn' ||
            resolvedAudio.source == 'direct_url' ||
            resolvedAudio.videoId == null)) {
      debugPrint('▶️ Playing direct stream URL for "${song.title}": ${resolvedAudio.url}');
      return AudioSource.uri(
        Uri.parse(resolvedAudio.url),
        tag: _buildMediaItem(enrichedSong),
      );
    }

    // 4. Determine the YouTube video ID to route through local proxy.
    //    Priority: videoId from resolver → yt_ song id prefix → direct url fallback
    String? ytVideoIdStr;
    if (resolvedAudio.videoId != null) {
      ytVideoIdStr = resolvedAudio.videoId!.value;
    } else if (song.id.startsWith('yt_')) {
      ytVideoIdStr = song.id.substring(3);
    }

    String playbackUrl;
    if (ytVideoIdStr != null && ytVideoIdStr.isNotEmpty) {
      // Start proxy server if not already running
      await AudioStreamingProxy.ensureStarted();

      // PRE-LOAD the stream manifest into the proxy cache BEFORE ExoPlayer connects.
      bool preloaded = await AudioStreamingProxy.preloadStream(ytVideoIdStr);
      if (!preloaded && !isFallback) {
        debugPrint('⚠️ Preload failed for $ytVideoIdStr; attempting fresh fallback search for "${song.title}"…');
        try {
          final fallbackAudio = await SongAudioResolver.resolveAudio(
            song,
            forceFresh: true,
            isFallback: true,
          );
          if (fallbackAudio.url.isNotEmpty &&
              (fallbackAudio.source == 'soundcloud_full' ||
                  fallbackAudio.source == 'direct_full' ||
                  fallbackAudio.source == 'direct_cdn' ||
                  fallbackAudio.source == 'itunes_cdn')) {
            return AudioSource.uri(
              Uri.parse(fallbackAudio.url),
              tag: _buildMediaItem(enrichedSong),
            );
          }
          if (fallbackAudio.videoId != null) {
            ytVideoIdStr = fallbackAudio.videoId!.value;
            preloaded = await AudioStreamingProxy.preloadStream(ytVideoIdStr);
          }
        } catch (e) {
          debugPrint('Fallback search error: $e');
        }
      }

      if (preloaded && ytVideoIdStr != null) {
        playbackUrl = AudioStreamingProxy.getStreamUrl(ytVideoIdStr);
        debugPrint('🔀 Routing "${song.title}" via proxy (videoId: $ytVideoIdStr)');
      } else if (song.audioUrl.isNotEmpty &&
          (song.audioUrl.startsWith('http://') || song.audioUrl.startsWith('https://'))) {
        playbackUrl = song.audioUrl;
        debugPrint('▶️ Proxy preload failed; falling back to direct song.audioUrl for "${song.title}"');
      } else {
        throw Exception('تعذّر تحميل بيانات البث لـ "${song.title}"');
      }
    } else {
      playbackUrl = resolvedAudio.url;
      debugPrint('▶️ Playing direct URL for "${song.title}": $playbackUrl');
    }

    return AudioSource.uri(
      Uri.parse(playbackUrl),
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

  Future<void> _loadAndPlayCurrentSong() async {
    if (_currentIndex < 0 || _currentIndex >= _queue.length) return;
    final song = _queue[_currentIndex];
    _currentSongController.add(song);
    ListeningHistoryService.recordSongPlayed(song);

    try {
      final source = await _createAudioSource(song, isFallback: false);
      await _player.setAudioSource(source, initialPosition: Duration.zero);
      await _player.play();

      // Preload next track quietly in background so next click is instant
      _preloadNextSong();
    } catch (e) {
      if (e.toString().contains('interrupted') || e.toString().contains('abort')) {
        debugPrint('Playback loading superseded by new track request.');
        return;
      }
      debugPrint('Playback error for "${song.title}": $e — attempting fallback resolve…');
      SongAudioResolver.clearCache(song);
      if (song.id.startsWith('yt_')) {
        AudioStreamingProxy.evictCache(song.id.substring(3));
      }
      try {
        final fallbackSource = await _createAudioSource(song, isFallback: true);
        await _player.setAudioSource(fallbackSource, initialPosition: Duration.zero);
        await _player.play();
        _preloadNextSong();
      } catch (fallbackErr) {
        if (fallbackErr.toString().contains('interrupted') ||
            fallbackErr.toString().contains('abort')) {
          return;
        }
        debugPrint('Fallback also failed for "${song.title}": $fallbackErr');
      }
    }
  }

  void _preloadNextSong() {
    if (_currentIndex + 1 < _queue.length) {
      final nextSong = _queue[_currentIndex + 1];
      // Resolve audio metadata AND pre-load the proxy stream in background
      // so the next track starts instantly when the user skips
      unawaited(SongAudioResolver.resolveAudio(nextSong).then((info) {
        final videoId = info.videoId?.value ??
            (nextSong.id.startsWith('yt_') ? nextSong.id.substring(3) : null);
        if (videoId != null && videoId.isNotEmpty) {
          AudioStreamingProxy.ensureStarted().then((_) {
            AudioStreamingProxy.preloadStream(videoId);
          });
        }
      }, onError: (_) {}));
    }
  }

  Future<void> playSong(Song song, {List<Song>? playlist}) async {
    List<Song> list;
    if (playlist != null && playlist.isNotEmpty) {
      list = List.from(playlist);
    } else {
      final sampleRemaining = SampleMusicData.songs.where((s) => s.id != song.id).toList();
      list = [song, ...sampleRemaining];
    }
    int index = list.indexWhere((s) => s.id == song.id);
    if (index == -1) {
      index = list.indexWhere((s) =>
          s.title.trim().toLowerCase() == song.title.trim().toLowerCase());
    }
    await playPlaylist(list, initialIndex: index >= 0 ? index : 0);
  }

  Future<void> playPlaylist(List<Song> songs, {int initialIndex = 0}) async {
    if (songs.isEmpty) return;

    await AudioStreamingProxy.ensureStarted();
    AudioStreamingProxy.registerSongs(songs);

    _queue = List.from(songs);
    _currentIndex = (initialIndex >= 0 && initialIndex < songs.length) ? initialIndex : 0;
    _queueController.add(_queue);

    final currentSong = _queue[_currentIndex];
    _currentSongController.add(currentSong);
    ListeningHistoryService.recordSongPlayed(currentSong);

    // Preload current song stream so it starts instantly
    unawaited(AudioStreamingProxy.preloadSong(currentSong));

    final sources = _queue.map((s) {
      return AudioSource.uri(
        Uri.parse(AudioStreamingProxy.getSongStreamUrl(s)),
        tag: _buildMediaItem(s),
      );
    }).toList();

    try {
      await _player.setAudioSources(
        sources,
        initialIndex: _currentIndex,
        initialPosition: Duration.zero,
      );
      await _player.play();
      _preloadNextSong();
    } catch (e) {
      debugPrint('Playback error with setAudioSources: $e');
      // Fallback to direct load
      await _loadAndPlayCurrentSong();
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
    if (_queue.isEmpty) return;
    if (_player.hasNext) {
      await _player.seekToNext();
    } else if (_player.loopMode == LoopMode.all || _queue.length > 1) {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  Future<void> skipToPrevious() async {
    if (_queue.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    } else if (_player.loopMode == LoopMode.all || _queue.length > 1) {
      await _player.seek(Duration.zero, index: _queue.length - 1);
    }
  }

  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      _queueController.add(_queue);
      _currentSongController.add(_queue[_currentIndex]);
      try {
        await _player.seek(Duration.zero, index: index);
        if (!_player.playing) {
          await _player.play();
        }
      } catch (e) {
        debugPrint('seek error: $e');
        await _loadAndPlayCurrentSong();
      }
      _preloadNextSong();
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

  void setQueue(List<Song> newQueue, {int? currentIndex}) {
    _queue = List.from(newQueue);
    AudioStreamingProxy.registerSongs(_queue);
    if (currentIndex != null && currentIndex >= 0 && currentIndex < _queue.length) {
      _currentIndex = currentIndex;
    }
    _queueController.add(_queue);
  }

  void addToQueue(Song song) {
    _queue.add(song);
    AudioStreamingProxy.registerSongs([song]);
    _player.addAudioSource(
      AudioSource.uri(
        Uri.parse(AudioStreamingProxy.getSongStreamUrl(song)),
        tag: _buildMediaItem(song),
      ),
    );
    _queueController.add(_queue);
  }

  void removeFromQueue(int index) {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      _player.removeAudioSourceAt(index);
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

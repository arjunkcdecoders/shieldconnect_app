import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

class RoomManager extends ChangeNotifier {
  lk.Room? _room;
  lk.Room? get room => _room;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _isSpeakerOn = false;
  bool get isSpeakerOn => _isSpeakerOn;

  bool _isCameraOn = false;
  bool get isCameraOn => _isCameraOn;

  lk.VideoTrack? _localVideoTrack;
  lk.VideoTrack? get localVideoTrack => _localVideoTrack;

  lk.VideoTrack? _remoteVideoTrack;
  lk.VideoTrack? get remoteVideoTrack => _remoteVideoTrack;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  final Set<String> _connectedParticipants = {};
  Set<String> get connectedParticipants => _connectedParticipants;

  bool hasParticipantLeft(String identity) {
    final room = _room;
    if (room == null) return false;
    // Dynamically ensure all currently active remote participants are registered as connected
    for (final rp in room.remoteParticipants.values) {
      if (rp.identity.isNotEmpty) {
        _connectedParticipants.add(rp.identity);
      }
    }
    return _connectedParticipants.contains(identity) &&
        !room.remoteParticipants.values.any((rp) => rp.identity == identity);
  }

  /// Open local camera immediately for preview before room connection
  Future<void> startLocalCamera() async {
    try {
      if (_localVideoTrack != null) return;
      dev.log(
        '🎙️ LiveKit: Starting local camera preview immediately',
        name: 'RoomManager',
      );
      final track = await lk.LocalVideoTrack.createCameraTrack();
      _localVideoTrack = track;
      _isCameraOn = true;
      notifyListeners();
    } catch (e) {
      dev.log(
        '🚨 LiveKit: Failed to start local camera preview: $e',
        name: 'RoomManager',
      );
    }
  }

  /// Connect to the LiveKit SFU media room.
  Future<void> connectRoom(
    String wsUrl,
    String token, {
    bool isVideo = false,
  }) async {
    if (_isConnecting || _isConnected) {
      dev.log(
        '🎙️ LiveKit: Already connecting or connected. Ignoring duplicate connect request.',
        name: 'RoomManager',
      );
      return;
    }
    _isConnecting = true;
    notifyListeners();

    try {
      dev.log(
        '🎙️ LiveKit: Connecting to room $wsUrl with token $token',
        name: 'RoomManager',
      );

      // Cleanup previous session if any (except the local preview track which we want to reuse/publish)
      if (_room != null) {
        await disconnectRoom();
      }

      final roomOptions = lk.RoomOptions(
        defaultVideoPublishOptions: const lk.VideoPublishOptions(
          simulcast: true,
        ),
      );

      final room = lk.Room(roomOptions: roomOptions);
      _room = room;

      // Setup connection state and participant listener hooks
      final listener = room.createListener();

      listener.on<lk.RoomDisconnectedEvent>((event) {
        dev.log('🎙️ LiveKit: Room disconnected', name: 'RoomManager');
        _cleanupRoomState();
        notifyListeners();
      });

      listener.on<lk.ParticipantConnectedEvent>((event) {
        dev.log(
          '🎙️ LiveKit: Participant connected: ${event.participant.identity}',
          name: 'RoomManager',
        );
        _connectedParticipants.add(event.participant.identity);
        notifyListeners();
      });

      listener.on<lk.ParticipantDisconnectedEvent>((event) {
        dev.log(
          '🎙️ LiveKit: Participant disconnected: ${event.participant.identity}',
          name: 'RoomManager',
        );
        notifyListeners();
      });

      listener.on<lk.ActiveSpeakersChangedEvent>((event) {
        dev.log('🎙️ LiveKit: Active speakers changed', name: 'RoomManager');
        notifyListeners();
      });

      listener.on<lk.TrackSubscribedEvent>((event) {
        dev.log(
          '🎙️ LiveKit: Track subscribed of type ${event.track.kind}',
          name: 'RoomManager',
        );
        if (event.track.kind.toString().toLowerCase().contains('video')) {
          _remoteVideoTrack = event.track as lk.VideoTrack;
          notifyListeners();
        }
      });

      listener.on<lk.TrackUnsubscribedEvent>((event) {
        dev.log('🎙️ LiveKit: Track unsubscribed', name: 'RoomManager');
        if (event.track.kind.toString().toLowerCase().contains('video')) {
          _remoteVideoTrack = null;
          notifyListeners();
        }
      });

      listener.on<lk.TrackMutedEvent>((event) {
        dev.log(
          '🎙️ LiveKit: Track muted: ${event.publication.sid}',
          name: 'RoomManager',
        );
        if (event.publication.kind.toString().toLowerCase().contains('video')) {
          notifyListeners();
        }
      });

      listener.on<lk.TrackUnmutedEvent>((event) {
        dev.log(
          '🎙️ LiveKit: Track unmuted: ${event.publication.sid}',
          name: 'RoomManager',
        );
        if (event.publication.kind.toString().toLowerCase().contains('video')) {
          notifyListeners();
        }
      });

      await room.connect(wsUrl, token);
      _isConnected = true;
      _isCameraOn = isVideo;
      _isSpeakerOn = isVideo;

      _connectedParticipants.clear();
      _connectedParticipants.addAll(
        room.remoteParticipants.values.map((p) => p.identity),
      );

      // Enable local audio and camera based on preferences
      await room.localParticipant?.setMicrophoneEnabled(true);
      _isMuted = false;

      if (isVideo) {
        if (_localVideoTrack is lk.LocalVideoTrack) {
          dev.log(
            '🎙️ LiveKit: Publishing pre-initialized local video track',
            name: 'RoomManager',
          );
          await room.localParticipant?.publishVideoTrack(
            _localVideoTrack as lk.LocalVideoTrack,
          );
        } else {
          await room.localParticipant?.setCameraEnabled(true);
          // Extract local video track for preview rendering if available
          final publications = room.localParticipant?.videoTrackPublications;
          if (publications != null && publications.isNotEmpty) {
            _localVideoTrack = publications.first.track as lk.VideoTrack?;
          }
        }
      }

      // Set Speakerphone state
      await lk.Hardware.instance.setSpeakerphoneOn(_isSpeakerOn);

      dev.log(
        '🎙️ LiveKit: Connected successfully. Local Participant Identity: ${room.localParticipant?.identity}',
        name: 'RoomManager',
      );
      _isConnecting = false;
      notifyListeners();
    } catch (e) {
      dev.log(
        '🚨 LiveKit: Connection failed: $e',
        name: 'RoomManager',
        error: e,
      );
      _cleanupRoomState();
      rethrow;
    }
  }

  /// Toggle microphone muting state.
  Future<void> setMicrophoneEnabled(bool enabled) async {
    final room = _room;
    if (room == null) return;
    try {
      await room.localParticipant?.setMicrophoneEnabled(enabled);
      _isMuted = !enabled;
      notifyListeners();
    } catch (e) {
      dev.log(
        '🚨 LiveKit: Failed to toggle microphone: $e',
        name: 'RoomManager',
        error: e,
      );
    }
  }

  /// Toggle local camera publication state.
  Future<void> setCameraEnabled(bool enabled) async {
    final room = _room;
    if (room == null) {
      if (!enabled) {
        if (_localVideoTrack is lk.LocalVideoTrack) {
          await (_localVideoTrack as lk.LocalVideoTrack).stop();
        }
        _localVideoTrack = null;
        _isCameraOn = false;
        notifyListeners();
      } else {
        await startLocalCamera();
      }
      return;
    }
    try {
      await room.localParticipant?.setCameraEnabled(enabled);
      _isCameraOn = enabled;
      if (enabled) {
        final publications = room.localParticipant?.videoTrackPublications;
        if (publications != null && publications.isNotEmpty) {
          _localVideoTrack = publications.first.track as lk.VideoTrack?;
        }
      } else {
        _localVideoTrack = null;
      }
      notifyListeners();
    } catch (e) {
      dev.log(
        '🚨 LiveKit: Failed to toggle camera: $e',
        name: 'RoomManager',
        error: e,
      );
    }
  }

  /// Toggle hardware speakerphone routing.
  Future<void> setSpeakerphoneOn(bool speakerOn) async {
    try {
      await lk.Hardware.instance.setSpeakerphoneOn(speakerOn);
      _isSpeakerOn = speakerOn;
      notifyListeners();
    } catch (e) {
      dev.log(
        '🚨 LiveKit: Failed to toggle speakerphone hardware: $e',
        name: 'RoomManager',
        error: e,
      );
    }
  }

  /// Cleanly close media room session and dispose resources.
  Future<void> disconnectRoom() async {
    // Clean up local camera track if any
    if (_localVideoTrack is lk.LocalVideoTrack) {
      try {
        await (_localVideoTrack as lk.LocalVideoTrack).stop();
      } catch (e) {
        dev.log('🚨 LiveKit: Error stopping track: $e', name: 'RoomManager');
      }
    }

    final room = _room;
    if (room == null) {
      _cleanupRoomState();
      notifyListeners();
      return;
    }
    try {
      dev.log('🎙️ LiveKit: Disconnecting from room', name: 'RoomManager');
      await room.disconnect();
      await room.dispose();
    } catch (e) {
      dev.log(
        '🚨 LiveKit: Error during disconnect: $e',
        name: 'RoomManager',
        error: e,
      );
    } finally {
      _cleanupRoomState();
      notifyListeners();
    }
  }

  void _cleanupRoomState() {
    _room = null;
    _isConnected = false;
    _isConnecting = false;
    _isMuted = false;
    _isSpeakerOn = false;
    _isCameraOn = false;
    _localVideoTrack = null;
    _remoteVideoTrack = null;
    _connectedParticipants.clear();
  }

  lk.VideoTrack? getRemoteVideoTrackFor(String userId) {
    final room = _room;
    if (room == null) return null;
    for (final participant in room.remoteParticipants.values) {
      if (participant.identity == userId) {
        final publications = participant.videoTrackPublications;
        if (publications.isNotEmpty) {
          final firstPub = publications.first;
          if (firstPub.track is lk.VideoTrack) {
            return firstPub.track as lk.VideoTrack;
          }
        }
      }
    }
    return null;
  }
}

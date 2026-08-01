import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/services/call_manager.dart';
import 'package:shieldconnect_app/services/socket_service.dart';
import 'dart:developer' as dev;

class CallController extends ChangeNotifier {
  // Add User / Friends State Management
  final ApiService _apiService = ApiService();
  bool _isLoadingFriends = false;
  bool get isLoadingFriends => _isLoadingFriends;

  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> get friends => _friends;

  String? _friendsErrorMessage;
  String? get friendsErrorMessage => _friendsErrorMessage;

  // Ongoing Call Participants State Management
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>> get participants => _participants;
  bool _isLoadingParticipants = false;
  bool get isLoadingParticipants => _isLoadingParticipants;

  String? _participantsErrorMessage;
  String? get participantsErrorMessage => _participantsErrorMessage;

  Timer? _participantsTimer;
  String? _pollingCallId;

  bool _hasFetchedParticipants = false;
  final Map<String, DateTime> _callingStartTimes = {};
  bool get hasFetchedParticipants => _hasFetchedParticipants;

  int _currentPage = 0;
  int get currentPage => _currentPage;

  PageController? _pageController;
  PageController get pageController {
    _pageController ??= PageController(initialPage: _currentPage);
    return _pageController!;
  }

  void setCurrentPage(int page) {
    if (_currentPage != page) {
      _currentPage = page;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  CallController() {
    CallManager().addListener(_handleCallManagerStateChange);
  }

  void _handleCallManagerStateChange() {
    final callManager = CallManager();
    if ((callManager.state == CallState.connected ||
            callManager.state == CallState.dialing ||
            callManager.state == CallState.ringing) &&
        callManager.currentCallId != null) {
      if (_pollingCallId != callManager.currentCallId) {
        _currentPage = 0;
        _pageController?.dispose();
        _pageController = PageController(initialPage: 0);
        _hasFetchedParticipants = false;
        _participants = [];
        startParticipantsPolling(callManager.currentCallId!);
      }
    } else if (callManager.state == CallState.idle) {
      if (_pollingCallId != null || _pageController != null) {
        stopParticipantsPolling();
      }
    }
  }

  @override
  void dispose() {
    CallManager().removeListener(_handleCallManagerStateChange);
    _participantsTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  int getGridMembersCount() {
    final callManager = CallManager();
    final myId = callManager.myUserId;

    // We always have "Me"
    int count = 1;

    // If not group call, we have the other participant
    final String otherId = (myId == callManager.callerId)
        ? (callManager.receiverId ?? '')
        : (callManager.callerId ?? '');

    bool hasOther = false;
    if (otherId.isNotEmpty && !callManager.isGroup) {
      // Check if other has left
      bool otherLeft = false;
      if (callManager.roomManager.hasParticipantLeft(otherId)) {
        otherLeft = true;
      } else {
        try {
          final p = _participants.firstWhere((p) {
            final pId = p['user_id'] ?? p['id'] ?? p['_id'];
            return pId?.toString() == otherId;
          });
          final String? status = p['status']?.toString().toLowerCase();
          if (status == 'left' ||
              status == 'declined' ||
              status == 'missed' ||
              status == 'rejected') {
            otherLeft = true;
          }
        } catch (_) {
          if (_hasFetchedParticipants) {
            otherLeft = true;
          }
        }
      }
      if (!otherLeft) {
        count++;
        hasOther = true;
      }
    }

    // Add other unique participants from _participants
    for (final p in _participants) {
      final pId = p['user_id'] ?? p['id'] ?? p['_id'];
      if (pId != null) {
        final String pIdStr = pId.toString();
        if (callManager.roomManager.hasParticipantLeft(pIdStr)) {
          continue;
        }
        // Check if it's Me
        if (pIdStr == myId?.toString()) {
          continue;
        }
        // Check if it's the other 1-to-1 participant we already counted
        if (hasOther && pIdStr == otherId) {
          continue;
        }
        count++;
      }
    }

    return count;
  }

  Future<void> fetchFriends(String? myUserId) async {
    _isLoadingFriends = true;
    _friendsErrorMessage = null;
    notifyListeners();

    try {
      String? resolvedUserId = myUserId;
      if (resolvedUserId == null) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? userSession = prefs.getString('user_session');
        if (userSession != null) {
          final Map<String, dynamic> userMap = jsonDecode(userSession);
          resolvedUserId = userMap['_id'] ?? userMap['id'];
        }
      }

      if (resolvedUserId == null) {
        _friendsErrorMessage = "Unable to resolve user session.";
        _isLoadingFriends = false;
        notifyListeners();
        return;
      }

      final response = await _apiService.get(
        "/connections/friends/$resolvedUserId",
      );
      if (response.data != null && response.data['success'] == true) {
        final List rawData = response.data['data'] ?? [];
        _friends = List<Map<String, dynamic>>.from(rawData);
      } else {
        _friendsErrorMessage = "Failed to load connections.";
      }
    } catch (e) {
      _friendsErrorMessage = "An error occurred while loading.";
    } finally {
      _isLoadingFriends = false;
      notifyListeners();
    }
  }

  Future<void> fetchParticipants(String callId) async {
    final bool wasLoading = _isLoadingParticipants;
    if (_participants.isEmpty) {
      _isLoadingParticipants = true;
    }
    _participantsErrorMessage = null;

    try {
      final response = await _apiService.get("/call/participants/$callId");
      if (response.data != null) {
        _hasFetchedParticipants = true;
        final dynamic rawData = response.data is Map
            ? (response.data['data'] ?? response.data['participants'] ?? [])
            : response.data;
        List<Map<String, dynamic>> newParticipants = [];
        if (rawData is List) {
          newParticipants = List<Map<String, dynamic>>.from(
            rawData.map((e) => Map<String, dynamic>.from(e)),
          );
        } else if (response.data['success'] == true) {
          final List rawList = response.data['data'] ?? [];
          newParticipants = List<Map<String, dynamic>>.from(rawList);
        }

        // Filter out inactive participants (status: left, declined, missed, rejected)
        newParticipants = newParticipants.where((p) {
          final String? status = p['status']?.toString().toLowerCase();
          return status != 'left' &&
              status != 'declined' &&
              status != 'missed' &&
              status != 'rejected';
        }).toList();

        // Handle invitation timeouts (30 seconds) for all calling participants
        final callManager = CallManager();
        final String? myId = callManager.myUserId;
        for (final p in newParticipants) {
          final pId = p['user_id'] ?? p['id'] ?? p['_id'];
          if (pId != null) {
            final String pIdStr = pId.toString();
            if (pIdStr == myId) continue;

            final String? status = p['status']?.toString().toLowerCase();
            final bool isCalling = status == 'ringing' ||
                status == 'dialing' ||
                status == 'invited' ||
                status == null;

            if (isCalling) {
              if (!_callingStartTimes.containsKey(pIdStr)) {
                _callingStartTimes[pIdStr] = DateTime.now();
              } else {
                final startTime = _callingStartTimes[pIdStr]!;
                final diff = DateTime.now().difference(startTime);
                if (diff.inSeconds >= 30) {
                  // Prevent duplicate triggers
                  _callingStartTimes[pIdStr] = DateTime.now().add(const Duration(minutes: 5));
                  removeTimedOutParticipant(callId, pIdStr);
                }
              }
            } else {
              _callingStartTimes.remove(pIdStr);
            }
          }
        }

        // Clean up tracking for participants no longer in the new list
        final activeUserIds = newParticipants
            .map((p) => (p['user_id'] ?? p['id'] ?? p['_id'])?.toString())
            .toSet();
        _callingStartTimes.removeWhere((key, value) => !activeUserIds.contains(key));

        // Check if there is any active participant other than Me
        final bool hasOtherActiveParticipant = newParticipants.any((p) {
          final pId = p['user_id'] ?? p['id'] ?? p['_id'];
          return pId != null && pId.toString() != myId;
        });

        // Automatically end the call if connected and no other participant is left
        if (CallManager().state == CallState.connected &&
            CallManager().roomManager.isConnected &&
            !CallManager().isReconnecting &&
            CallManager().secondsElapsed > 2 &&
            !hasOtherActiveParticipant) {
          dev.log(
            '👥 CallController: No other active participant left in the call besides Me. Automatically ending call.',
            name: 'CallController',
          );
          CallManager().endCall();
          _participants = [];
          _isLoadingParticipants = false;
          notifyListeners();
          return;
        }

        // Identify participants who have left and log it
        for (final oldP in _participants) {
          final oldId = oldP['user_id'] ?? oldP['id'] ?? oldP['_id'];
          if (oldId != null) {
            final stillActive = newParticipants.any((p) {
              final newId = p['user_id'] ?? p['id'] ?? p['_id'];
              return newId?.toString() == oldId.toString();
            });
            if (!stillActive) {
              final String name = oldP['name'] ?? 'User';
              dev.log(
                '👥 CallController: Participant left call: $name ($oldId). Removing from grid UI.',
                name: 'CallController',
              );
            }
          }
        }

        // Compare newParticipants with _participants to prevent redundant notifyListeners() and blinking
        bool isIdentical = newParticipants.length == _participants.length;
        if (isIdentical) {
          for (int i = 0; i < newParticipants.length; i++) {
            final pNew = newParticipants[i];
            final pOld = _participants[i];
            final idNew = pNew['user_id'] ?? pNew['id'] ?? pNew['_id'];
            final idOld = pOld['user_id'] ?? pOld['id'] ?? pOld['_id'];
            final String? avatarNew = pNew['avatar'] ?? pNew['profile_pic'];
            final String? avatarOld = pOld['avatar'] ?? pOld['profile_pic'];

            final bool muteNew =
                pNew['is_muted'] == true || pNew['isMuted'] == true;
            final bool muteOld =
                pOld['is_muted'] == true || pOld['isMuted'] == true;

            final String? statusNew = pNew['status']?.toString();
            final String? statusOld = pOld['status']?.toString();

            if (idNew != idOld ||
                pNew['name'] != pOld['name'] ||
                muteNew != muteOld ||
                statusNew != statusOld ||
                _normalizeAvatarUrl(avatarNew) !=
                    _normalizeAvatarUrl(avatarOld)) {
              isIdentical = false;
              break;
            }
          }
        }

        if (!isIdentical || _isLoadingParticipants) {
          _participants = newParticipants;

          // Clamp _currentPage based on new participant list length
          final int total = getGridMembersCount();
          final int numPages = total <= 4 ? 1 : 1 + ((total - 4) / 3.0).ceil();
          if (_currentPage >= numPages) {
            _currentPage = numPages - 1;
            if (_pageController != null && _pageController!.hasClients) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _pageController!.jumpToPage(_currentPage);
              });
            }
          }
          if (_currentPage < 0) {
            _currentPage = 0;
            if (_pageController != null && _pageController!.hasClients) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _pageController!.jumpToPage(_currentPage);
              });
            }
          }

          _isLoadingParticipants = false;
          notifyListeners();
          return;
        }
      }
    } catch (e) {
      _participantsErrorMessage =
          "An error occurred while loading participants.";
    } finally {
      if (_isLoadingParticipants || wasLoading) {
        _isLoadingParticipants = false;
        notifyListeners();
      }
    }
  }

  String? _normalizeAvatarUrl(dynamic avatar) {
    if (avatar == null || avatar is! String || avatar.isEmpty) return null;
    try {
      final uri = Uri.parse(avatar);
      return uri.replace(queryParameters: {}).toString();
    } catch (_) {
      return avatar;
    }
  }

  Future<bool> addParticipant(String callId, String userId) async {
    try {
      final response = await _apiService.post(
        "/call/add-participant",
        data: {"call_id": callId, "user_id": userId},
      );
      if (response.data != null && response.data['success'] == true) {
        await fetchParticipants(callId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> removeTimedOutParticipant(String callId, String userId) async {
    try {
      dev.log(
        '👥 CallController: Removing timed out participant $userId from call $callId',
        name: 'CallController',
      );

      // REST /call/decline endpoint to update status
      await _apiService.post(
        '/call/decline',
        data: {'call_id': callId, 'user_id': userId},
      );

      // Emit call_rejected socket event
      final callManager = CallManager();
      SocketService().emit('call_rejected', {
        'to': userId,
        'callId': callId,
        'roomId': callManager.currentRoomId,
        'callerId': callManager.callerId,
        'receiverId': userId,
      });

      _callingStartTimes.remove(userId);
      await fetchParticipants(callId);
    } catch (e) {
      dev.log(
        '🚨 CallController: Error removing timed out participant: $e',
        name: 'CallController',
      );
    }
  }

  void startParticipantsPolling(String callId) {
    if (_pollingCallId == callId) return;
    _pollingCallId = callId;
    _participantsTimer?.cancel();
    _callingStartTimes.clear();
    fetchParticipants(callId); // initial load
    _participantsTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      fetchParticipants(callId);
    });
  }

  void stopParticipantsPolling() {
    _pollingCallId = null;
    _participantsTimer?.cancel();
    _participantsTimer = null;
    _participants = [];
    _hasFetchedParticipants = false;
    _currentPage = 0;
    _pageController?.dispose();
    _pageController = null;
    _callingStartTimes.clear();
    notifyListeners();
  }
}

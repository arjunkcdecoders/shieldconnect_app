import 'package:flutter/material.dart';

class CallController extends ChangeNotifier {
  bool _isMuted = false;
  bool get isMuted => _isMuted;

  bool _isSpeakerOn = false;
  bool get isSpeakerOn => _isSpeakerOn;

  bool _isCameraOn = true;
  bool get isCameraOn => _isCameraOn;

  String _callDuration = "00:00";
  String get callDuration => _callDuration;

  bool _isInCall = false;
  bool get isInCall => _isInCall;

  void startCall(String userName, {bool isVideo = false}) {
    _isInCall = true;
    _isCameraOn = isVideo;
    _isMuted = false;
    _isSpeakerOn = isVideo; // Default speaker on for video
    _callDuration = "00:00";
    notifyListeners();
    // In a real app, logic to start timer would go here
  }

  void endCall() {
    _isInCall = false;
    notifyListeners();
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    notifyListeners();
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    notifyListeners();
  }

  void toggleCamera() {
    _isCameraOn = !_isCameraOn;
    notifyListeners();
  }

  void updateDuration(String duration) {
    _callDuration = duration;
    notifyListeners();
  }
}

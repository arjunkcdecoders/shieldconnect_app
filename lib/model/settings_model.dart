import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsModel {
  final String? id;
  final String? docLimit;
  final String? audioLimit;
  final String? videoLimit;
  final String? imageLimit;
  final int? shareLimit;
  final int? msgLength;
  final String? uploadTypes;
  final int? callTimeout;
  final int? statusExpiry;
  final int? sessionExpiry;
  final int? maxGroup;
  final int? maxGroupMembers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SettingsModel({
    this.id,
    this.docLimit,
    this.audioLimit,
    this.videoLimit,
    this.imageLimit,
    this.shareLimit,
    this.msgLength,
    this.uploadTypes,
    this.callTimeout,
    this.statusExpiry,
    this.sessionExpiry,
    this.maxGroup,
    this.maxGroupMembers,
    this.createdAt,
    this.updatedAt,
  });

  int getDocLimitBytes() => _parseLimitToBytes(docLimit, 20 * 1024 * 1024);
  int getAudioLimitBytes() => _parseLimitToBytes(audioLimit, 15 * 1024 * 1024);
  int getVideoLimitBytes() => _parseLimitToBytes(videoLimit, 100 * 1024 * 1024);
  int getImageLimitBytes() => _parseLimitToBytes(imageLimit, 10 * 1024 * 1024);

  static int _parseLimitToBytes(String? limitStr, int defaultBytes) {
    if (limitStr == null || limitStr.isEmpty) return defaultBytes;
    try {
      final normalized = limitStr.trim().toUpperCase();
      final regExp = RegExp(r'^(\d+(?:\.\d+)?)\s*([KMGT]?B)$');
      final match = regExp.firstMatch(normalized);
      if (match != null) {
        final value = double.parse(match.group(1)!);
        final unit = match.group(2)!;
        switch (unit) {
          case 'KB':
            return (value * 1024).round();
          case 'MB':
            return (value * 1024 * 1024).round();
          case 'GB':
            return (value * 1024 * 1024 * 1024).round();
          case 'B':
          default:
            return value.round();
        }
      }
      final directDouble = double.tryParse(normalized.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (directDouble != null) {
        if (normalized.contains('KB')) return (directDouble * 1024).round();
        if (normalized.contains('GB')) return (directDouble * 1024 * 1024 * 1024).round();
        if (normalized.contains('B')) return directDouble.round();
        return (directDouble * 1024 * 1024).round();
      }
    } catch (e) {
      // ignore
    }
    return defaultBytes;
  }

  static String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = 0;
    double doubleBytes = bytes.toDouble();
    while (doubleBytes >= 1024 && i < suffixes.length - 1) {
      doubleBytes /= 1024;
      i++;
    }
    return "${doubleBytes.toStringAsFixed(decimals)} ${suffixes[i]}";
  }

  static Future<SettingsModel> loadActiveSettings() async {
    try {
      final SharedPreferences sharedPrefs = await SharedPreferences.getInstance();
      final String? sessionStr = sharedPrefs.getString('user_session');
      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final dynamic settingsJson = userMap['settings'];
        if (settingsJson != null) {
          return SettingsModel.fromJson(settingsJson as Map<String, dynamic>);
        }
      }
    } catch (e) {
      // ignore
    }
    return SettingsModel(
      docLimit: "20MB",
      audioLimit: "15MB",
      videoLimit: "100MB",
      imageLimit: "10MB",
      statusExpiry: 24,
      maxGroup: 50,
      maxGroupMembers: 256,
    );
  }

  factory SettingsModel.fromJson(Map<String, dynamic> json) {
    return SettingsModel(
      id: json['_id'] as String? ?? json['id'] as String?,
      docLimit: json['docLimit'] as String? ?? json['doc_limit'] as String?,
      audioLimit: json['audioLimit'] as String? ?? json['audio_limit'] as String?,
      videoLimit: json['videoLimit'] as String? ?? json['video_limit'] as String?,
      imageLimit: json['imageLimit'] as String? ?? json['image_limit'] as String?,
      shareLimit: json['shareLimit'] as int? ?? json['share_limit'] as int?,
      msgLength: json['msgLength'] as int? ?? json['msg_length'] as int?,
      uploadTypes: json['uploadTypes'] as String? ?? json['upload_types'] as String?,
      callTimeout: json['callTimeout'] as int? ?? json['call_timeout'] as int?,
      statusExpiry: json['statusExpiry'] as int? ?? json['status_expiry'] as int?,
      sessionExpiry: json['sessionExpiry'] as int? ?? json['session_expiry'] as int?,
      maxGroup: json['maxGroup'] as int? ?? json['max_group'] as int?,
      maxGroupMembers: json['maxGroupMembers'] as int? ?? json['max_group_members'] as int?,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : (json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : (json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'docLimit': docLimit,
      'audioLimit': audioLimit,
      'videoLimit': videoLimit,
      'imageLimit': imageLimit,
      'shareLimit': shareLimit,
      'msgLength': msgLength,
      'uploadTypes': uploadTypes,
      'callTimeout': callTimeout,
      'statusExpiry': statusExpiry,
      'sessionExpiry': sessionExpiry,
      'maxGroup': maxGroup,
      'maxGroupMembers': maxGroupMembers,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

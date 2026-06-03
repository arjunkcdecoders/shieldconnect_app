import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/model/status_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:dio/dio.dart' as dio_lib;
import 'package:video_player/video_player.dart';
import 'package:image/image.dart' as img;
import 'package:video_compress/video_compress.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:path_provider/path_provider.dart';

class StatusController extends ChangeNotifier {
  StatusController() {
    init();
  }

  List<StatusModel> _myStatuses = [];
  List<StatusModel> get myStatuses => _myStatuses;

  List<dynamic> _othersStatuses = [];
  List<dynamic> get othersStatuses => _othersStatuses;

  final Map<String, List<dynamic>> _viewersCache = {};
  Map<String, List<dynamic>> get viewersCache => _viewersCache;

  String? _profileImage;
  String? get profileImage => _profileImage;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  int _uploadSentBytes = 0;
  int get uploadSentBytes => _uploadSentBytes;

  int _uploadTotalBytes = 0;
  int get uploadTotalBytes => _uploadTotalBytes;

  double _uploadProgress = 0.0;
  double get uploadProgress => _uploadProgress;

  String? _userId;
  String? get userId => _userId;

  // --- Media Status Preview State ---
  final TextEditingController captionController = TextEditingController();
  VideoPlayerController? _videoPlayerController;
  VideoPlayerController? get videoPlayerController => _videoPlayerController;

  bool _isVideoInitialized = false;
  bool get isVideoInitialized => _isVideoInitialized;

  // --- Text Status Creator State ---
  final TextEditingController textStatusController = TextEditingController();

  final List<String> hexColors = [
    "#5ABED6", // Light Blue
    "#6B8ECC", // Pastel Blue
    "#8661D6", // Purple
    "#C762D2", // Magenta/pink
    "#78E266", // Light Green
    "#0F9C35", // Dark Green
    "#E2A814", // Gold/Orange
    "#D64D4D", // Red
  ];

  final List<String> fontFamilies = [
    'ClashDisplay',
    'Roboto',
    'PlayfairDisplay',
    'Courier',
  ];

  int _selectedColorIndex = 0;
  int get selectedColorIndex => _selectedColorIndex;

  int _selectedFontIndex = 0;
  int get selectedFontIndex => _selectedFontIndex;

  String _previousValidText = "";

  void cycleFont() {
    _selectedFontIndex = (_selectedFontIndex + 1) % fontFamilies.length;
    notifyListeners();
  }

  void selectColor(int index) {
    _selectedColorIndex = index;
    notifyListeners();
  }

  void handleTextStatusChanged(BuildContext context) {
    final text = textStatusController.text;
    final lines = text.split('\n').length;

    if (text.length > 700 || lines > 10) {
      textStatusController.text = _previousValidText;
      textStatusController.selection = TextSelection.fromPosition(
        TextPosition(offset: textStatusController.text.length),
      );
      _showLimitExceededDialog(context);
    } else {
      _previousValidText = text;
    }
    notifyListeners();
  }

  void clearTextStatus() {
    textStatusController.clear();
    _selectedColorIndex = 0;
    _selectedFontIndex = 0;
    _previousValidText = "";
  }

  void _showLimitExceededDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Status Limit Exceeded",
            style: fontStyle.clashDisplayBold18.textColor(
              appColor(context).black,
            ),
          ),
          content: Text(
            "Your status update cannot exceed 700 characters or 10 lines.",
            style: fontStyle.clashDisplayRegular14.textColor(
              appColor(context).grey500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                "OK",
                style: fontStyle.clashDisplaySemiBold14.textColor(
                  appColor(context).secondary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> init() async {
    _isLoading = true;
    _myStatuses = [];
    _othersStatuses = [];
    _viewersCache.clear();
    _profileImage = null;
    _userId = null;
    notifyListeners();

    await fetchProfileImage();
    if (_userId != null) {
      await fetchMyStatuses();
      await fetchOthersStatuses();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProfileImage() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? sessionStr = prefs.getString('user_session');
      debugPrint("StatusController: sessionStr: $sessionStr");

      if (sessionStr != null) {
        final Map<String, dynamic> userMap = jsonDecode(sessionStr);
        final UserModel user = UserModel.fromJson(userMap);
        _userId = user.id;
        debugPrint("StatusController: userId: $_userId");

        if (_userId != null) {
          final response = await ApiService().get(
            '/users/$_userId?currentUserId=$_userId',
          );
          debugPrint("StatusController: API Response: ${response.data}");

          final dynamic responseData = response.data;
          final Map<String, dynamic> json = responseData is String
              ? jsonDecode(responseData)
              : responseData as Map<String, dynamic>;

          if (json.containsKey('success') && json['success'] == true) {
            final data = json['data'];
            if (data != null) {
              _profileImage = data['avatar'];
            }
          }
        }
      } else {
        _profileImage = null;
      }
    } catch (e) {
      debugPrint("Error fetching profile image: $e");
      _profileImage = null;
    }
    notifyListeners();
  }

  Future<void> fetchMyStatuses() async {
    if (_userId == null) return;
    try {
      final response = await ApiService().get('/status/me?userId=$_userId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        final list = json['data'] as List<dynamic>;
        _myStatuses = list.map((e) => StatusModel.fromJson(e as Map<String, dynamic>)).toList();
        
        // Sort myStatuses chronologically (oldest first, newest last)
        _myStatuses.sort((a, b) {
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aTime.compareTo(bTime);
        });

        // Prefetch status viewers for all my statuses immediately in the background
        for (var status in _myStatuses) {
          if (status.id != null) {
            fetchStatusViewers(status.id!).then((viewers) {
              _viewersCache[status.id!] = viewers;
              notifyListeners();
            }).catchError((e) {
              debugPrint("Error prefetching status viewers in controller: $e");
            });
          }
        }
      } else {
        _myStatuses = [];
      }
    } catch (e) {
      debugPrint("Error fetching my statuses: $e");
      _myStatuses = [];
    }
    notifyListeners();
  }

  Future<void> fetchOthersStatuses() async {
    if (_userId == null) return;
    try {
      final response = await ApiService().get('/status?userId=$_userId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        _othersStatuses = json['data'] as List<dynamic>;
        for (var item in _othersStatuses) {
          if (item is Map<String, dynamic> && item['statuses'] != null) {
            final mutableList = List<dynamic>.from(item['statuses']);
            mutableList.sort((a, b) {
              final aMap = a as Map<String, dynamic>;
              final bMap = b as Map<String, dynamic>;
              final aTimeStr = aMap['createdAt'] as String? ?? aMap['created_at'] as String?;
              final bTimeStr = bMap['createdAt'] as String? ?? bMap['created_at'] as String?;
              final aTime = aTimeStr != null ? DateTime.tryParse(aTimeStr) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0);
              final bTime = bTimeStr != null ? DateTime.tryParse(bTimeStr) ?? DateTime.fromMillisecondsSinceEpoch(0) : DateTime.fromMillisecondsSinceEpoch(0);
              return aTime.compareTo(bTime);
            });
            item['statuses'] = mutableList;
          }
        }
      } else {
        _othersStatuses = [];
      }
    } catch (e) {
      debugPrint("Error fetching others statuses: $e");
      _othersStatuses = [];
    }
    notifyListeners();
  }

  Future<bool> uploadTextStatus(String text, String bgColor) async {
    if (_userId == null) return false;
    _isLoading = true;
    notifyListeners();
    try {
      final data = {
        "user_id": _userId,
        "caption": text,
        "content": text,
        "content_type": "text",
        "background_color": bgColor,
      };
      final response = await ApiService().post(
        '/status',
        data: data,
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        await fetchMyStatuses();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error uploading text status: $e");
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<File> _compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) return file;

      img.Image resizedImage = decodedImage;
      if (decodedImage.width > 1080 || decodedImage.height > 1080) {
        if (decodedImage.width > decodedImage.height) {
          resizedImage = img.copyResize(decodedImage, width: 1080);
        } else {
          resizedImage = img.copyResize(decodedImage, height: 1080);
        }
      }

      final compressedBytes = img.encodeJpg(resizedImage, quality: 80);
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/compressed_img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(compressedBytes);
      debugPrint("StatusController: Image compressed from ${bytes.length} to ${compressedBytes.length} bytes");
      return tempFile;
    } catch (e) {
      debugPrint("Error compressing image in controller: $e");
      return file;
    }
  }

  Future<File> _compressVideo(File file) async {
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        debugPrint("StatusController: Video compression is only supported on Android/iOS, skipping");
        return file;
      }

      debugPrint("StatusController: Compressing video at ${file.path}...");
      final MediaInfo? mediaInfo = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (mediaInfo != null && mediaInfo.file != null) {
        debugPrint("StatusController: Video compressed successfully to ${mediaInfo.file!.path}");
        return mediaInfo.file!;
      }
    } catch (e) {
      debugPrint("Error compressing video in controller: $e");
    }
    return file;
  }

  Future<bool> uploadMediaStatus(File file, String caption, String contentType) async {
    if (_userId == null) return false;
    _isLoading = true;
    _isUploading = false;
    _uploadSentBytes = 0;
    _uploadTotalBytes = 0;
    _uploadProgress = 0.0;
    notifyListeners();

    File? compressedFile;
    try {
      if (contentType == 'video') {
        final int originalSize = await file.length();
        if (originalSize > 100 * 1024 * 1024) {
          debugPrint("StatusController: Video size exceeds 100MB, aborting upload");
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      File fileToUpload = file;

      if (contentType == 'image') {
        compressedFile = await _compressImage(file);
        fileToUpload = compressedFile;
      } else if (contentType == 'video') {
        compressedFile = await _compressVideo(file);
        fileToUpload = compressedFile;
      }

      final filename = fileToUpload.path.split('/').last;
      
      // Update upload state
      _uploadTotalBytes = fileToUpload.lengthSync();
      _isUploading = true;
      notifyListeners();

      final formData = dio_lib.FormData.fromMap({
        "user_id": _userId,
        "caption": caption,
        "content_type": contentType,
        "file": await dio_lib.MultipartFile.fromFile(fileToUpload.path, filename: filename),
      });

      final response = await ApiService().post(
        '/status',
        data: formData,
        onSendProgress: (sent, total) {
          _uploadSentBytes = sent;
          _uploadTotalBytes = total > 0 ? total : fileToUpload.lengthSync();
          _uploadProgress = _uploadTotalBytes > 0 ? sent / _uploadTotalBytes : 0.0;
          notifyListeners();
        },
      );
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        await fetchMyStatuses();
        _isUploading = false;
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error uploading media status: $e");
    } finally {
      _isUploading = false;
      _uploadSentBytes = 0;
      _uploadTotalBytes = 0;
      _uploadProgress = 0.0;

      if (compressedFile != null && compressedFile.path != file.path) {
        try {
          if (await compressedFile.exists()) {
            await compressedFile.delete();
            debugPrint("StatusController: Deleted temporary compressed media file at ${compressedFile.path}");
          }
        } catch (cleanupError) {
          debugPrint("StatusController: Error deleting temporary file: $cleanupError");
        }
      }

      if (contentType == 'video' && (Platform.isAndroid || Platform.isIOS)) {
        try {
          await VideoCompress.deleteAllCache();
          debugPrint("StatusController: Cleared native video compression caches");
        } catch (cacheError) {
          debugPrint("StatusController: Error clearing native video compression cache: $cacheError");
        }
      }
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> deleteStatus(String statusId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService().delete('/status/$statusId');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true) {
        _viewersCache.remove(statusId);
        await fetchMyStatuses();
        await fetchOthersStatuses();
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Error deleting status: $e");
    }
    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> viewStatus(String statusId) async {
    if (_userId == null) return;
    try {
      final response = await ApiService().put(
        '/status/view/$statusId',
        data: {"userId": _userId},
      );
      debugPrint("StatusController: viewed status $statusId response: ${response.data}");
    } catch (e) {
      debugPrint("Error viewing status: $e");
    }
  }

  Future<List<dynamic>> fetchStatusViewers(String statusId) async {
    try {
      final response = await ApiService().get('/status/$statusId/viewers');
      final dynamic responseData = response.data;
      final Map<String, dynamic> json = responseData is String
          ? jsonDecode(responseData)
          : responseData as Map<String, dynamic>;

      if (json['success'] == true && json['data'] != null) {
        return json['data'] as List<dynamic>;
      }
    } catch (e) {
      debugPrint("Error fetching status viewers: $e");
    }
    return [];
  }

  Future<void> initVideoPlayer(File file) async {
    await disposeVideoPlayer();

    _isVideoInitialized = false;
    notifyListeners();

    try {
      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController!.initialize();
      await _videoPlayerController!.setLooping(true);
      await _videoPlayerController!.play();
      _isVideoInitialized = true;
    } catch (e) {
      debugPrint("Error initializing video player inside controller: $e");
      _isVideoInitialized = false;
    }
    notifyListeners();
  }

  Future<void> disposeVideoPlayer() async {
    if (_videoPlayerController != null) {
      final player = _videoPlayerController;
      _videoPlayerController = null;
      _isVideoInitialized = false;
      notifyListeners();

      try {
        await player!.pause();
        await player.dispose();
      } catch (e) {
        debugPrint("Error disposing video player in controller: $e");
      }
    } else {
      _isVideoInitialized = false;
    }
  }

  void clearMediaStatusPreview() {
    captionController.clear();
    disposeVideoPlayer();
  }

  @override
  void dispose() {
    captionController.dispose();
    textStatusController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }
}

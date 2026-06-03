import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class MediaCaptionScreen extends StatelessWidget {
  final String filePath;
  final String messageType; // 'image', 'video' or 'file'
  final String? fileName;

  MediaCaptionScreen({
    super.key,
    required this.filePath,
    required this.messageType,
    this.fileName,
  });

  final TextEditingController _captionController = TextEditingController();
  final ValueNotifier<bool> _isSending = ValueNotifier<bool>(false);

  Widget _buildDocumentPreview(BuildContext context) {
    final String displayFileName = fileName ?? filePath.split('/').last.split('\\').last;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: appColor(context).secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_rounded,
              color: appColor(context).secondary,
              size: 54,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            displayFileName,
            style: fontStyle.clashDisplaySemiBold16.textColor(Colors.white),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          FutureBuilder<int>(
            future: File(filePath).length(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                final double kb = snapshot.data! / 1024;
                final String sizeStr = kb > 1024 
                    ? "${(kb / 1024).toStringAsFixed(2)} MB" 
                    : "${kb.toStringAsFixed(2)} KB";
                return Text(
                  sizeStr,
                  style: fontStyle.clashDisplayRegular14.textColor(Colors.white54),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, // Prevents media preview from shifting/resizing when keyboard opens
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Full Screen Preview Area
            Positioned.fill(
              bottom: 80, // Leave room for caption bar
              top: 60,   // Leave room for top action bar
              child: Center(
                child: messageType == 'image'
                    ? InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.file(
                          File(filePath),
                          fit: BoxFit.contain,
                        ),
                      )
                    : messageType == 'video'
                        ? LocalVideoPlayerWidget(filePath: filePath)
                        : _buildDocumentPreview(context),
              ),
            ),

            // 2. Top Navigation & Details Bar
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context, null),
                  ),
                  Text(
                    messageType == 'image'
                        ? "Preview Image"
                        : messageType == 'video'
                            ? "Preview Video"
                            : "Preview Document",
                    style: fontStyle.clashDisplaySemiBold16.textColor(Colors.white),
                  ),
                  const SizedBox(width: 48), // Spacer to balance close button
                ],
              ),
            ),

            // 3. WhatsApp-style Bottom Caption & Send Bar
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom + 16, // Slides input bar up smoothly over the keyboard
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade900.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _captionController,
                        style: fontStyle.clashDisplayMedium14.textColor(Colors.white),
                        decoration: InputDecoration(
                          hintText: "Add a caption...",
                          hintStyle: fontStyle.clashDisplayRegular14.textColor(Colors.white54),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) async {
                          if (_isSending.value) return;
                          _isSending.value = true;
                          await Future.delayed(const Duration(milliseconds: 600));
                          if (context.mounted) {
                            Navigator.pop(context, _captionController.text.trim());
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isSending,
                    builder: (context, sending, child) {
                      return GestureDetector(
                        onTap: () async {
                          if (sending) return;
                          _isSending.value = true;
                          await Future.delayed(const Duration(milliseconds: 600));
                          if (context.mounted) {
                            Navigator.pop(context, _captionController.text.trim());
                          }
                        },
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: appColor(context).secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: appColor(context).secondary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: sending
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LocalVideoPlayerWidget extends StatefulWidget {
  final String filePath;
  const LocalVideoPlayerWidget({super.key, required this.filePath});

  @override
  State<LocalVideoPlayerWidget> createState() => _LocalVideoPlayerWidgetState();
}

class _LocalVideoPlayerWidgetState extends State<LocalVideoPlayerWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.file(File(widget.filePath));
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController!.play();
        _videoController!.setLooping(true);
      }
    } catch (e) {
      debugPrint("Error initializing video player for local preview: $e");
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideoInitialized) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            "Loading video...",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        if (_videoController != null) {
          setState(() {
            if (_videoController!.value.isPlaying) {
              _videoController!.pause();
            } else {
              _videoController!.play();
            }
          });
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _videoController!.value.aspectRatio,
            child: VideoPlayer(_videoController!),
          ),
          if (!_videoController!.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
        ],
      ),
    );
  }
}

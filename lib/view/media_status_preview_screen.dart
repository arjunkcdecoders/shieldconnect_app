import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:shieldconnect_app/controller/status_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class MediaStatusPreviewScreen extends StatelessWidget {
  final File file;
  final bool isVideo;

  const MediaStatusPreviewScreen({
    super.key,
    required this.file,
    required this.isVideo,
  });

  Future<void> _submitMediaStatus(BuildContext context) async {
    final controller = context.read<StatusController>();
    if (controller.isLoading) return;
    final caption = controller.captionController.text.trim();

    if (caption.length > 500) {
      _showCaptionLimitWarning(context, caption.length);
      return;
    }

    final contentType = isVideo ? "video" : "image";

    final success = await controller.uploadMediaStatus(
      file,
      caption,
      contentType,
    );

    if (success && context.mounted) {
      Navigator.pop(context);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload status. Please try again.')),
      );
    }
  }

  void _showCaptionLimitWarning(BuildContext context, int currentLength) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: appColor(context).secondary,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Caption Too Long",
                  style: fontStyle.clashDisplayBold18.textColor(
                    appColor(context).black,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "Media status captions cannot exceed 500 characters. Your current caption has $currentLength characters.",
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

  String formatBytes(int bytes, {int decimals = 2}) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<StatusController>(
      builder: (context, controller, child) {
        final bool isLoading = controller.isLoading;
        final bool isUploading = controller.isUploading;
        final int sentBytes = controller.uploadSentBytes;
        final int totalBytes = controller.uploadTotalBytes;
        final double progress = controller.uploadProgress;

        final videoPlayerController = controller.videoPlayerController;
        final isVideoInitialized = controller.isVideoInitialized;

        return Scaffold(
          backgroundColor: appColor(context).black,
          body: SafeArea(
            child: Stack(
              children: [
                // Full Screen Media Preview
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: isVideo
                        ? (isVideoInitialized && videoPlayerController != null && videoPlayerController.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: videoPlayerController.value.aspectRatio,
                                child: VideoPlayer(videoPlayerController),
                              )
                            : const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ))
                        : Image.file(
                            file,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),

                // Top dismiss / header overlay
                Positioned(
                  top: 10,
                  left: 10,
                  child: CircleAvatar(
                    backgroundColor: appColor(context).black.withValues(alpha: 0.5),
                    child: IconButton(
                      onPressed: isLoading ? null : () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: isLoading
                            ? appColor(context).white.withValues(alpha: 0.5)
                            : appColor(context).white,
                      ),
                    ),
                  ),
                ),

                // Top-right Video Size Pill
                if (isVideo)
                  Positioned(
                    top: 10,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: appColor(context).black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: appColor(context).white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam_rounded,
                            color: appColor(context).secondary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formatBytes(file.lengthSync()),
                            style: fontStyle.clashDisplaySemiBold12.textColor(
                              appColor(context).white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom Caption Input Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          appColor(context).black.withValues(alpha: 0.8),
                          appColor(context).transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: appColor(context).white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: appColor(context).white.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: controller.captionController,
                              style: fontStyle.clashDisplayMedium14.textColor(
                                appColor(context).white,
                              ),
                              decoration: InputDecoration(
                                hintText: "Add a caption...",
                                hintStyle: fontStyle.clashDisplayRegular14.textColor(
                                  appColor(context).white.withValues(alpha: 0.5),
                                ),
                                border: InputBorder.none,
                                suffix: ValueListenableBuilder<TextEditingValue>(
                                  valueListenable: controller.captionController,
                                  builder: (context, value, child) {
                                    final int length = value.text.length;
                                    return Text(
                                      "$length/500",
                                      style: fontStyle.clashDisplayRegular10.textColor(
                                        length > 500
                                            ? const Color(0xFFE57373)
                                            : appColor(context).white.withValues(alpha: 0.6),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: isLoading ? null : () => _submitMediaStatus(context),
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: BoxDecoration(
                              color: isLoading
                                  ? appColor(context).secondary.withValues(alpha: 0.5)
                                  : appColor(context).secondary,
                              shape: BoxShape.circle,
                            ),
                            child: isLoading
                                ? const Padding(
                                    padding: EdgeInsets.all(14.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: appColor(context).white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Premium Glassmorphism Loading / Uploading Overlay
                if (isLoading && isUploading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: appColor(context).black.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: appColor(context).white.withValues(alpha: 0.15),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Beautiful floating icon
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: appColor(context).secondary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isUploading ? Icons.cloud_upload_rounded : Icons.compress_rounded,
                                    color: appColor(context).secondary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Header Text
                                Text(
                                  isUploading ? "Uploading Status" : (isVideo ? "Compressing Video..." : "Processing Media..."),
                                  style: fontStyle.clashDisplayBold16.textColor(
                                    appColor(context).white,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Subtitle / Status info
                                Text(
                                  isUploading
                                      ? "Sending secure status to your contacts"
                                      : "Optimizing quality and file size for faster delivery",
                                  textAlign: TextAlign.center,
                                  style: fontStyle.clashDisplayRegular12.textColor(
                                    appColor(context).white.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                if (isUploading) ...[
                                  // Real-time progress bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 8,
                                      backgroundColor: appColor(context).white.withValues(alpha: 0.1),
                                      valueColor: AlwaysStoppedAnimation<Color>(appColor(context).secondary),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Exact uploading file sizes and percentage
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "${formatBytes(sentBytes)} / ${formatBytes(totalBytes)}",
                                        style: fontStyle.clashDisplayMedium12.textColor(
                                          appColor(context).white.withValues(alpha: 0.8),
                                        ),
                                      ),
                                      Text(
                                        "${(progress * 100).toStringAsFixed(0)}%",
                                        style: fontStyle.clashDisplayBold12.textColor(
                                          appColor(context).secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  // Spinning Loader for compression state
                                  SizedBox(
                                    width: 48,
                                    height: 48,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3.5,
                                      color: appColor(context).secondary,
                                      backgroundColor: appColor(context).white.withValues(alpha: 0.1),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:io';
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

  @override
  Widget build(BuildContext context) {
    return Consumer<StatusController>(
      builder: (context, controller, child) {
        final bool isLoading = controller.isLoading;
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
              ],
            ),
          ),
        );
      },
    );
  }
}

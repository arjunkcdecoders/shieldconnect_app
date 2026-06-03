import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';
import 'package:shieldconnect_app/services/api_services.dart';

class MediaViewerScreen extends StatelessWidget {
  final String url;
  final String type; // 'image' or 'video'
  final String fileName;

  const MediaViewerScreen({
    super.key,
    required this.url,
    required this.type,
    required this.fileName,
  });

  // Future<void> _launchInBrowser(BuildContext context) async {
  //   try {
  //     final absoluteUrl = ApiService.getImageUrl(url);
  //     final Uri uri = Uri.parse(absoluteUrl);
  //     final canLaunch = await canLaunchUrl(uri);
  //     if (!context.mounted) return;
  //     if (canLaunch) {
  //       await launchUrl(uri, mode: LaunchMode.externalApplication);
  //     } else {
  //       ToastHelper.showToast(context, "Could not open external player.");
  //     }
  //   } catch (e) {
  //     if (!context.mounted) return;
  //     ToastHelper.showToast(context, "Error: $e");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          fileName,
          style: fontStyle.clashDisplaySemiBold16.textColor(Colors.white),
        ),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.open_in_browser_rounded, color: Colors.white),
          //   onPressed: () => _launchInBrowser(context),
          //   tooltip: "Open in external browser/player",
          // ),
          DownloadButton(url: url, fileName: fileName),
        ],
      ),
      body: Center(
        child: type == 'image'
            ? InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: ApiService.getImageUrl(url),
                  fit: BoxFit.contain,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.broken_image,
                        color: Colors.grey,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Unable to load image",
                        style: fontStyle.clashDisplayMedium14.textColor(
                          Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : VideoPlayerWidget(url: url),
      ),
    );
  }
}

class DownloadButton extends StatefulWidget {
  final String url;
  final String fileName;

  const DownloadButton({super.key, required this.url, required this.fileName});

  @override
  State<DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<DownloadButton> {
  bool _isDownloading = false;

  Future<void> _downloadFile() async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
    });

    if (mounted) {
      ToastHelper.showToast(context, "Starting download...");
    }

    try {
      final dio = Dio();

      Directory? targetDir;
      if (Platform.isAndroid) {
        targetDir = Directory('/storage/emulated/0/Download');
        if (!await targetDir.exists()) {
          targetDir = await getExternalStorageDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final String finalDir =
          targetDir?.path ?? (await getTemporaryDirectory()).path;
      final String savePath = "$finalDir/${widget.fileName}";
      final absoluteUrl = ApiService.getImageUrl(widget.url);

      await dio.download(absoluteUrl, savePath);

      if (mounted) {
        ToastHelper.showToast(
          context,
          "Successfully downloaded to Downloads folder!",
        );
      }
    } catch (e) {
      debugPrint("Download failed: $e");
      try {
        final cacheDir = await getTemporaryDirectory();
        final String fallbackPath = "${cacheDir.path}/${widget.fileName}";
        final absoluteUrl = ApiService.getImageUrl(widget.url);
        await Dio().download(absoluteUrl, fallbackPath);
        if (mounted) {
          ToastHelper.showToast(context, "Saved to cache: $fallbackPath");
        }
      } catch (ex) {
        if (mounted) {
          ToastHelper.showToast(context, "Download failed: $ex");
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isDownloading
        ? const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          )
        : IconButton(
            icon: const Icon(Icons.file_download_outlined, color: Colors.white),
            onPressed: _downloadFile,
            tooltip: "Download to device",
          );
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String url;

  const VideoPlayerWidget({super.key, required this.url});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }

  Future<void> _initVideoPlayer() async {
    try {
      final absoluteUrl = ApiService.getImageUrl(widget.url);
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(absoluteUrl),
      );
      await _videoController!.initialize();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController!.play();
        _videoController!.setLooping(true);
      }
    } catch (e) {
      debugPrint("Error initializing video player: $e");
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVideoInitialized) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text("Loading video...", style: TextStyle(color: Colors.white70)),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
        Container(
          color: Colors.black.withValues(alpha: 0.8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: appColor(context).secondary,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ValueListenableBuilder(
                    valueListenable: _videoController!,
                    builder: (context, VideoPlayerValue value, child) {
                      final duration = value.position;
                      return Text(
                        _formatDuration(duration),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_videoController!.value.isPlaying) {
                              _videoController!.pause();
                            } else {
                              _videoController!.play();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  Text(
                    _formatDuration(_videoController!.value.duration),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shieldconnect_app/controller/status_controller.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/model/settings_model.dart';
import 'package:shieldconnect_app/utils/toast_helper.dart';
import 'package:shieldconnect_app/model/status_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/notification_screen.dart';
import 'package:shieldconnect_app/view/status_view_screen.dart';
import 'package:shieldconnect_app/view/text_status_creator_screen.dart';
import 'package:shieldconnect_app/view/media_status_preview_screen.dart';
import 'package:shieldconnect_app/controller/notification_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

class StatusScreen extends StatelessWidget {
  const StatusScreen({super.key});

  Future<void> _pickMedia(BuildContext context, bool isVideo) async {
    final ImagePicker picker = ImagePicker();
    try {
      final settings = await SettingsModel.loadActiveSettings();
      if (isVideo) {
        final XFile? file = await picker.pickVideo(source: ImageSource.gallery);
        if (file != null) {
          final int fileSize = await File(file.path).length();
          final int limit = settings.getVideoLimitBytes();
          if (fileSize > limit) {
            if (!context.mounted) return;
            ToastHelper.showWarningDialog(
              context,
              "Video Too Large",
              "Videos uploaded to status cannot exceed ${settings.videoLimit ?? '100 MB'}. Your selected video is ${SettingsModel.formatBytes(fileSize)}."
            );
            return;
          }
          if (!context.mounted) return;
          final controller = context.read<StatusController>();
          controller.clearMediaStatusPreview();
          controller.initVideoPlayer(File(file.path));
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => MediaStatusPreviewScreen(
                file: File(file.path),
                isVideo: true,
              ),
            ),
          ).then((_) {
            if (context.mounted) {
              final statusController = context.read<StatusController>();
              statusController.clearMediaStatusPreview();
              statusController.init();
            }
          });
        }
      } else {
        final XFile? file = await picker.pickImage(source: ImageSource.gallery);
        if (file != null) {
          final int fileSize = await File(file.path).length();
          final int limit = settings.getImageLimitBytes();
          if (fileSize > limit) {
            if (!context.mounted) return;
            ToastHelper.showWarningDialog(
              context,
              "Image Too Large",
              "Images uploaded to status cannot exceed ${settings.imageLimit ?? '10 MB'}. Your selected image is ${SettingsModel.formatBytes(fileSize)}."
            );
            return;
          }
          if (!context.mounted) return;
          final controller = context.read<StatusController>();
          controller.clearMediaStatusPreview();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => MediaStatusPreviewScreen(
                file: File(file.path),
                isVideo: false,
              ),
            ),
          ).then((_) {
            if (context.mounted) {
              final statusController = context.read<StatusController>();
              statusController.clearMediaStatusPreview();
              statusController.init();
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error picking media: $e");
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: appColor(context).grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Create Status",
                style: fontStyle.clashDisplayBold16.textColor(
                  appColor(context).black,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: appColor(
                    context,
                  ).secondary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: appColor(context).secondary,
                  ),
                ),
                title: Text(
                  "Text Status",
                  style: fontStyle.clashDisplaySemiBold14.textColor(
                    appColor(context).black,
                  ),
                ),
                subtitle: Text(
                  "Share what's on your mind",
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).textMediumGrey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(bCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TextStatusCreatorScreen(),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<StatusController>().init();
                    }
                  });
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: appColor(
                    context,
                  ).secondary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.image_outlined,
                    color: appColor(context).secondary,
                  ),
                ),
                title: Text(
                  "Image Status",
                  style: fontStyle.clashDisplaySemiBold14.textColor(
                    appColor(context).black,
                  ),
                ),
                subtitle: Text(
                  "Share a photo from your gallery",
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).textMediumGrey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(bCtx);
                  _pickMedia(context, false);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: appColor(
                    context,
                  ).secondary.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.videocam_outlined,
                    color: appColor(context).secondary,
                  ),
                ),
                title: Text(
                  "Video Status",
                  style: fontStyle.clashDisplaySemiBold14.textColor(
                    appColor(context).black,
                  ),
                ),
                subtitle: Text(
                  "Share a video from your gallery",
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).textMediumGrey,
                  ),
                ),
                onTap: () {
                  Navigator.pop(bCtx);
                  _pickMedia(context, true);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatStatusTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StatusController>(
      builder: (context, controller, child) {
        final profileImgUrl =
            controller.profileImage != null &&
                controller.profileImage!.isNotEmpty
            ? ApiService.getImageUrl(controller.profileImage!)
            : "";

        final bool hasMyStatuses = controller.myStatuses.isNotEmpty;

        final bool myStatusesAllViewed = hasMyStatuses &&
            controller.myStatuses.every((status) =>
                status.viewerIds?.contains(controller.userId) == true);

        // Split othersStatuses into recent vs viewed dynamically
        final List<Map<String, dynamic>> recentUpdates = [];
        final List<Map<String, dynamic>> viewedUpdates = [];

        for (var item in controller.othersStatuses) {
          if (item is Map<String, dynamic>) {
            final List<dynamic> rawStatuses = item['statuses'] ?? [];
            final List<StatusModel> statuses = rawStatuses
                .map((e) => StatusModel.fromJson(e as Map<String, dynamic>))
                .toList();
            statuses.sort((a, b) {
              final aTime =
                  a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final bTime =
                  b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return aTime.compareTo(bTime);
            });

            bool allViewed = false;
            if (statuses.isNotEmpty && controller.userId != null) {
              allViewed = statuses.every((status) {
                return status.viewerIds?.contains(controller.userId) == true;
              });
            }

            if (item['all_viewed'] == true) {
              allViewed = true;
            }

            // Update the item map so both the categorization and individual status list item
            // styling (such as ring segment indicators) reflect the correct state.
            item['all_viewed'] = allViewed;

            if (allViewed) {
              viewedUpdates.add(item);
            } else {
              recentUpdates.add(item);
            }
          }
        }

        return Scaffold(
          backgroundColor: appColor(context).white,
          body: SafeArea(
            child: controller.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: appColor(context).primary,
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      // parent: BouncingScrollPhysics(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Consistent App Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      color: appColor(context).grey100,
                                      image: profileImgUrl.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(profileImgUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: profileImgUrl.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            color: appColor(context).grey400,
                                            size: 24,
                                          )
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: -4,
                                    child: Image.asset(
                                      ImageAssets.tick,
                                      width: 16,
                                      height: 16,
                                    ),
                                  ),
                                ],
                              ),
                              Consumer<NotificationController>(
                                builder:
                                    (context, notificationController, child) {
                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const NotificationScreen(),
                                            ),
                                          );
                                        },
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: appColor(
                                                  context,
                                                ).silver.withValues(alpha: 0.1),
                                              ),
                                              child: Center(
                                                child: Image.asset(
                                                  ImageAssets.notification,
                                                  width: 22,
                                                  height: 22,
                                                  color: appColor(
                                                    context,
                                                  ).secondary,
                                                ),
                                              ),
                                            ),
                                            if (notificationController
                                                    .unreadCount >
                                                0)
                                              Positioned(
                                                right: -2,
                                                top: -2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: appColor(
                                                      context,
                                                    ).secondary,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: appColor(
                                                        context,
                                                      ).white,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 18,
                                                        minHeight: 18,
                                                      ),
                                                  child: Center(
                                                    child: Text(
                                                      notificationController
                                                                  .unreadCount >
                                                              9
                                                          ? '9+'
                                                          : notificationController
                                                                .unreadCount
                                                                .toString(),
                                                      style: fontStyle
                                                          .clashDisplayBold10
                                                          .textColor(
                                                            appColor(
                                                              context,
                                                            ).white,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Screen Title
                          Text(
                            "Status",
                            style: fontStyle.clashDisplayBold30.textColor(
                              appColor(context).black,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // My Status block
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              if (hasMyStatuses) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StatusViewScreen(
                                      statuses: controller.myStatuses,
                                      user: UserModel(
                                        id: controller.userId,
                                        name: "My status",
                                        avatar: controller.profileImage,
                                      ),
                                    ),
                                  ),
                                ).then((_) {
                                  controller.init();
                                });
                              } else {
                                _showAddOptions(context);
                              }
                            },
                            child: Row(
                              children: [
                                if (hasMyStatuses)
                                  SizedBox(
                                    width: 62,
                                    height: 62,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned.fill(
                                          child: CustomPaint(
                                            painter: StatusRingPainter(
                                              segments:
                                                  controller.myStatuses.length,
                                              color: !myStatusesAllViewed
                                                  ? appColor(context).secondary
                                                  : appColor(context).grey300,
                                            ),
                                          ),
                                        ),
                                        _buildStatusThumbnail(
                                          context,
                                          controller.myStatuses.last,
                                          26,
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                       CircleAvatar(
                                        radius: 28,
                                        backgroundColor: appColor(context).grey100,
                                        backgroundImage: profileImgUrl.isNotEmpty
                                            ? NetworkImage(profileImgUrl)
                                            : null,
                                        child: profileImgUrl.isEmpty
                                            ? Icon(
                                                Icons.person,
                                                color: appColor(context).grey400,
                                                size: 28,
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: appColor(context).secondary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: appColor(context).white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.add,
                                            color: appColor(context).white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "My status",
                                        style: fontStyle.clashDisplaySemiBold16
                                            .textColor(appColor(context).black),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        hasMyStatuses
                                            ? "Tap to View Status"
                                            : "Tap to add status update",
                                        style: fontStyle.clashDisplayRegular12
                                            .textColor(
                                              appColor(context).textMediumGrey,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (hasMyStatuses) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _showAddOptions(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: appColor(
                                          context,
                                        ).secondary.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.add,
                                        color: appColor(context).secondary,
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // First section: "Recent Updates"
                          if (recentUpdates.isNotEmpty) ...[
                            Text(
                              "Recent Updates",
                              style: fontStyle.clashDisplaySemiBold14.textColor(
                                appColor(context).textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: recentUpdates.length,
                              itemBuilder: (context, index) {
                                return _buildStatusItem(
                                  context,
                                  recentUpdates[index],
                                  controller,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Second section: "Viewed Updates"
                          if (viewedUpdates.isNotEmpty) ...[
                            Text(
                              "Viewed Updates",
                              style: fontStyle.clashDisplaySemiBold14.textColor(
                                appColor(context).textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: viewedUpdates.length,
                              itemBuilder: (context, index) {
                                return _buildStatusItem(
                                  context,
                                  viewedUpdates[index],
                                  controller,
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(
    BuildContext context,
    Map<String, dynamic> item,
    StatusController controller,
  ) {
    final userMap = item['user'] ?? {};
    final bool allViewed = item['all_viewed'] ?? false;
    final List<dynamic> rawStatuses = item['statuses'] ?? [];
    final List<StatusModel> statuses = rawStatuses
        .map((e) => StatusModel.fromJson(e as Map<String, dynamic>))
        .toList();
    statuses.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });

    final int segments = statuses.length;
    final String name = userMap['name'] ?? 'Unknown';
    final String avatar = userMap['avatar'] ?? '';
    final String formattedAvatar = ApiService.getImageUrl(avatar);

    String timeText = '';
    if (statuses.isNotEmpty) {
      timeText = _formatStatusTime(statuses.last.createdAt);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (statuses.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatusViewScreen(
                  statuses: statuses,
                  user: UserModel.fromJson(userMap),
                ),
              ),
            ).then((_) {
              controller.init();
            });
          }
        },
        child: Row(
          children: [
            // Custom Segmented Ring surrounding Avatar
            SizedBox(
              width: 62,
              height: 62,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: StatusRingPainter(
                        segments: segments,
                        color: !allViewed
                            ? appColor(context).secondary
                            : appColor(context).grey300,
                      ),
                    ),
                  ),
                  statuses.isNotEmpty
                      ? _buildStatusThumbnail(context, statuses.last, 26)
                      : CircleAvatar(
                          radius: 26,
                          backgroundColor: appColor(context).grey100,
                          backgroundImage: formattedAvatar.isNotEmpty
                              ? NetworkImage(formattedAvatar)
                              : null,
                          child: formattedAvatar.isEmpty
                              ? Icon(
                                  Icons.person,
                                  color: appColor(context).grey400,
                                  size: 26,
                                )
                              : null,
                        ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Text descriptors
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: fontStyle.clashDisplaySemiBold16.textColor(
                      appColor(context).black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeText,
                    style: fontStyle.clashDisplayRegular12.textColor(
                      appColor(context).textMediumGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusThumbnail(
    BuildContext context,
    StatusModel latestStatus,
    double radius,
  ) {
    if (latestStatus.contentType == 'text') {
      final String hex = latestStatus.backgroundColor ?? "#8661D6";
      final Color bgColor = Color(int.parse(hex.replaceFirst('#', '0xFF')));
      final String firstLetter =
          (latestStatus.content != null && latestStatus.content!.isNotEmpty)
          ? latestStatus.content![0].toUpperCase()
          : '?';

      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          firstLetter,
          style: fontStyle.clashDisplayBold18.textColor(Colors.white),
        ),
      );
    } else if (latestStatus.contentType == 'video') {
      final String videoUrl = ApiService.getImageUrl(latestStatus.content);
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        clipBehavior: Clip.hardEdge,
        child: VideoThumbnailWidget(videoUrl: videoUrl),
      );
    } else {
      final String imageUrl = ApiService.getImageUrl(latestStatus.content);
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
        ),
        clipBehavior: Clip.hardEdge,
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: Colors.white,
              ),
            ),
          ),
          errorWidget: (context, url, error) =>
              const Icon(Icons.image, color: Colors.white, size: 16),
        ),
      );
    }
  }
}

/// Mathematical Status Segment Painter defining dynamic high-fidelity updates arcs.
class StatusRingPainter extends CustomPainter {
  final int segments;
  final Color color;

  StatusRingPainter({required this.segments, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 2.5;
    final Rect rect =
        const Offset(strokeWidth / 2, strokeWidth / 2) &
        Size(size.width - strokeWidth, size.height - strokeWidth);

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (segments <= 1) {
      canvas.drawArc(rect, 0, 2 * pi, false, paint);
      return;
    }

    // Spacing in radians between status rings
    const double spacing = 0.25;
    final double availableAngle = (2 * pi) - (spacing * segments);
    final double arcLength = availableAngle / segments;

    double currentAngle = -pi / 2; // Orient upwards at 12 o'clock position

    for (int i = 0; i < segments; i++) {
      canvas.drawArc(rect, currentAngle, arcLength, false, paint);
      currentAngle += arcLength + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant StatusRingPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.color != color;
  }
}

class VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  const VideoThumbnailWidget({super.key, required this.videoUrl});

  @override
  State<VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<VideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
          })
          .catchError((e) {
            debugPrint("Error initializing thumbnail video: $e");
          });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _controller != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }
    return const Center(
      child: SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white),
      ),
    );
  }
}

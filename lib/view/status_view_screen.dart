import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/status_controller.dart';
import 'package:shieldconnect_app/model/status_model.dart';
import 'package:shieldconnect_app/model/user_model.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class StatusViewScreen extends StatelessWidget {
  final List<StatusModel> statuses;
  final UserModel user;

  const StatusViewScreen({
    super.key,
    required this.statuses,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return _StatusViewBody(statuses: statuses, user: user);
  }
}

class _StatusViewBody extends StatefulWidget {
  final List<StatusModel> statuses;
  final UserModel user;

  const _StatusViewBody({required this.statuses, required this.user});

  @override
  State<_StatusViewBody> createState() => _StatusViewBodyState();
}

class _StatusViewBodyState extends State<_StatusViewBody>
    with TickerProviderStateMixin {
  late List<StatusModel> _statuses;
  int _currentIndex = 0;
  AnimationController? _animationController;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  final Map<String, List<dynamic>> _statusViewersMap = {};
  bool _isCaptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _statuses = List.from(widget.statuses);
    _statuses.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });
    if (_statuses.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showStory(_currentIndex);
          _preloadViewers();
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  }

  void _preloadViewers() {
    final controller = context.read<StatusController>();
    for (var status in _statuses) {
      if (status.id != null) {
        // 1. Check if controller already has them cached
        if (controller.viewersCache.containsKey(status.id!)) {
          final viewers = controller.viewersCache[status.id!];
          if (viewers != null) {
            _statusViewersMap[status.id!] = viewers;
            _precacheViewerImages(viewers);
          }
        }

        // 2. Also populate from status.viewers as fallback
        if (!_statusViewersMap.containsKey(status.id!) &&
            status.viewers != null &&
            status.viewers!.isNotEmpty) {
          _statusViewersMap[status.id!] = status.viewers!.map((user) {
            return {
              '_id': user.id,
              'name': user.name,
              'avatar': user.avatar,
              'bio': user.bio,
              'viewed_at': null,
            };
          }).toList();
          _precacheViewerImages(_statusViewersMap[status.id!]!);
        }

        // 3. Always fetch from API to ensure fresh/real-time state, and update both local map and controller cache
        controller
            .fetchStatusViewers(status.id!)
            .then((viewers) {
              if (mounted) {
                setState(() {
                  _statusViewersMap[status.id!] = viewers;
                });
                controller.viewersCache[status.id!] = viewers;
                _precacheViewerImages(viewers);
              }
            })
            .catchError((e) {
              debugPrint(
                "Error preloading viewers for status ${status.id}: $e",
              );
            });
      }
    }
  }

  void _precacheViewerImages(List<dynamic> viewers) {
    for (var viewer in viewers) {
      if (viewer is Map<String, dynamic>) {
        final String avatarUrl = ApiService.getImageUrl(viewer['avatar']);
        if (avatarUrl.isNotEmpty) {
          precacheImage(
            CachedNetworkImageProvider(avatarUrl),
            context,
          ).catchError((e) {
            debugPrint("Error precaching viewer avatar: $e");
          });
        }
      }
    }
  }

  Widget _buildViewerAvatars(String? statusId) {
    if (statusId == null) return const SizedBox.shrink();
    final List<dynamic> rawList = _statusViewersMap[statusId] ?? [];
    if (rawList.isEmpty) return const SizedBox.shrink();

    final controller = context.read<StatusController>();
    final viewersList = rawList.where((viewer) {
      final Map<String, dynamic> vMap = viewer is Map<String, dynamic>
          ? viewer
          : {};
      final String? viewerId = vMap['_id'] ?? vMap['id'];
      return viewerId != controller.userId;
    }).toList();

    if (viewersList.isEmpty) return const SizedBox.shrink();

    return Row(
      children: viewersList.take(5).map((viewer) {
        final Map<String, dynamic> vMap = viewer is Map<String, dynamic>
            ? viewer
            : {};
        final String avatarUrl = ApiService.getImageUrl(vMap['avatar']);
        return Align(
          widthFactor: 0.65,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 11,
              backgroundImage: avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(avatarUrl) as ImageProvider
                  : const AssetImage(ImageAssets.userAvatar),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _showStory(int index) {
    _isCaptionExpanded = false;
    // Clean up previous video player
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _isVideoInitialized = false;

    // Clean up animation controller
    _animationController?.dispose();
    _animationController = null;

    final currentStatus = _statuses[index];

    // Trigger update that I viewed others status
    final controller = context.read<StatusController>();
    if (currentStatus.id != null) {
      controller.viewStatus(currentStatus.id!);
    }

    if (currentStatus.contentType == 'video') {
      final String videoUrl = ApiService.getImageUrl(currentStatus.content);
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(videoUrl))
            ..initialize()
                .then((_) {
                  if (!mounted) return;
                  setState(() {
                    _isVideoInitialized = true;
                  });
                  _videoPlayerController!.play();
                  _animationController = AnimationController(
                    vsync: this,
                    duration: _videoPlayerController!.value.duration,
                  );
                  _setupAnimationListeners();
                  _animationController!.forward();
                })
                .catchError((e) {
                  debugPrint("Error initializing video: $e");
                  _startDefaultTimer();
                });
    } else {
      _startDefaultTimer();
    }
  }

  void _startDefaultTimer() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _setupAnimationListeners();
    _animationController!.forward();
    setState(() {});
  }

  void _setupAnimationListeners() {
    _animationController!.addListener(() {
      setState(() {});
    });
    _animationController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });
  }

  void _nextStory() {
    if (_currentIndex < _statuses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _showStory(_currentIndex);
    } else {
      Navigator.pop(context);
    }
  }

  void _prevStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _showStory(_currentIndex);
    } else {
      _animationController?.forward(from: 0.0);
      _videoPlayerController?.seekTo(Duration.zero);
      _videoPlayerController?.play();
    }
  }

  void _onTapStory(TapUpDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;
    if (dx < screenWidth * 0.3) {
      _prevStory();
    } else {
      _nextStory();
    }
  }

  void _pauseStory() {
    _animationController?.stop(canceled: false);
    _videoPlayerController?.pause();
  }

  void _resumeStory() {
    _animationController?.forward();
    _videoPlayerController?.play();
  }

  Future<void> _deleteCurrentStatus() async {
    final currentStatus = _statuses[_currentIndex];
    final String? statusId = currentStatus.id;
    if (statusId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final controller = context.read<StatusController>();
    final success = await controller.deleteStatus(statusId);

    if (mounted) {
      Navigator.pop(context); // Pop loading dialog
    }

    if (success) {
      if (!mounted) return;
      setState(() {
        _statuses.removeAt(_currentIndex);
        _statusViewersMap.remove(statusId);
      });

      if (_statuses.isEmpty) {
        Navigator.pop(context);
      } else {
        if (_currentIndex >= _statuses.length) {
          _currentIndex = _statuses.length - 1;
        }
        _showStory(_currentIndex);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete status. Please try again.'),
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext bContext) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Delete Status?",
            style: fontStyle.clashDisplayBold18.textColor(
              appColor(context).black,
            ),
          ),
          content: Text(
            "Are you sure you want to delete this status? This action cannot be undone.",
            style: fontStyle.clashDisplayRegular14.textColor(
              appColor(context).grey500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                "Cancel",
                style: fontStyle.clashDisplaySemiBold14.textColor(
                  appColor(context).textMediumGrey,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                "Delete",
                style: fontStyle.clashDisplaySemiBold14.textColor(
                  const Color(0xFFC61D1D),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      if (bContext.mounted) {
        Navigator.pop(bContext); // Dismiss bottom sheet
      }
      await _deleteCurrentStatus();
    }
  }

  Future<void> _showOpenLinkConfirmationDialog(String url) async {
    _pauseStory();

    final bool? shouldOpen = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: appColor(context).secondary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.open_in_new_rounded,
                  color: appColor(context).secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Open Link?",
                  style: fontStyle.clashDisplayBold18.textColor(
                    appColor(context).black,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Are you sure you want to open this link in your web browser?",
                style: fontStyle.clashDisplayRegular14.textColor(
                  appColor(context).grey500,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: appColor(context).grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: appColor(context).grey200,
                    width: 1,
                  ),
                ),
                child: Text(
                  url,
                  style: fontStyle.clashDisplayMedium12.textColor(
                    appColor(context).secondary,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                "Cancel",
                style: fontStyle.clashDisplaySemiBold14.textColor(
                  appColor(context).textMediumGrey,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(dialogContext, true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: appColor(context).secondary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: appColor(
                        context,
                      ).secondary.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  "Open Link",
                  style: fontStyle.clashDisplaySemiBold14.textColor(
                    appColor(context).white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldOpen == true) {
      String formattedUrl = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        formattedUrl = 'https://$url';
      }
      final Uri uri = Uri.parse(formattedUrl);
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Error launching URL: $e');
        try {
          await launchUrl(uri);
        } catch (fallbackError) {
          debugPrint('Fallback launch failed: $fallbackError');
        }
      }
    }

    _resumeStory();
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
    if (_statuses.isEmpty) return const SizedBox.shrink();

    final currentStatus = _statuses[_currentIndex];
    final String userAvatarUrl = ApiService.getImageUrl(widget.user.avatar);
    final String statusTimeText = _formatStatusTime(currentStatus.createdAt);

    // Identify if own status
    final controller = context.read<StatusController>();
    final bool isOwnStatus =
        widget.user.name == "My status" ||
        widget.user.id == controller.userId ||
        currentStatus.userId == controller.userId;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: _onTapStory,
        onLongPress: _pauseStory,
        onLongPressEnd: (_) => _resumeStory(),
        child: Stack(
          children: [
            // 1. Center Story Render Content
            Positioned.fill(
              child: _buildStoryContent(currentStatus, isOwnStatus),
            ),

            // 2. Depth Vignette Gradients for High Text Contrast
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.0, 0.15, 0.85, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. SafeArea Interactive Overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Segmented Progress Indicator
                    _buildProgressBar(),
                    const SizedBox(height: 16),

                    // Header: Submitter contextual details and actions
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 4),
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: userAvatarUrl.isNotEmpty
                              ? CachedNetworkImageProvider(userAvatarUrl)
                                    as ImageProvider
                              : const AssetImage(ImageAssets.userAvatar),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    widget.user.name ?? 'Unknown',
                                    style: fontStyle.clashDisplaySemiBold14
                                        .textColor(Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    statusTimeText,
                                    style: fontStyle.clashDisplayRegular12
                                        .textColor(
                                          Colors.white.withValues(alpha: 0.8),
                                        ),
                                  ),
                                ],
                              ),
                              if (widget.user.email != null &&
                                  widget.user.email!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.user.email!,
                                  style: fontStyle.clashDisplayMedium10
                                      .textColor(
                                        Colors.white.withValues(alpha: 0.6),
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Centered Caption Rendering
                    if (currentStatus.contentType != 'text' &&
                        currentStatus.caption != null &&
                        currentStatus.caption!.isNotEmpty) ...[
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          margin: const EdgeInsets.symmetric(horizontal: 24.0),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LinkifiedText(
                                text:
                                    (currentStatus.caption!.length > 90 &&
                                        !_isCaptionExpanded)
                                    ? "${currentStatus.caption!.substring(0, 90)}..."
                                    : currentStatus.caption!,
                                textAlign: TextAlign.center,
                                style: fontStyle.clashDisplayMedium14.textColor(
                                  Colors.white,
                                ),
                                onLinkTapped: _showOpenLinkConfirmationDialog,
                              ),
                              if (currentStatus.caption!.length > 90) ...[
                                const SizedBox(height: 6),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isCaptionExpanded = !_isCaptionExpanded;
                                      if (_isCaptionExpanded) {
                                        _pauseStory();
                                      } else {
                                        _resumeStory();
                                      }
                                    });
                                  },
                                  child: Text(
                                    _isCaptionExpanded
                                        ? "Read less"
                                        : "Read more",
                                    style: fontStyle.clashDisplaySemiBold12
                                        .textColor(appColor(context).secondary),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Bottom Viewer Metrics Layout (ONLY FOR OWN STATUSES)
                    if (isOwnStatus) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showViewsBottomSheet(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.remove_red_eye_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "${(currentStatus.viewerIds ?? []).where((id) => id != controller.userId).length} Views",
                                        style: fontStyle.clashDisplayBold12
                                            .textColor(Colors.white),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildViewerAvatars(currentStatus.id),
                                ],
                              ),
                            ),
                          ),
                          // IconButton(
                          //   onPressed: () => _showViewsBottomSheet(context),
                          //   icon: const Icon(
                          //     Icons.more_vert,
                          //     color: Colors.white,
                          //     size: 24,
                          //   ),
                          //   padding: EdgeInsets.zero,
                          //   constraints: const BoxConstraints(),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_statuses.length, (index) {
        double value = 0.0;
        if (index < _currentIndex) {
          value = 1.0;
        } else if (index > _currentIndex) {
          value = 0.0;
        } else {
          value = _animationController?.value ?? 0.0;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 3,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStoryContent(StatusModel status, bool isOwnStatus) {
    if (status.contentType == 'text') {
      final String hex = status.backgroundColor ?? "#8661D6";
      final Color bgColor = Color(int.parse(hex.replaceFirst('#', '0xFF')));
      final String textContent = status.content ?? '';

      // Calculate a highly optimized dynamic font size based on text length
      double fontSize = 32.0;
      if (textContent.length > 250) {
        fontSize = 16.0;
      } else if (textContent.length > 150) {
        fontSize = 20.0;
      } else if (textContent.length > 80) {
        fontSize = 26.0;
      }

      return Container(
        color: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 100.0),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: LinkifiedText(
              text: textContent,
              textAlign: TextAlign.center,
              style: clashDisplay(
                fontsize: fontSize,
                fontWeight: FontWeight.w600,
              ).textColor(Colors.white),
              onLinkTapped: _showOpenLinkConfirmationDialog,
            ),
          ),
        ),
      );
    } else if (status.contentType == 'video') {
      final double bottomPadding =
          (status.caption != null && status.caption!.isNotEmpty)
          ? (isOwnStatus ? 150.0 : 85.0)
          : (isOwnStatus ? 70.0 : 0.0);
      return Container(
        color: Colors.black,
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Center(
          child: _isVideoInitialized && _videoPlayerController != null
              ? AspectRatio(
                  aspectRatio: _videoPlayerController!.value.aspectRatio,
                  child: VideoPlayer(_videoPlayerController!),
                )
              : const CircularProgressIndicator(color: Colors.white),
        ),
      );
    } else {
      final String imageUrl = ApiService.getImageUrl(status.content);
      final double bottomPadding =
          (status.caption != null && status.caption!.isNotEmpty)
          ? (isOwnStatus ? 150.0 : 85.0)
          : (isOwnStatus ? 70.0 : 0.0);
      return Container(
        color: Colors.black,
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const CircularProgressIndicator(color: Colors.white),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFF3A4D28),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  color: Colors.white.withValues(alpha: 0.38),
                  size: 40,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  void _showViewsBottomSheet(BuildContext context) {
    _pauseStory();
    final currentStatus = _statuses[_currentIndex];
    final String? statusId = currentStatus.id;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext bContext) {
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.65,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (_, ScrollController scrollController) {
              return FutureBuilder<List<dynamic>>(
                future: statusId != null
                    ? (_statusViewersMap[statusId] != null
                          ? Future.value(_statusViewersMap[statusId]!)
                          : context
                                .read<StatusController>()
                                .fetchStatusViewers(statusId)
                                .then((val) {
                                  if (mounted) {
                                    setState(() {
                                      _statusViewersMap[statusId] = val;
                                    });
                                  }
                                  return val;
                                }))
                    : Future.value([]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final List<dynamic> rawViewers = snapshot.data ?? [];
                  final controller = context.read<StatusController>();
                  final viewers = rawViewers.where((viewer) {
                    final Map<String, dynamic> vMap =
                        viewer is Map<String, dynamic> ? viewer : {};
                    final String? viewerId = vMap['_id'] ?? vMap['id'];
                    return viewerId != controller.userId;
                  }).toList();
                  final int viewersCount = viewers.length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        Center(
                          child: Container(
                            width: 38,
                            height: 4,
                            decoration: BoxDecoration(
                              color: appColor(context).grey300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            "Views",
                            style: fontStyle.clashDisplayBold14.textColor(
                              appColor(context).black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: appColor(context).black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$viewersCount Views",
                                  style: fontStyle.clashDisplaySemiBold14
                                      .textColor(appColor(context).black),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () =>
                                  _showDeleteConfirmationDialog(bContext),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                color: appColor(context).black,
                                size: 22,
                              ),
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: appColor(context).grey100,
                          height: 1,
                          thickness: 1.2,
                        ),
                        const SizedBox(height: 18),
                        if (viewers.isEmpty)
                          Expanded(
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: appColor(context).grey300,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No views yet",
                                    style: fontStyle.clashDisplaySemiBold16
                                        .textColor(
                                          appColor(context).textMediumGrey,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: ListView.builder(
                              controller: scrollController,
                              physics: const BouncingScrollPhysics(),
                              itemCount: viewers.length,
                              itemBuilder: (context, index) {
                                return _buildViewerItem(
                                  context,
                                  viewers[index] as Map<String, dynamic>,
                                  index,
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    ).then((_) {
      _resumeStory();
    });
  }

  Widget _buildViewerItem(
    BuildContext context,
    Map<String, dynamic> viewer,
    int index,
  ) {
    final String avatarUrl = ApiService.getImageUrl(viewer['avatar']);

    // Parse and format viewed_at timestamp dynamically
    String timeText = '';
    final String? viewedAtStr = viewer['viewed_at'];
    if (viewedAtStr != null) {
      final parsed = DateTime.tryParse(viewedAtStr);
      if (parsed != null) {
        timeText = DateFormat('hh:mm a').format(parsed.toLocal());
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: avatarUrl.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl) as ImageProvider
                    : const AssetImage(ImageAssets.userAvatar),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewer['name'] ?? 'Unknown',
                  style: fontStyle.clashDisplaySemiBold16.textColor(
                    appColor(context).black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeText.isNotEmpty
                      ? timeText
                      : (viewer['bio'] ?? 'Available'),
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).grey400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class LinkifiedText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final ValueChanged<String>? onLinkTapped;

  const LinkifiedText({
    super.key,
    required this.text,
    required this.style,
    this.textAlign = TextAlign.center,
    this.onLinkTapped,
  });

  @override
  State<LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    String formattedUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      formattedUrl = 'https://$url';
    }
    final Uri uri = Uri.parse(formattedUrl);
    try {
      // Direct launch bypasses package visibility constraints on newer Android versions
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching URL directly: $e');
      try {
        // Fallback launch
        await launchUrl(uri);
      } catch (fallbackError) {
        debugPrint('Fallback launch failed: $fallbackError');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clear previous recognizers on rebuild to prevent leak/accumulation
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();

    final RegExp urlRegex = RegExp(
      r'((https?:\/\/|www\.)[^\s]+)',
      caseSensitive: false,
    );

    final List<InlineSpan> spans = [];
    int start = 0;

    for (final match in urlRegex.allMatches(widget.text)) {
      if (match.start > start) {
        spans.add(
          TextSpan(
            text: widget.text.substring(start, match.start),
            style: widget.style,
          ),
        );
      }

      final String url = match.group(0)!;

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () {
              if (widget.onLinkTapped != null) {
                widget.onLinkTapped!(url);
              } else {
                _launchURL(url);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: 0.3,
                ), // Glassmorphic dark covering
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, color: Color(0xFF5EADFF), size: 16),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      url,
                      overflow: TextOverflow.ellipsis,
                      style: widget.style.copyWith(
                        color: const Color(0xFF5EADFF),
                        fontSize: widget.style.fontSize != null
                            ? widget.style.fontSize! * 0.9
                            : 14.0,
                        decoration: TextDecoration.underline,
                        decorationColor: const Color(0xFF5EADFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      start = match.end;
    }

    if (start < widget.text.length) {
      spans.add(
        TextSpan(text: widget.text.substring(start), style: widget.style),
      );
    }

    return Text.rich(TextSpan(children: spans), textAlign: widget.textAlign);
  }
}

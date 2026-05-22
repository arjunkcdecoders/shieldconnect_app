import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/services/api_services.dart';

class VoiceMessageBubble extends StatefulWidget {
  final String? url;
  final bool isOutgoing;
  final String? avatarUrl;
  final String time;
  final bool isForwarded;

  const VoiceMessageBubble({
    super.key,
    required this.url,
    required this.isOutgoing,
    this.avatarUrl,
    required this.time,
    this.isForwarded = false,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() {
          _duration = newDuration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() {
          _position = newPosition;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (widget.url == null || widget.url!.isEmpty) return;
    try {
      final absoluteUrl = ApiService.getImageUrl(widget.url);
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(absoluteUrl));
      }
    } catch (e) {
      debugPrint("AudioPlayer error: $e");
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final bubbleColor = widget.isOutgoing
        ? appColor(context).secondary
        : appColor(context).grey100;

    final subtitleColor = Colors.white60;

    Widget buildAvatar() {
      final String resolvedAvatar = widget.avatarUrl ?? '';
      return Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 18,
            // backgroundColor: Colors.grey.shade700,
            backgroundImage: resolvedAvatar.isNotEmpty
                ? CachedNetworkImageProvider(
                    ApiService.getImageUrl(resolvedAvatar),
                  )
                : null,
            child: resolvedAvatar.isEmpty
                ? Icon(Icons.person, color: appColor(context).white, size: 20)
                : null,
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mic, color: Color(0xFF4FC3F7), size: 10),
          ),
        ],
      );
    }

    Widget buildControlsRow() {
      double progress = 0.0;
      if (_duration.inMilliseconds > 0) {
        progress = _position.inMilliseconds / _duration.inMilliseconds;
      }
      if (progress > 1.0) progress = 1.0;

      final List<double> waveHeights = [
        8.0,
        14.0,
        20.0,
        12.0,
        16.0,
        10.0,
        14.0,
        20.0,
        12.0,
        16.0,
        10.0,
        14.0,
        8.0,
        12.0,
        10.0,
      ];

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: widget.isOutgoing
                  ? appColor(context).white
                  : appColor(context).black,
              size: 28,
            ),
            onPressed: _togglePlay,
          ),
          const SizedBox(width: 4),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.isOutgoing
                  ? appColor(context).white
                  : appColor(context).black,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(waveHeights.length, (index) {
              final h = waveHeights[index];
              final bool isActive = (index / waveHeights.length) <= progress;
              return Container(
                width: 2,
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? widget.isOutgoing
                            ? appColor(context).white
                            : appColor(context).black
                      : Colors.white24,
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: widget.isOutgoing
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!widget.isOutgoing) ...[const SizedBox(width: 8)],
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topRight: const Radius.circular(20),
              bottomRight: const Radius.circular(20),
              bottomLeft: const Radius.circular(20),
              topLeft: widget.isOutgoing
                  ? const Radius.circular(20)
                  : const Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isForwarded) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      scaleX: -1,
                      child: Icon(
                        Icons.reply_rounded,
                        size: 13,
                        color: widget.isOutgoing
                            ? appColor(context).white.withValues(alpha: 0.7)
                            : appColor(context).secondary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Forwarded",
                      style: fontStyle.clashDisplayRegular10.italic().textColor(
                        widget.isOutgoing
                            ? appColor(context).white.withValues(alpha: 0.7)
                            : appColor(context).secondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.isOutgoing) ...[
                    buildAvatar(),
                    const SizedBox(width: 8),
                    buildControlsRow(),
                  ] else ...[
                    buildControlsRow(),
                    const SizedBox(width: 8),
                    buildAvatar(),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 170,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(
                        _position.inMilliseconds > 0 ? _position : _duration,
                      ),
                      style: fontStyle.clashDisplayMedium10.textColor(
                        subtitleColor,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          widget.time,
                          style: fontStyle.clashDisplayMedium10.textColor(
                            subtitleColor,
                          ),
                        ),
                        // if (widget.isOutgoing) ...[
                        //   const SizedBox(width: 4),
                        //   const Icon(
                        //     Icons.done_all,
                        //     color: Color(0xFF4FC3F7),
                        //     size: 14,
                        //   ),
                        // ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (widget.isOutgoing) ...[const SizedBox(width: 8)],
      ],
    );
  }
}

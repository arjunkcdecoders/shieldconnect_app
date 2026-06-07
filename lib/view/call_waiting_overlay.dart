import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';

class CallWaitingOverlay extends StatelessWidget {
  final Map<String, dynamic> waitingCall;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const CallWaitingOverlay({
    super.key,
    required this.waitingCall,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final String callerName = waitingCall['receiverName'] ?? 'User';
    final String? avatarUrl = waitingCall['receiverAvatar'];
    final bool isVideo = waitingCall['isVideo'] == true;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: (avatarUrl != null && avatarUrl.isNotEmpty)
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(26),
                        child: CachedNetworkImage(
                          imageUrl: ApiService.getImageUrl(avatarUrl),
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white24,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            color: Colors.white70,
                            size: 24,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white70,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 14),
              // Call Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      callerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: fontStyle.clashDisplayBold14.textColor(Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isVideo ? Icons.videocam : Icons.phone,
                          color: appColor(context).secondary,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "Incoming ${isVideo ? 'Video' : 'Voice'} Call...",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: fontStyle.clashDisplayRegular12.textColor(
                              Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Decline Button
                  GestureDetector(
                    onTap: onDecline,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD32F2F),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Accept Button
                  GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isVideo ? Icons.videocam : Icons.phone,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

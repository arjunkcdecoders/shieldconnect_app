import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class StatusViewScreen extends StatelessWidget {
  const StatusViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).black,
      body: Stack(
        children: [
          // 1. Immersive Full Screen Foliage Background
          Positioned.fill(
            child: Image.network(
              "https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?q=80&w=1000",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF3A4D28),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: appColor(context).white38,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Depth Vignette Gradients for High Text Contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    appColor(context).black.withValues(alpha: 0.6),
                    appColor(context).transparent,
                    appColor(context).transparent,
                    appColor(context).black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.0, 0.15, 0.85, 1.0],
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
                  // Dynamic Progress Indicator at top boundary
                  Container(
                    height: 3,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: appColor(context).white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header: Submitter contextual details and actions
                  Row(
                    children: [
                      // Back and dismiss click interaction
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.chevron_left,
                          color: appColor(context).white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage(ImageAssets.maisieAvatar),
                      ),
                      const SizedBox(width: 12),

                      // User Details Alignment
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
                                  "_Angelina_Gomez_",
                                  style: fontStyle.clashDisplaySemiBold14
                                      .textColor(appColor(context).white),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "52 m ago",
                                  style: fontStyle.clashDisplayRegular12
                                      .textColor(
                                        appColor(context).white.withValues(alpha: 0.8),
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "angelina@gmail.com",
                              style: fontStyle.clashDisplayMedium10.textColor(
                                appColor(context).white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Bottom Viewer Metrics Layout
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Wrapped in GestureDetector to open viewer bottom sheet
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showViewsBottomSheet(context),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // View count header
                              Row(
                                children: [
                                  Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: appColor(context).white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "112 Views",
                                    style: fontStyle.clashDisplayBold12.textColor(
                                      appColor(context).white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Overlapping user viewer stack
                              Row(
                                children: List.generate(5, (index) {
                                  return Align(
                                    widthFactor: 0.65,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: appColor(context).white,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const CircleAvatar(
                                        radius: 11,
                                        backgroundImage: AssetImage(
                                          ImageAssets.userAvatar,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Actions Trigger
                      IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.more_vert,
                          color: appColor(context).white,
                          size: 24,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the interactive Views list bottom modal matching your mockup
  void _showViewsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: appColor(context).white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext bContext) {
        final List<Map<String, dynamic>> viewers = List.generate(
          12,
          (index) => {
            "name": "Maisie williams",
            "time": "10:35 am",
            "hasHeart": index == 0 || index == 2 || index == 4 || index >= 5,
          },
        );

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, ScrollController scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // 1. Drag Handle
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

                  // 2. Centralized Head Title
                  Center(
                    child: Text(
                      "Views",
                      style: fontStyle.clashDisplayBold14.textColor(
                        appColor(context).black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. Detailed Metrics Bar (Eye icon + count | Delete icon)
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
                            "112 Views",
                            style: fontStyle.clashDisplaySemiBold14.textColor(
                              appColor(context).black,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () {},
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

                  // 4. Dynamic Roster List
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: viewers.length,
                      itemBuilder: (context, index) {
                        return _buildViewerItem(context, viewers[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Visual composition of single viewer item matching mockup design
  Widget _buildViewerItem(BuildContext context, Map<String, dynamic> viewer) {
    final bool hasHeart = viewer["hasHeart"] ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Row(
        children: [
          // User circular avatar stacked with optional tiny heart badge
          Stack(
            alignment: Alignment.bottomRight,
            clipBehavior: Clip.none,
            children: [
              const CircleAvatar(
                radius: 26,
                backgroundImage: AssetImage(ImageAssets.maisieAvatar),
              ),
              if (hasHeart)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: appColor(context).white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFFC61D1D), // A premium deep crimson red
                      size: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),

          // Name & Timing descriptors
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  viewer["name"],
                  style: fontStyle.clashDisplaySemiBold16.textColor(
                    appColor(context).black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  viewer["time"],
                  style: fontStyle.clashDisplayRegular12.textColor(
                    appColor(context).grey400,
                  ),
                ),
              ],
            ),
          ),

          // Action vertical more trigger
          IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.more_vert_rounded,
              color: appColor(context).black87,
              size: 22,
            ),
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

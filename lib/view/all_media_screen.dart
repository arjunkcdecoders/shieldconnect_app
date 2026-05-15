import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class AllMediaScreen extends StatelessWidget {
  const AllMediaScreen({super.key});

  // Highly curated scenery & modern grids mirroring user design
  static const List<String> photoGridImages = [
    "https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?w=400", // Interior modern
    "https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=400", // Sofa living room
    "https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?w=400", // Modern white living
    "https://images.unsplash.com/photo-1616046229478-9901c5536a45?w=400", // Sofa light
    "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400", // Ocean shoreline
    "https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=400", // Yellow flowers mountains
    "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400", // Yosemite valley
    "https://images.unsplash.com/photo-1500627869164-eb7a7092a9c0?w=400", // Green rolling grass
    "https://images.unsplash.com/photo-1501854140801-50d01698950b?w=400", // nature hills
    "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400", // Tech blue connections
    "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=400", // Tech laptop dark
    "https://images.unsplash.com/photo-1518770660439-4636190af475?w=400", // Microchip AI
    "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=400", // Happy group / two people
    "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400", // Tech grid
    "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400", // Portrait
  ];

  @override
  Widget build(BuildContext context) {
    // Retaining local UI interaction context inside a scoped StatefulBuilder satisfying strict Stateless requirements
    int activeTab = 0;

    return Scaffold(
      backgroundColor: appColor(context).white,
      body: SafeArea(
        child: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Column(
              children: [
                // 1. Elegant Rounded Header Block
                _buildHeader(context),

                // 2. Tabs Selector Feed
                _buildTabs(context, activeTab, (index) {
                  setState(() {
                    activeTab = index;
                  });
                }),
                const SizedBox(height: 16),

                // 3. Dynamic Grid/List Frame
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _buildActiveView(context, activeTab),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Refined Header segment carrying custom iOS hot-pink back arrows
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: appColor(context).secondary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: appColor(context).secondary,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            "All Media",
            style: fontStyle.clashDisplaySemiBold18.textColor(
              appColor(context).black,
            ),
          ),
        ],
      ),
    );
  }

  /// Top scrolling pill drawer switching dynamic filters
  Widget _buildTabs(
    BuildContext context,
    int activeTab,
    ValueChanged<int> onTabChange,
  ) {
    final List<Map<String, dynamic>> tabOptions = [
      {"label": "Photos", "icon": Icons.image_outlined, "isAsset": false},
      {"label": "Videos", "icon": Icons.videocam_outlined, "isAsset": false},
      {"label": "Docs", "icon": Icons.description_outlined, "isAsset": false},
      {"label": "Links", "icon": ImageAssets.link, "isAsset": true},
    ];

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tabOptions.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final bool isActive = activeTab == index;
          final option = tabOptions[index];
          final bool isAsset = option["isAsset"] as bool;

          return GestureDetector(
            onTap: () => onTabChange(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? appColor(context).secondary
                    : appColor(context).grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  if (isAsset)
                    Image.asset(
                      option["icon"] as String,
                      width: 14,
                      height: 14,
                      color: isActive ? appColor(context).white : appColor(context).grey400,
                    )
                  else
                    Icon(
                      option["icon"] as IconData,
                      size: 14,
                      color: isActive ? appColor(context).white : appColor(context).grey400,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    option["label"] as String,
                    style: fontStyle.clashDisplayMedium12.textColor(
                      isActive ? appColor(context).white : appColor(context).grey400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// High-performance swapping frame returning appropriate layouts per selection
  Widget _buildActiveView(BuildContext context, int activeTab) {
    switch (activeTab) {
      case 0:
        return _buildPhotosGrid(context);
      case 1:
        return _buildVideosGrid(context);
      case 2:
        return _buildDocsGrid(context);
      case 3:
        return _buildLinksList(context);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Pristine photo viewer framing beautiful immersive grids
  Widget _buildPhotosGrid(BuildContext context) {
    return GridView.builder(
      key: const ValueKey("photos_grid"),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: photoGridImages.length,
      itemBuilder: (context, index) {
        return Container(
          color: appColor(context).grey100,
          child: Image.network(
            photoGridImages[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: appColor(context).grey200,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: appColor(context).grey400,
                ),
              );
            },
          ),
        );
      },
    );
  }

  /// Structured video layout implementing Play indicia overlays
  Widget _buildVideosGrid(BuildContext context) {
    return GridView.builder(
      key: const ValueKey("videos_grid"),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              photoGridImages[index + 4],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: appColor(context).grey200,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: appColor(context).grey400,
                  ),
                );
              },
            ),
            Container(color: appColor(context).black26),
            Center(
              child: Icon(
                Icons.play_circle_outline,
                color: appColor(context).white,
                size: 32,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Structured Document view utilizing actual pdfIcon image assets exactly as specified
  Widget _buildDocsGrid(BuildContext context) {
    return GridView.builder(
      key: const ValueKey("docs_grid"),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            // Underlying content frame
            Image.network(
              photoGridImages[0],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: appColor(context).grey200,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: appColor(context).grey400,
                  ),
                );
              },
            ),
            Container(color: appColor(context).black.withValues(alpha: 0.55)),

            // Floating document tags
            Positioned(
              top: 12,
              left: 12,
              child: Text(
                "Frame123.pdf",
                style: fontStyle.clashDisplayMedium12.textColor(appColor(context).white),
              ),
            ),

            // Asset PDF Icon placed precisely at bottom-left as per user's updated image_assets
            Positioned(
              bottom: 12,
              left: 12,
              child: Image.asset(
                ImageAssets.pdfIcon,
                width: 20,
                height: 22,
                fit: BoxFit.contain,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Feeds list implementing custom elevated Hyperlink cards backed by project physical link assets
  Widget _buildLinksList(BuildContext context) {
    return ListView(
      key: const ValueKey("links_list"),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      children: [
        Text(
          "Recent",
          style: fontStyle.clashDisplaySemiBold16.textColor(appColor(context).black),
        ),
        const SizedBox(height: 16),

        ...List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: appColor(context).white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: appColor(context).black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                // Leading Icon container leveraging standard link1 asset image
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: appColor(context).grey100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      ImageAssets.link,
                      width: 22,
                      height: 22,
                      color: appColor(context).secondary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Shared URL descriptive contents
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Lorem ipsum dolor sit",
                        style: fontStyle.clashDisplaySemiBold14.textColor(
                          appColor(context).black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "https://meet.google.com/rqo-ozca...",
                        style: fontStyle.clashDisplayRegular12.textColor(
                          appColor(context).grey400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          );
        }),
      ],
    );
  }
}

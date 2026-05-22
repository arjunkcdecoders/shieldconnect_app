import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/media_viewer_screen.dart';

class AllMediaScreen extends StatelessWidget {
  final List<dynamic> mediaItems;

  const AllMediaScreen({super.key, required this.mediaItems});

  @override
  Widget build(BuildContext context) {
    // Retaining local UI interaction context inside a scoped StatefulBuilder satisfying strict Stateless requirements
    int activeTab = 0;

    // Filter the mediaItems dynamically on build
    final List<Map<String, String>> photos = [];
    final List<Map<String, String>> videos = [];
    final List<Map<String, String>> docs = [];
    final List<Map<String, String>> links = [];

    for (var item in mediaItems) {
      String url = "";
      String type = "";
      String name = "";

      if (item is Map) {
        url = item['file_url']?.toString() ?? item['url']?.toString() ?? item['file']?.toString() ?? "";
        type = item['message_type']?.toString() ?? item['type']?.toString() ?? "";
        name = item['file_name']?.toString() ?? item['name']?.toString() ?? "";
      } else if (item is String) {
        url = item;
      }

      if (url.isEmpty) continue;

      final String lowerUrl = url.toLowerCase();
      final String extension = lowerUrl.split('?').first.split('.').last;

      bool isImage = false;
      bool isVideo = false;
      bool isDoc = false;
      bool isLink = false;

      if (type == 'image') {
        isImage = true;
      } else if (type == 'video') {
        isVideo = true;
      } else if (type == 'file' || type == 'doc' || type == 'document') {
        isDoc = true;
      } else if (type == 'link') {
        isLink = true;
      } else {
        final imageExts = {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp', 'heic'};
        final videoExts = {'mp4', 'mov', 'mkv', 'avi', 'webm', '3gp'};
        final docExts = {'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'ppt', 'pptx', 'csv', 'zip', 'rar'};
        
        if (imageExts.contains(extension)) {
          isImage = true;
        } else if (videoExts.contains(extension)) {
          isVideo = true;
        } else if (docExts.contains(extension)) {
          isDoc = true;
        } else if (url.startsWith('http://') || url.startsWith('https://')) {
          isLink = true;
        }
      }

      if (name.isEmpty) {
        try {
          final path = url.split('?').first;
          name = path.split('/').last;
        } catch (_) {
          name = "file";
        }
      }
      if (name.isEmpty) {
        name = "Shared File";
      }

      final mediaMap = {
        "url": url,
        "name": name,
      };

      if (isImage) {
        photos.add(mediaMap);
      } else if (isVideo) {
        videos.add(mediaMap);
      } else if (isDoc) {
        docs.add(mediaMap);
      } else if (isLink) {
        links.add(mediaMap);
      }
    }

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
                    child: _buildActiveView(context, activeTab, photos, videos, docs, links),
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
  Widget _buildActiveView(
    BuildContext context,
    int activeTab,
    List<Map<String, String>> photos,
    List<Map<String, String>> videos,
    List<Map<String, String>> docs,
    List<Map<String, String>> links,
  ) {
    switch (activeTab) {
      case 0:
        return _buildPhotosGrid(context, photos);
      case 1:
        return _buildVideosGrid(context, videos);
      case 2:
        return _buildDocsGrid(context, docs);
      case 3:
        return _buildLinksList(context, links);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Premium empty states for clean aesthetics
  Widget _buildEmptyState(BuildContext context, String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: appColor(context).grey300,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: fontStyle.clashDisplayMedium14.textColor(
              appColor(context).grey400,
            ),
          ),
        ],
      ),
    );
  }

  /// Safe external launcher for Documents and Links
  Future<void> _openExternal(BuildContext context, String urlString) async {
    try {
      final Uri uri = Uri.parse(urlString);
      final String lowerUrl = urlString.toLowerCase();
      final String path = lowerUrl.split('?').first;
      final String extension = path.split('.').last;

      final docExts = {'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'ppt', 'pptx', 'csv', 'zip', 'rar'};
      final bool isDoc = docExts.contains(extension);

      if (isDoc) {
        try {
          // Attempt to open directly using the device's native PDF/Doc viewer app
          final bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          if (!launched) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
          }
        } catch (_) {
          // Fallback to standard external browser if direct native app launch fails
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        }
      } else {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint("Error opening URL external: $e");
    }
  }

  /// Pristine photo viewer framing beautiful immersive grids
  Widget _buildPhotosGrid(BuildContext context, List<Map<String, String>> photos) {
    if (photos.isEmpty) {
      return _buildEmptyState(context, "No shared photos yet", Icons.image_outlined);
    }
    return GridView.builder(
      key: const ValueKey("photos_grid"),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final rawUrl = photo["url"] ?? "";
        final photoUrl = ApiService.getImageUrl(rawUrl);
        final name = photo["name"] ?? "Image";
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MediaViewerScreen(
                  url: rawUrl,
                  type: 'image',
                  fileName: name,
                ),
              ),
            );
          },
          child: Container(
            color: appColor(context).grey100,
            child: Image.network(
              photoUrl,
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
          ),
        );
      },
    );
  }

  /// Structured video layout implementing Play indicia overlays
  Widget _buildVideosGrid(BuildContext context, List<Map<String, String>> videos) {
    if (videos.isEmpty) {
      return _buildEmptyState(context, "No shared videos yet", Icons.videocam_outlined);
    }
    return GridView.builder(
      key: const ValueKey("videos_grid"),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        final rawUrl = video["url"] ?? "";
        final videoUrl = ApiService.getImageUrl(rawUrl);
        final name = video["name"] ?? "Video";
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MediaViewerScreen(
                  url: rawUrl,
                  type: 'video',
                  fileName: name,
                ),
              ),
            );
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                videoUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: appColor(context).grey200,
                    child: Icon(
                      Icons.video_library_outlined,
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
          ),
        );
      },
    );
  }

  /// Structured Document view utilizing actual pdfIcon image assets exactly as specified
  Widget _buildDocsGrid(BuildContext context, List<Map<String, String>> docs) {
    if (docs.isEmpty) {
      return _buildEmptyState(context, "No shared documents yet", Icons.description_outlined);
    }
    return GridView.builder(
      key: const ValueKey("docs_grid"),
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
      ),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final rawUrl = doc["url"] ?? "";
        final docName = doc["name"] ?? "document.pdf";
        return GestureDetector(
          onTap: () {
            final absoluteUrl = ApiService.getImageUrl(rawUrl);
            _openExternal(context, absoluteUrl);
          },
          child: Container(
            color: appColor(context).grey900,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: appColor(context).black.withValues(alpha: 0.55)),

                // Floating document tags
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Text(
                    docName,
                    style: fontStyle.clashDisplayMedium12.textColor(appColor(context).white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
            ),
          ),
        );
      },
    );
  }

  /// Feeds list implementing custom elevated Hyperlink cards backed by project physical link assets
  Widget _buildLinksList(BuildContext context, List<Map<String, String>> links) {
    if (links.isEmpty) {
      return _buildEmptyState(context, "No shared links yet", Icons.link);
    }
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

        ...List.generate(links.length, (index) {
          final link = links[index];
          final String url = link["url"] ?? "";
          final String name = link["name"] ?? "";
          
          String displayTitle = name;
          if (displayTitle == "Shared File" || displayTitle.contains('.')) {
            try {
              final uri = Uri.parse(url);
              displayTitle = uri.host.replaceAll('www.', '');
            } catch (_) {
              displayTitle = "Shared Link";
            }
          }
          if (displayTitle.isEmpty) {
            displayTitle = "Shared Link";
          }

          return GestureDetector(
            onTap: () => _openExternal(context, url),
            child: Container(
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
                          displayTitle,
                          style: fontStyle.clashDisplaySemiBold14.textColor(
                            appColor(context).black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          url,
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
            ),
          );
        }),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';

class AnnouncementDetailsScreen extends StatelessWidget {
  final List<dynamic> announcements;

  const AnnouncementDetailsScreen({
    super.key,
    required this.announcements,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      appBar: AppBar(
        backgroundColor: appColor(context).white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: appColor(context).black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Announcements",
          style: fontStyle.clashDisplaySemiBold18
              .textColor(appColor(context).black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: announcements.isEmpty
            ? Center(
                child: Text(
                  "No announcements available",
                  style: fontStyle.clashDisplayMedium14
                      .textColor(appColor(context).grey400),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                itemCount: announcements.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Divider(color: appColor(context).grey100, thickness: 1),
                ),
                itemBuilder: (context, index) {
                  final ann = announcements[index];
                  final String title = ann["title"] ?? "Announcement";
                  final String description = ann["content"] ?? ann["message"] ?? "";
                  final String date = DateHelper.formatDate(ann["createdAt"] ?? ann["time"]);
                  final String? media = ann["media"];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: appColor(context).secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Admin",
                          style: fontStyle.clashDisplaySemiBold12
                              .textColor(appColor(context).secondary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        title,
                        style: fontStyle.clashDisplayBold24
                            .textColor(appColor(context).black),
                      ),
                      const SizedBox(height: 8),

                      // Date
                      Text(
                        date,
                        style: fontStyle.clashDisplayMedium14
                            .textColor(appColor(context).grey400),
                      ),
                      const SizedBox(height: 24),

                      // Media Image (if available)
                      if (media != null && media.isNotEmpty) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            ApiService.getImageUrl(media),
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Description
                      Text(
                        description,
                        style: fontStyle.clashDisplayRegular16
                            .textColor(appColor(context).black87)
                            .copyWith(height: 1.6),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}

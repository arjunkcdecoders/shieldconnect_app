import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/announcement_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';

class AnnouncementDetailsScreen extends StatelessWidget {
  final List<dynamic> announcements;

  const AnnouncementDetailsScreen({super.key, required this.announcements});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        context.read<AnnouncementController>().markAllAsRead();
      }
    });

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
          style: fontStyle.clashDisplaySemiBold18.textColor(
            appColor(context).black,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: announcements.isEmpty
            ? Center(
                child: Text(
                  "No announcements available",
                  style: fontStyle.clashDisplayMedium14.textColor(
                    appColor(context).grey400,
                  ),
                ),
              )
            : ListView.separated(
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                itemCount: announcements.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 20.0),
                itemBuilder: (context, index) {
                  final ann = announcements[index];
                  final String title = ann["title"] ?? "Announcement";
                  final String description =
                      ann["content"] ?? ann["message"] ?? "";
                  final String date = DateHelper.formatAnnouncementDate(
                    ann["createdAt"] ?? ann["time"],
                  );
                  final String? media = ann["media"];

                  return Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: appColor(
                        context,
                      ).bgGrey, // Beautiful modern soft viewing color
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: appColor(context).grey100,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: appColor(
                            context,
                          ).black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row for Admin Badge & Date/Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: appColor(
                                  context,
                                ).secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "Admin",
                                style: fontStyle.clashDisplaySemiBold12
                                    .textColor(appColor(context).secondary),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                date,
                                textAlign: TextAlign.end,
                                style: fontStyle.clashDisplayMedium12.textColor(
                                  appColor(context).grey500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          title,
                          style: fontStyle.clashDisplayBold20.textColor(
                            appColor(context).black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Media Image (if available)
                        if (media != null && media.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              ApiService.getImageUrl(media),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Description
                        Text(
                          description,
                          style: fontStyle.clashDisplayRegular14
                              .textColor(appColor(context).black87)
                              .copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}

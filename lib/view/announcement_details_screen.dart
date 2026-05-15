import 'package:flutter/material.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class AnnouncementDetailsScreen extends StatelessWidget {
  final String title;
  final String description;
  final String date;

  const AnnouncementDetailsScreen({
    super.key,
    this.title = "Important Announcement",
    this.description = "We will be performing a scheduled system maintenance today at 12:00 PM. The app might be temporarily unavailable for a few minutes. We apologize for the inconvenience.",
    this.date = "14 May 2026",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColor(context).white,
      appBar: AppBar(
        backgroundColor: appColor(context).white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: appColor(context).black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Details",
          style: fontStyle.clashDisplaySemiBold18.textColor(appColor(context).black),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
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
                  style: fontStyle.clashDisplaySemiBold12.textColor(appColor(context).secondary),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: fontStyle.clashDisplayBold24.textColor(appColor(context).black),
              ),
              const SizedBox(height: 8),

              // Date
              Text(
                date,
                style: fontStyle.clashDisplayMedium14.textColor(appColor(context).grey400),
              ),
              const SizedBox(height: 24),

              // Divider
              Divider(color: appColor(context).grey100, thickness: 1),
              const SizedBox(height: 24),

              // Description
              Text(
                description,
                style: fontStyle.clashDisplayRegular16.textColor(appColor(context).black87).copyWith(height: 1.6),
              ),
              
              const SizedBox(height: 40),

              // Call to action button (if any)
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      appColor(context).primary,
                      appColor(context).secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(27),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  ),
                  child: Text(
                    "Acknowledge",
                    style: fontStyle.clashDisplaySemiBold16.textColor(appColor(context).white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

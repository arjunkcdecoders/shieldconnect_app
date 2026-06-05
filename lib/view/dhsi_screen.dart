import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/profile_controller.dart';
import 'package:shieldconnect_app/services/api_services.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';
import 'package:shieldconnect_app/view/notification_screen.dart';

class DhsiScreen extends StatelessWidget {
  const DhsiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profileController = Provider.of<ProfileController>(context);
    final String userName = profileController.name.isNotEmpty
        ? profileController.name
        : "Maisie";
    final String userAvatar = profileController.imageUrl;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF), // Soft premium pink/white tint
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Avatar (with green badge) & Circular Actions
                _buildHeader(context, userAvatar),
                const SizedBox(height: 20),

                // 2. Main DHSI Score Card
                _buildScoreCard(context, userName, userAvatar),
                const SizedBox(height: 20),

                // 3. Positive Streak Card
                _buildStreakCard(context),
                const SizedBox(height: 20),

                // 4. Your DHSI Level (Horizontal scrolling timeline)
                _buildLevelTimeline(context, userAvatar),
                const SizedBox(height: 20),

                // 5. What affects your DHSI?
                _buildAffectsGrid(context),
                const SizedBox(height: 20),

                // 6. Your DHSI Trend (Chart)
                _buildTrendChart(context),
                const SizedBox(height: 20),

                // 7. What improved your score?
                _buildImprovementsGrid(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header Component
  Widget _buildHeader(BuildContext context, String userAvatar) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Avatar + Check badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: () {
                // Tapping avatar goes to profile
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(9.33),
                  color: appColor(context).grey100,
                  boxShadow: [
                    BoxShadow(
                      color: appColor(context).black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9.33),
                  child: userAvatar.isNotEmpty
                      ? Image.network(
                          ApiService.getImageUrl(userAvatar),
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Icon(
                            Icons.person,
                            color: appColor(context).grey400,
                            size: 24,
                          ),
                        )
                      : Image.asset(
                          ImageAssets.dhsi, // fallback to dhsi/avatar
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Icon(
                            Icons.person,
                            color: appColor(context).grey400,
                            size: 24,
                          ),
                        ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: -4,
              child: Image.asset(ImageAssets.tick, width: 16, height: 16),
            ),
          ],
        ),
        // Bell and Menu Circular Badges
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: appColor(context).silver.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Image.asset(
                    ImageAssets.notification,
                    width: 22,
                    height: 22,
                    color: const Color(0xFFEB3667),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: appColor(context).silver.withValues(alpha: 0.1),
              ),
              child: const Center(
                child: Icon(
                  Icons.more_vert,
                  color: Color(0xFFEB3667),
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Sparkle Builder Helper
  Widget _buildSparkle(double size) {
    return CustomPaint(size: Size(size, size), painter: SparklePainter());
  }

  // Score Card Component
  Widget _buildScoreCard(
    BuildContext context,
    String userName,
    String userAvatar,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD5DD), width: 1),
        gradient: const LinearGradient(
          colors: [Color(0xFFFDD6EB), Color(0xFFFFFFFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEB3667).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: User image surrounded by safety gauge ring, thin white ring & sparkles
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Outer White/Glimmer Ring
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.0,
                  ),
                ),
              ),
              // Gauge ring
              SizedBox(
                width: 76,
                height: 76,
                child: CircularProgressIndicator(
                  value: 0.82,
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.4),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFEB3667),
                  ),
                ),
              ),
              // Main User avatar
              Container(
                width: 66,
                height: 66,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: userAvatar.isNotEmpty
                      ? Image.network(
                          ApiService.getImageUrl(userAvatar),
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          ImageAssets.dhsi,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Image.asset(
                            ImageAssets.level82,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              // Score badge overlapping bottom
              Positioned(
                bottom: -8,
                child: Image.asset(ImageAssets.level82, width: 32, height: 35),
              ),
              // Sparkles / Stars
              Positioned(top: 2, left: 8, child: _buildSparkle(9)),
              Positioned(top: -4, right: 10, child: _buildSparkle(12)),
              Positioned(bottom: 18, left: -2, child: _buildSparkle(8)),
              Positioned(bottom: 30, right: -4, child: _buildSparkle(5)),
            ],
          ),
          const SizedBox(width: 20),
          // Right: Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hi, $userName!",
                  style: fontStyle.clashDisplayBold16.textColor(
                    appColor(context).black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "You're doing amazing!",
                  style: fontStyle.clashDisplaySemiBold12.textColor(
                    const Color(0xFFEB3667),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Your Digital Harm Safety Index (DHSI)",
                  style: fontStyle.clashDisplayMedium10
                      .copyWith(fontSize: 9.5)
                      .textColor(appColor(context).black),
                ),
                const SizedBox(height: 6),
                // Score & status safe badge inside a single white container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEB3667).withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            "82",
                            style: fontStyle.clashDisplayBold20.textColor(
                              const Color(0xFFEB3667),
                            ),
                          ),
                          Text(
                            " /100",
                            style: fontStyle.clashDisplaySemiBold12
                                .copyWith(fontSize: 11)
                                .textColor(appColor(context).textGrey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F6E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "Safe",
                          style: fontStyle.clashDisplayMedium10
                              .copyWith(fontSize: 9)
                              .textColor(const Color(0xFF1A9E16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Streak Component
  Widget _buildStreakCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8FC), Color(0xFFFFFFFF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3E8), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEB3667).withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: fontStyle.clashDisplayBold14.textColor(
                appColor(context).black,
              ),
              children: const [
                TextSpan(
                  text: "12 ",
                  style: TextStyle(color: Color(0xFFEB3667)),
                ),
                TextSpan(text: "Days Positive Streak"),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Keep it up! Every day you choose kindness, you level up!",
            style: fontStyle.clashDisplayMedium10.textColor(
              appColor(context).textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          // Horizontal days row with connector line behind
          Stack(
            children: [
              Positioned(
                left: 16,
                right: 16,
                top: 12,
                child: Container(height: 1.5, color: const Color(0xFFEB3667)),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStreakDay(context, "Mon", isChecked: true),
                  _buildStreakDay(context, "Tue", isChecked: true),
                  _buildStreakDay(context, "Wed", isChecked: true),
                  _buildStreakDay(context, "Thu", isChecked: true),
                  _buildStreakDay(context, "Fri", isChecked: true),
                  _buildStreakDay(context, "Sat", isChecked: true),
                  _buildStreakDay(context, "Today", isToday: true),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDay(
    BuildContext context,
    String day, {
    bool isChecked = false,
    bool isToday = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isToday)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEB3667), width: 1.5),
            ),
            child: const Center(
              child: Text("🔥", style: TextStyle(fontSize: 11)),
            ),
          )
        else if (isChecked)
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFEB3667), width: 1.5),
            ),
            padding: const EdgeInsets.all(2.0),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEB3667),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.check, color: Colors.white, size: 10),
              ),
            ),
          )
        else
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E3E5), width: 1.5),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          day,
          style: fontStyle.clashDisplayMedium10.textColor(
            isToday ? const Color(0xFFEB3667) : appColor(context).black,
          ),
        ),
      ],
    );
  }

  // Levels Timeline Component
  Widget _buildLevelTimeline(BuildContext context, String userAvatar) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8FC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3E8), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEB3667).withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "Your DHSI Level",
              style: fontStyle.clashDisplayBold14.textColor(
                appColor(context).black,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal timeline layout
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  // Leading connector line going off-screen to the left
                  _buildTimelineConnector(
                    context,
                    color: const Color(0xFFFF9800),
                  ),
                  // Level 3 item (Completed)
                  _buildTimelineItem(
                    context,
                    title: "Level 3",
                    subtitle: "Kind Communicator",
                    badgeImage: ImageAssets.level3,
                    color: const Color(0xFF673AB7),
                    isCompleted: true,
                  ),
                  _buildTimelineConnector(
                    context,
                    color: const Color(0xFF673AB7),
                  ),
                  // Level 4 item (Current)
                  _buildTimelineItem(
                    context,
                    title: "Level 4",
                    subtitle: "Respect Explorer",
                    badgeImage: ImageAssets.level4,
                    color: const Color(0xFFEB3667),
                    isCurrent: true,
                    userAvatar: userAvatar,
                  ),
                  _buildTimelineConnector(
                    context,
                    color: const Color(0xFFEB3667),
                  ),
                  // Level 5 item (Locked)
                  _buildTimelineItem(
                    context,
                    title: "Level 5",
                    subtitle: "Empathy Champion",
                    badgeImage: ImageAssets.locked,
                    color: Colors.grey,
                    isLocked: true,
                  ),
                  // Trailing connector line going off-screen to the right
                  _buildTimelineConnector(context, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Progress banner inside
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Color(0xFFFFF8FC),
                    border: Border.all(
                      color: const Color(0xFFFFD5DD),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "180 Points to reach level 5  ",
                        style: fontStyle.clashDisplayMedium10.textColor(
                          appColor(context).black,
                        ),
                      ),
                      const Text("🚀", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                // Indicator dots
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEB3667),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE0E0E0),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String badgeImage,
    required Color color,
    bool isCompleted = false,
    bool isCurrent = false,
    bool isLocked = false,
    String? userAvatar,
  }) {
    // Determine card background and border colors
    Color cardBgColor;
    Color cardBorderColor;
    Color textColor;
    Color subtitleColor;

    if (isLocked) {
      cardBgColor = const Color(0xFFF7F8F9);
      cardBorderColor = const Color(0xFFE5E7EB);
      textColor = const Color(0xFF9CA3AF);
      subtitleColor = const Color(0xFF9CA3AF);
    } else if (isCurrent) {
      cardBgColor = const Color(0xFFFFF0F3);
      cardBorderColor = const Color(0xFFFFD5DD);
      textColor = const Color(0xFFEB3667);
      subtitleColor = const Color(0xFFEB3667);
    } else {
      // Completed (purple)
      cardBgColor = const Color(0xFFF2EFFF);
      cardBorderColor = const Color(0xFFDCD6FF);
      textColor = color;
      subtitleColor = const Color(0xFF5B30A7);
    }

    return SizedBox(
      width: 100,
      height: 95,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Card Container
          Positioned(
            top: 24,
            left: 0,
            right: 0,
            child: Container(
              height: 68,
              padding: const EdgeInsets.only(
                top: 24,
                bottom: 4,
                left: 4,
                right: 4,
              ),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorderColor, width: 1.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: fontStyle.clashDisplayBold10.textColor(textColor),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: fontStyle.clashDisplayMedium10
                        .copyWith(fontSize: 9)
                        .textColor(subtitleColor),
                  ),
                ],
              ),
            ),
          ),

          // Badge / Avatar Stack
          Positioned(
            top: 0,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (isCurrent) ...[
                  // Current level avatar with pink ring
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFEB3667),
                        width: 1.5,
                      ),
                    ),
                    padding: const EdgeInsets.all(1.5),
                    child: ClipOval(
                      child: userAvatar != null && userAvatar.isNotEmpty
                          ? Image.network(
                              ApiService.getImageUrl(userAvatar),
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              ImageAssets.maisieAvatar,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  // Overlapping pink shield badge (level4 image)
                  Positioned(
                    bottom: -6,
                    child: Image.asset(
                      ImageAssets.level4,
                      width: 18,
                      height: 20,
                    ),
                  ),
                ] else ...[
                  // Completed or Locked badge
                  Image.asset(
                    badgeImage,
                    width: 38,
                    height: 42,
                    fit: BoxFit.contain,
                  ),
                ],
              ],
            ),
          ),

          // Completed checkmark indicator on top-right (fully inside the card container)
          if (isCompleted)
            Positioned(
              top: 28,
              right: 6,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A9E16),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.check, color: Colors.white, size: 9),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector(BuildContext context, {required Color color}) {
    return Container(
      width: 40,
      margin: const EdgeInsets.only(
        top: 22,
      ), // Align with center of the shields
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Dashes before the arrow
          ...List.generate(
            2,
            (index) => Container(
              width: 3,
              height: 1.2,
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
              color: color,
            ),
          ),
          const SizedBox(width: 1),
          // Arrow pointing right
          Icon(Icons.chevron_right_rounded, color: color, size: 10),
          const SizedBox(width: 1),
          // Dashes after the arrow
          ...List.generate(
            2,
            (index) => Container(
              width: 3,
              height: 1.2,
              margin: const EdgeInsets.symmetric(horizontal: 1.0),
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Affects Index Grid Component
  Widget _buildAffectsGrid(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3E8), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEB3667).withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "What affects your DHSI? ",
                style: fontStyle.clashDisplayBold14.textColor(
                  appColor(context).black,
                ),
              ),
              const Text("🤔", style: TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal row of factors
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildAffectCard(
                  context,
                  title: "Harm Signals",
                  status: "Medium",
                  statusColor: const Color(0xFFF59E0B),
                  desc: "You avoided some harmful content.",
                  imageAsset: ImageAssets.harm,
                  bgColor: const Color(0xFFFFF0F2),
                  borderColor: const Color(0xFFFFD5DD),
                  progressValue: 0.66,
                  progressColor: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 12),
                _buildAffectCard(
                  context,
                  title: "Behavior Changes",
                  status: "Low",
                  statusColor: const Color(0xFF1A9E16),
                  desc: "You're showing positive change!",
                  imageAsset: ImageAssets.changes,
                  bgColor: const Color(0xFFF4F6FF),
                  borderColor: const Color(0xFFDCE2FF),
                  progressValue: 0.33,
                  progressColor: const Color(0xFF1A9E16),
                ),
                const SizedBox(width: 12),
                _buildAffectCard(
                  context,
                  title: "Repeat Exposure",
                  status: "Medium",
                  statusColor: const Color(0xFFF59E0B),
                  desc: "You sometimes visit risky spaces.",
                  imageAsset: ImageAssets.repeat,
                  bgColor: const Color(0xFFFFF7EA),
                  borderColor: const Color(0xFFFFEAD5),
                  progressValue: 0.66,
                  progressColor: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 12),
                _buildAffectCard(
                  context,
                  title: "Good Choices",
                  status: "Low",
                  statusColor: const Color(0xFF1A9E16),
                  desc: "You make kind and smart choices!",
                  imageAsset: ImageAssets.choices,
                  bgColor: const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFFD5FAD9),
                  progressValue: 0.33,
                  progressColor: const Color(0xFF1A9E16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAffectCard(
    BuildContext context, {
    required String title,
    required String status,
    required Color statusColor,
    required String desc,
    required String imageAsset,
    required Color bgColor,
    required Color borderColor,
    required double progressValue,
    required Color progressColor,
  }) {
    return Container(
      width: 115,
      height: 165,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Icon
          Image.asset(imageAsset, width: 22, height: 24, fit: BoxFit.contain),
          const SizedBox(height: 8),
          // Centered Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: fontStyle.clashDisplayBold9.textColor(
              appColor(context).black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          // Centered Status
          Text(
            status,
            textAlign: TextAlign.center,
            style: fontStyle.clashDisplayBold10.textColor(statusColor),
          ),
          const SizedBox(height: 8),
          // Custom segmented progress bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: progressValue >= 0.33
                        ? progressColor
                        : const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: progressValue >= 0.66
                        ? progressColor
                        : const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: progressValue >= 0.99
                        ? progressColor
                        : const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Centered Description
          Expanded(
            child: Text(
              desc,
              textAlign: TextAlign.center,
              style: fontStyle.clashDisplayMedium10.textColor(
                appColor(context).black,
              ),
              maxLines: 3,
              overflow: TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }

  // DHSITrend Chart Component
  Widget _buildTrendChart(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3E8), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEB3667).withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your DHSITrend",
            style: fontStyle.clashDisplayBold14.textColor(
              appColor(context).black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left text info
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "This Week",
                    style: fontStyle.clashDisplayMedium10.textColor(
                      appColor(context).textGrey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "82",
                        style: fontStyle.clashDisplayBold20.textColor(
                          const Color(0xFFEB3667),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2F6E2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.arrow_upward,
                              color: Color(0xFF1A9E16),
                              size: 10,
                            ),
                            Text(
                              " +6",
                              style: fontStyle.clashDisplayMedium10.textColor(
                                const Color(0xFF1A9E16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Last Week",
                    style: fontStyle.clashDisplayMedium10.textColor(
                      appColor(context).textGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "76",
                    style: fontStyle.clashDisplayBold20.textColor(
                      appColor(context).textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              // Right: custom painter line graph chart
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: CustomPaint(
                    painter: _TrendChartPainter(
                      points: [71, 74, 76, 79, 80, 78, 82],
                      labels: [
                        "Sun",
                        "Mon",
                        "Tue",
                        "Wed",
                        "Thu",
                        "Fri",
                        "Today",
                      ],
                      lineColor: const Color(0xFFEB3667),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Improvements Grid Component
  Widget _buildImprovementsGrid(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9FA),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFE3E8), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEB3667).withValues(alpha: 0.02),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "What improved your score? ",
                style: fontStyle.clashDisplayBold14.textColor(
                  appColor(context).black,
                ),
              ),
              const Text("⭐", style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          // Horizontal scrolling row of improvement cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildImproveCard(
                  context,
                  pts: "+15 pts",
                  desc: "You sent positive messages",
                  imageAsset: ImageAssets.blueBubble,
                  iconBgColor: const Color(0xFFE8F4FD), // Light blue
                ),
                const SizedBox(width: 12),
                _buildImproveCard(
                  context,
                  pts: "+10pts",
                  desc: "You respected different opinions",
                  imageAsset: ImageAssets.opinion,
                  iconBgColor: const Color(0xFFE8F7EC), // Light green
                ),
                const SizedBox(width: 12),
                _buildImproveCard(
                  context,
                  pts: "+10 pts",
                  desc: "You reported harmful content",
                  imageAsset: ImageAssets.reported,
                  iconBgColor: const Color(0xFFF2EAFF), // Light purple
                ),
                const SizedBox(width: 12),
                _buildImproveCard(
                  context,
                  pts: "+8 pts",
                  desc: "You helped a friend",
                  imageAsset: ImageAssets.help,
                  iconBgColor: const Color(0xFFF2EAFF), // Light purple
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImproveCard(
    BuildContext context, {
    required String pts,
    required String desc,
    required String imageAsset,
    required Color iconBgColor,
  }) {
    return Container(
      width: 115,
      height: 140,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Icon in colored circle
          Center(
            child: Image.asset(
              imageAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 10),
          // Points
          Text(
            pts,
            textAlign: TextAlign.center,
            style: fontStyle.clashDisplayBold14.textColor(
              const Color(0xFF1A9E16),
            ),
          ),
          const SizedBox(height: 6),
          // Description
          Expanded(
            child: Text(
              desc,
              textAlign: TextAlign.center,
              style: fontStyle.clashDisplayMedium10.textColor(
                appColor(context).black.withValues(alpha: 0.85),
              ),
              maxLines: 3,
              overflow: TextOverflow.clip,
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Trend Line Chart
class _TrendChartPainter extends CustomPainter {
  final List<double> points;
  final List<String> labels;
  final Color lineColor;

  _TrendChartPainter({
    required this.points,
    required this.labels,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double width = size.width;
    final double height = size.height - 24; // reserve space for text labels

    // Find min/max values
    double minVal = points[0];
    double maxVal = points[0];
    for (final val in points) {
      if (val < minVal) minVal = val;
      if (val > maxVal) maxVal = val;
    }
    // Add small buffer to top/bottom of chart
    minVal -= 2;
    maxVal += 2;

    final double range = maxVal - minVal;

    final int segments = points.length - 1;
    final double xSpacing = width / segments;

    final List<Offset> offsetPoints = [];
    for (int i = 0; i < points.length; i++) {
      final double x = i * xSpacing;
      // map point to height
      final double normalizedY = (points[i] - minVal) / range;
      final double y =
          height - (normalizedY * (height - 15)); // reverse since y is down
      offsetPoints.add(Offset(x, y));
    }

    // Draw grid/labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // 1. Draw thin vertical grid lines from nodes to the bottom
    final Paint gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < offsetPoints.length; i++) {
      canvas.drawLine(
        Offset(offsetPoints[i].dx, offsetPoints[i].dy + 4),
        Offset(offsetPoints[i].dx, height + 10),
        gridPaint,
      );
    }

    // 2. Draw bottom labels (Sun, Mon, etc.)
    for (int i = 0; i < points.length; i++) {
      final bool isToday = (i == segments);
      final labelStyle = TextStyle(
        color: isToday ? lineColor : Colors.grey.shade400,
        fontSize: 10,
        fontFamily: FontStyle.clashDisplay,
        fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
      );

      textPainter.text = TextSpan(text: labels[i], style: labelStyle);
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(offsetPoints[i].dx - (textPainter.width / 2), size.height - 12),
      );

      // 3. Draw score values above the nodes
      if (i == segments) {
        // Draw pink pill for today's value (82)
        final valText = points[i].toInt().toString();
        textPainter.text = TextSpan(
          text: valText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontFamily: FontStyle.clashDisplay,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();

        final double pillWidth = textPainter.width + 10;
        final double pillHeight = textPainter.height + 4;
        final double pillX = offsetPoints[i].dx - (pillWidth / 2);
        final double pillY = offsetPoints[i].dy - pillHeight - 6;

        final RRect pillRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(pillX, pillY, pillWidth, pillHeight),
          const Radius.circular(6),
        );
        final Paint pillPaint = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;
        canvas.drawRRect(pillRRect, pillPaint);

        textPainter.paint(canvas, Offset(pillX + 5, pillY + 2));
      } else {
        // Draw regular score text (71, 74, 76, 79, 80, 78)
        final score = points[i].toInt();
        Color scoreColor;
        if (score >= 80) {
          scoreColor = const Color(0xFF1A9E16); // Green
        } else {
          scoreColor = const Color(0xFFD97706); // Orange/brown
        }

        textPainter.text = TextSpan(
          text: score.toString(),
          style: TextStyle(
            color: scoreColor,
            fontSize: 9,
            fontFamily: FontStyle.clashDisplay,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            offsetPoints[i].dx - (textPainter.width / 2),
            offsetPoints[i].dy - 16,
          ),
        );
      }
    }

    // 4. Draw gradient fill under curve
    final Path pathGradient = Path();
    pathGradient.moveTo(offsetPoints.first.dx, height + 10);
    for (final p in offsetPoints) {
      pathGradient.lineTo(p.dx, p.dy);
    }
    pathGradient.lineTo(offsetPoints.last.dx, height + 10);
    pathGradient.close();

    final Paint paintGradient = Paint()
      ..shader = ui.Gradient.linear(
        Offset(
          0,
          offsetPoints.map((p) => p.dy).reduce((a, b) => a < b ? a : b),
        ),
        Offset(0, height + 10),
        [lineColor.withValues(alpha: 0.15), lineColor.withValues(alpha: 0.0)],
      );
    canvas.drawPath(pathGradient, paintGradient);

    // 5. Draw line curve
    final Paint linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final Path curvePath = Path();
    curvePath.moveTo(offsetPoints.first.dx, offsetPoints.first.dy);
    for (int i = 1; i < offsetPoints.length; i++) {
      curvePath.lineTo(offsetPoints[i].dx, offsetPoints[i].dy);
    }
    canvas.drawPath(curvePath, linePaint);

    // 6. Draw circle dots on curve points
    final Paint dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final Paint dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < offsetPoints.length; i++) {
      final double radius = (i == segments) ? 5.0 : 3.5;
      final double innerRadius = (i == segments) ? 2.5 : 1.5;
      canvas.drawCircle(offsetPoints[i], radius, dotPaint);
      canvas.drawCircle(offsetPoints[i], innerRadius, dotInnerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}

class SparklePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w / 2, 0);
    path.quadraticBezierTo(w / 2, h / 2, w, h / 2);
    path.quadraticBezierTo(w / 2, h / 2, w / 2, h);
    path.quadraticBezierTo(w / 2, h / 2, 0, h / 2);
    path.quadraticBezierTo(w / 2, h / 2, w / 2, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

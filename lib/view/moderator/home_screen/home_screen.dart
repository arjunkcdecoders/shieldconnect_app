import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/moderator/moderator_home_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';
import 'package:shieldconnect_app/utils/image_assets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ModeratorHomeController>(
      builder: (context, controller, _) {
        return Scaffold(
          backgroundColor: appColor(context).white,
          appBar: _buildAppBar(context),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeHeader(context),
                const SizedBox(height: 24),
                controller.isLoadingStats
                    ? SizedBox(
                        height: 100,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: appColor(context).secondary,
                          ),
                        ),
                      )
                    : _buildStatsGrid(context, controller.dashboardStats),
                const SizedBox(height: 32),
                _buildSectionHeader(context, "Moderations"),
                const SizedBox(height: 16),
                _buildModerationList(context, controller.moderationItems),
                const SizedBox(height: 32),
                // _buildSectionHeader(context, "Recent User Registrations"),
                // const SizedBox(height: 16),
                // _buildRecentRegistrations(
                //   context,
                //   controller.recentRegistrations,
                // ),
                const SizedBox(height: 32),
                _buildSectionHeader(context, "Message Activity"),
                const SizedBox(height: 16),
                _buildActivityChart(context),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: appColor(context).white,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: appColor(context).transparent,
      leading: Padding(
        padding: const EdgeInsets.only(left: 24),
        child: Image.asset(ImageAssets.appIcon, height: 28, width: 28),
      ),
      leadingWidth: 56,
      title: Text(
        "Dashboard",
        style: fontStyle.clashDisplayBold30
            .textColor(appColor(context).black)
            .size(20),
      ),
      centerTitle: false,
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Admin",
          style: fontStyle.clashDisplayBold30
              .textColor(appColor(context).primary)
              .size(18),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's what's happening in your chat app today",
          style: fontStyle.clashDisplayRegular14
              .textColor(appColor(context).silver)
              .size(12),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    List<Map<String, dynamic>> stats,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.8,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: appColor(context).white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: appColor(context).black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stat['value'],
                style: fontStyle.clashDisplayBold30
                    .textColor(stat['color'])
                    .size(20),
              ),
              const SizedBox(height: 4),
              Text(
                stat['title'],
                textAlign: TextAlign.center,
                style: fontStyle.clashDisplayMedium12
                    .textColor(appColor(context).black)
                    .size(10),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModerationList(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    return Column(
      children: [
        ...items.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: appColor(context).white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: appColor(context).black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Image.asset(
                      ImageAssets.messagedots,
                      color: appColor(context).primary,
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['postId'],
                      style: fontStyle.clashDisplayMedium12
                          .textColor(appColor(context).silver)
                          .size(10),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['userName'],
                      style: fontStyle.clashDisplayBold30
                          .textColor(appColor(context).black)
                          .size(12),
                    ),
                    const Spacer(),
                    _buildActionButton(
                      context,
                      Icons.close,
                      appColor(context).bgGrey,
                      appColor(context).red,
                    ),
                    const SizedBox(width: 6),
                    _buildActionButton(
                      context,
                      Icons.check,
                      appColor(context).primary,
                      appColor(context).white,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildTag(
                      context,
                      "Risk ${item['riskScore']}",
                      appColor(context).primary.withOpacity(0.1),
                      appColor(context).primary,
                    ),
                    const SizedBox(width: 6),
                    ...item['tags']
                        .map<Widget>(
                          (tag) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildTag(
                              context,
                              tag,
                              const Color(0xFFE3F2FD),
                              const Color(0xFF1E88E5),
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['content'],
                  style: fontStyle.clashDisplayRegular14
                      .textColor(appColor(context).black)
                      .size(11),
                ),
                const SizedBox(height: 8),
                Text(
                  item['timestamp'],
                  style: fontStyle.clashDisplayRegular12
                      .textColor(appColor(context).silver)
                      .size(9),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: () {
              // Navigate to all moderations
            },
            child: Text(
              "View All",
              style: fontStyle.clashDisplaySemiBold18
                  .textColor(appColor(context).primary)
                  .size(14)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTag(
    BuildContext context,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: fontStyle.clashDisplaySemiBold18.textColor(textColor).size(9),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      height: 28,
      width: 28,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: iconColor, size: 16),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: fontStyle.clashDisplayBold30
          .textColor(appColor(context).black)
          .size(16),
    );
  }

  Widget _buildRecentRegistrations(
    BuildContext context,
    List<Map<String, dynamic>> users,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: appColor(context).bgGrey),
      ),
      child: Column(
        children: [
          ...users.take(3).map((user) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: appColor(context).white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: appColor(context).black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: NetworkImage(user['image']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                user['name'],
                                style: fontStyle.clashDisplayBold30
                                    .textColor(appColor(context).black)
                                    .size(14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  user['country'],
                                  style: fontStyle.clashDisplaySemiBold18
                                      .textColor(appColor(context).textGrey)
                                      .size(9),
                                ),
                                const SizedBox(width: 4),
                                Image.asset(
                                  ImageAssets.usFlag,
                                  height: 14,
                                  width: 14,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user['email'],
                          style: fontStyle.clashDisplayRegular12
                              .textColor(appColor(context).textGrey)
                              .size(11),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          user['phone'],
                          style: fontStyle.clashDisplayRegular12
                              .textColor(appColor(context).textMediumGrey)
                              .size(11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          const SizedBox(height: 4),
          Center(
            child: Text(
              "View More",
              style: fontStyle.clashDisplaySemiBold18
                  .textColor(appColor(context).primary)
                  .size(12)
                  .copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColor(context).white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: appColor(context).bgGrey),
        boxShadow: [
          BoxShadow(
            color: appColor(context).black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: CustomPaint(painter: ChartPainter(appColor(context).primary)),
    );
  }
}

class ChartPainter extends CustomPainter {
  final Color color;
  ChartPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.1,
      size.height * 0.4,
      size.width * 0.2,
      size.height * 0.2,
    );
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.5,
      size.width * 0.4,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.8,
      size.width * 0.6,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.7,
      size.height * 0.4,
      size.width * 0.8,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.9,
      size.width,
      size.height * 0.5,
    );

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, paint);
    canvas.drawPath(path, linePaint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

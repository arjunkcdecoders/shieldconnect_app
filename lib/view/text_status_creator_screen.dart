import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/status_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class TextStatusCreatorScreen extends StatelessWidget {
  const TextStatusCreatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StatusController>(
      builder: (context, controller, child) {
        final List<String> hexColors = controller.hexColors;
        final List<String> fontFamilies = controller.fontFamilies;
        
        final String currentHexColor = hexColors[controller.selectedColorIndex];
        final Color backgroundColor = Color(int.parse(currentHexColor.replaceFirst('#', '0xFF')));
        final String currentFont = fontFamilies[controller.selectedFontIndex];

        // Dynamic Font Scaling
        double fontSize = 32.0;
        final String textContent = controller.textStatusController.text;
        if (textContent.length > 250) {
          fontSize = 16.0;
        } else if (textContent.length > 150) {
          fontSize = 20.0;
        } else if (textContent.length > 80) {
          fontSize = 26.0;
        }

        TextStyle textStyle;
        switch (currentFont) {
          case 'Roboto':
            textStyle = clashDisplay(fontsize: fontSize, fontWeight: FontWeight.w600).copyWith(fontFamily: 'Roboto');
            break;
          case 'PlayfairDisplay':
            textStyle = clashDisplay(fontsize: fontSize, fontWeight: FontWeight.w600).copyWith(fontFamily: 'PlayfairDisplay');
            break;
          case 'Courier':
            textStyle = clashDisplay(fontsize: fontSize, fontWeight: FontWeight.w600).copyWith(fontFamily: 'Courier');
            break;
          default:
            textStyle = clashDisplay(fontsize: fontSize, fontWeight: FontWeight.w600);
            break;
        }

        final bool isLoading = controller.isLoading;

        return Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: isLoading 
                            ? null 
                            : () {
                                controller.clearTextStatus();
                                Navigator.pop(context);
                              },
                        icon: Icon(
                          Icons.close,
                          color: isLoading
                              ? appColor(context).white.withValues(alpha: 0.5)
                              : appColor(context).white,
                          size: 28,
                        ),
                      ),
                      Text(
                        "Add Status",
                        style: fontStyle.clashDisplaySemiBold18.textColor(
                          appColor(context).white,
                        ),
                      ),
                      isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : TextButton.icon(
                              onPressed: () async {
                                final text = controller.textStatusController.text.trim();
                                if (text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a status message.')),
                                  );
                                  return;
                                }

                                final success = await controller.uploadTextStatus(
                                  text,
                                  currentHexColor,
                                );

                                if (success && context.mounted) {
                                  controller.clearTextStatus();
                                  Navigator.pop(context);
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to upload status. Please try again.')),
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.check,
                                color: appColor(context).white,
                                size: 20,
                              ),
                              label: Text(
                                "Done",
                                style: fontStyle.clashDisplaySemiBold16.textColor(
                                  appColor(context).white,
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 32.0),
                      child: TextField(
                        controller: controller.textStatusController,
                        onChanged: (text) => controller.handleTextStatusChanged(context),
                        maxLines: null,
                        textAlign: TextAlign.center,
                        style: textStyle.textColor(appColor(context).white),
                        decoration: InputDecoration(
                          hintText: "Type a Status",
                          hintStyle: clashDisplay(fontsize: 32, fontWeight: FontWeight.w600).textColor(
                            appColor(context).white.withValues(alpha: 0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),

                // Floating Style / Font Selector
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 24.0, bottom: 16.0),
                    child: GestureDetector(
                      onTap: controller.cycleFont,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: appColor(context).white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: appColor(context).white.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Aa",
                              style: fontStyle.clashDisplayBold18.textColor(
                                appColor(context).white,
                              ),
                            ),
                            Text(
                              "Text",
                              style: fontStyle.clashDisplayMedium10.textColor(
                                appColor(context).white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Solid background color palette at the bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 24.0, left: 16.0, right: 16.0),
                  child: SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: hexColors.length,
                      itemBuilder: (context, index) {
                        final String hex = hexColors[index];
                        final Color color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                        final bool isSelected = index == controller.selectedColorIndex;

                        return GestureDetector(
                          onTap: () => controller.selectColor(index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: appColor(context).white,
                                      width: 3.0,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: appColor(context).white,
                                    size: 20,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

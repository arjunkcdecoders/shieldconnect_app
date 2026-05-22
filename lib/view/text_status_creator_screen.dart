import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shieldconnect_app/controller/status_controller.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';
import 'package:shieldconnect_app/utils/font_style.dart';

class TextStatusCreatorScreen extends StatefulWidget {
  const TextStatusCreatorScreen({super.key});

  @override
  State<TextStatusCreatorScreen> createState() => _TextStatusCreatorScreenState();
}

class _TextStatusCreatorScreenState extends State<TextStatusCreatorScreen> {
  final TextEditingController _textController = TextEditingController();

  // Color options as hex string & flutter Color objects
  final List<String> _hexColors = [
    "#5ABED6", // Light Blue
    "#6B8ECC", // Pastel Blue
    "#8661D6", // Purple
    "#C762D2", // Magenta/pink
    "#78E266", // Light Green
    "#0F9C35", // Dark Green
    "#E2A814", // Gold/Orange
    "#D64D4D", // Red
  ];

  int _selectedColorIndex = 0;

  // Font cycling options
  final List<String> _fontFamilies = [
    'ClashDisplay',
    'Roboto',
    'PlayfairDisplay',
    'Courier',
  ];
  int _selectedFontIndex = 0;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _cycleFont() {
    setState(() {
      _selectedFontIndex = (_selectedFontIndex + 1) % _fontFamilies.length;
    });
  }

  Future<void> _submitStatus() async {
    if (context.read<StatusController>().isLoading) return;
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a status message.')),
      );
      return;
    }

    final controller = context.read<StatusController>();
    final success = await controller.uploadTextStatus(
      text,
      _hexColors[_selectedColorIndex],
    );

    if (success && mounted) {
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload status. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentHexColor = _hexColors[_selectedColorIndex];
    final Color backgroundColor = Color(int.parse(currentHexColor.replaceFirst('#', '0xFF')));
    final String currentFont = _fontFamilies[_selectedFontIndex];

    TextStyle textStyle;
    switch (currentFont) {
      case 'Roboto':
        textStyle = clashDisplay(fontsize: 32, fontWeight: FontWeight.w600).copyWith(fontFamily: 'Roboto');
        break;
      case 'PlayfairDisplay':
        textStyle = clashDisplay(fontsize: 32, fontWeight: FontWeight.w600).copyWith(fontFamily: 'PlayfairDisplay');
        break;
      case 'Courier':
        textStyle = clashDisplay(fontsize: 32, fontWeight: FontWeight.w600).copyWith(fontFamily: 'Courier');
        break;
      default:
        textStyle = clashDisplay(fontsize: 32, fontWeight: FontWeight.w600);
        break;
    }

    final bool isLoading = context.watch<StatusController>().isLoading;

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
                    onPressed: isLoading ? null : () => Navigator.pop(context),
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
                          onPressed: _submitStatus,
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
            const Spacer(),

            // Type a Status Center Editor Stack
            Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: TextField(
                    controller: _textController,
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
              ],
            ),
            const Spacer(),

            // Floating Style / Font Selector
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24.0, bottom: 16.0),
                child: GestureDetector(
                  onTap: _cycleFont,
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
                  itemCount: _hexColors.length,
                  itemBuilder: (context, index) {
                    final String hex = _hexColors[index];
                    final Color color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                    final bool isSelected = index == _selectedColorIndex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColorIndex = index;
                        });
                      },
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
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shieldconnect_app/utils/app_colors.dart';

class LinkifiedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final String query;
  final bool isSearchActive;

  const LinkifiedText({
    super.key,
    required this.text,
    required this.style,
    this.query = '',
    this.isSearchActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final RegExp urlRegExp = RegExp(
      r'((?:https?:\/\/|www\.)[^\s\)]+)',
      caseSensitive: false,
    );

    final List<InlineSpan> spans = [];
    int lastIndex = 0;

    for (final Match match in urlRegExp.allMatches(text)) {
      if (match.start > lastIndex) {
        final plainText = text.substring(lastIndex, match.start);
        spans.addAll(_getHighlightSpans(context, plainText));
      }

      final urlText = match.group(0)!;
      
      // Separate trailing punctuation from the link
      var cleanUrlText = urlText;
      var trailingPunctuation = '';
      while (cleanUrlText.isNotEmpty &&
          (cleanUrlText.endsWith('.') ||
           cleanUrlText.endsWith(',') ||
           cleanUrlText.endsWith('?') ||
           cleanUrlText.endsWith('!'))) {
        trailingPunctuation = cleanUrlText.substring(cleanUrlText.length - 1) + trailingPunctuation;
        cleanUrlText = cleanUrlText.substring(0, cleanUrlText.length - 1);
      }

      final linkUrl = cleanUrlText.toLowerCase().startsWith('www.')
          ? 'https://$cleanUrlText'
          : cleanUrlText;

      final isDarkBg = style.color == Colors.white || 
                       style.color == appColor(context).white;
      final linkColor = isDarkBg ? const Color(0xFF90CAF9) : const Color(0xFF1565C0);

      spans.add(
        TextSpan(
          text: cleanUrlText,
          style: style.copyWith(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              try {
                final uri = Uri.parse(linkUrl);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint("Could not launch $linkUrl: $e");
              }
            },
        ),
      );

      if (trailingPunctuation.isNotEmpty) {
        spans.addAll(_getHighlightSpans(context, trailingPunctuation));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final plainText = text.substring(lastIndex);
      spans.addAll(_getHighlightSpans(context, plainText));
    }

    return RichText(text: TextSpan(children: spans));
  }

  List<TextSpan> _getHighlightSpans(BuildContext context, String chunk) {
    if (!isSearchActive ||
        query.isEmpty ||
        !chunk.toLowerCase().contains(query.toLowerCase())) {
      return [TextSpan(text: chunk, style: style)];
    }

    final List<TextSpan> spans = [];
    final String chunkLower = chunk.toLowerCase();
    final String queryLower = query.toLowerCase();
    int start = 0;

    while (true) {
      final int index = chunkLower.indexOf(queryLower, start);
      if (index == -1) {
        spans.add(TextSpan(text: chunk.substring(start), style: style));
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: chunk.substring(start, index), style: style),
        );
      }

      spans.add(
        TextSpan(
          text: chunk.substring(index, index + query.length),
          style: style.copyWith(
            backgroundColor: appColor(context).primary.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + query.length;
    }
    return spans;
  }
}

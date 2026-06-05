import 'package:flutter_test/flutter_test.dart';
import 'package:shieldconnect_app/utils/date_helper.dart';

bool shouldShowNewGroupBadge({
  required bool isGroup,
  required String messageContentRaw,
  required String groupName,
  required String? createdAtStr,
  required DateTime now,
}) {
  String messageContent = messageContentRaw;
  if (isGroup) {
    final String msgLower = messageContentRaw.toLowerCase();
    if (msgLower.contains("created") ||
        msgLower.contains("system_group_created")) {
      messageContent = 'Group "$groupName" created';
    }
  }

  bool showNewGroupBadge = false;
  if (isGroup &&
      (messageContent == 'No messages yet' || messageContent == 'Group "$groupName" created') &&
      createdAtStr != null) {
    try {
      final DateTime createdAt = DateTime.parse(createdAtStr).toUtc();
      final Duration difference = now.difference(createdAt);
      if (difference.inHours >= 0 && difference.inHours < 10) {
        showNewGroupBadge = true;
      }
    } catch (_) {}
  }
  return showNewGroupBadge;
}

void main() {
  group('New Group Badge Tests', () {
    final DateTime now = DateTime.now().toUtc();

    test('Show badge when no messages yet and created within 10 hours', () {
      final createdAtStr = now.subtract(const Duration(hours: 5)).toIso8601String();
      final result = shouldShowNewGroupBadge(
        isGroup: true,
        messageContentRaw: 'No messages yet',
        groupName: 'Test Group',
        createdAtStr: createdAtStr,
        now: now,
      );
      expect(result, isTrue);
    });

    test('Show badge when message content is group created and created within 10 hours', () {
      final createdAtStr = now.subtract(const Duration(hours: 9)).toIso8601String();
      final result = shouldShowNewGroupBadge(
        isGroup: true,
        messageContentRaw: 'Group "Test Group" created',
        groupName: 'Test Group',
        createdAtStr: createdAtStr,
        now: now,
      );
      expect(result, isTrue);
    });

    test('Do not show badge if created more than 10 hours ago', () {
      final createdAtStr = now.subtract(const Duration(hours: 11)).toIso8601String();
      final result = shouldShowNewGroupBadge(
        isGroup: true,
        messageContentRaw: 'Group "Test Group" created',
        groupName: 'Test Group',
        createdAtStr: createdAtStr,
        now: now,
      );
      expect(result, isFalse);
    });

    test('Do not show badge if not a group chat', () {
      final createdAtStr = now.subtract(const Duration(hours: 2)).toIso8601String();
      final result = shouldShowNewGroupBadge(
        isGroup: false,
        messageContentRaw: 'Group "Test Group" created',
        groupName: 'Test Group',
        createdAtStr: createdAtStr,
        now: now,
      );
      expect(result, isFalse);
    });
  });

  group('DateHelper Tests', () {
    test('formatTime with empty/null input returns empty string', () {
      expect(DateHelper.formatTime(null), "");
      expect(DateHelper.formatTime(""), "");
    });

    test('formatDate with empty/null input returns empty string', () {
      expect(DateHelper.formatDate(null), "");
      expect(DateHelper.formatDate(""), "");
    });
  });
}

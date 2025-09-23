import 'package:stream_video_flutter/stream_video_flutter.dart';

import 'tutorial_user.dart';

String displayNameFromCallUser(CallUser user) {
  final name = user.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return displayNameFromUserId(user.id);
}

String displayNameFromUserId(String userId) {
  for (final tutorialUser in TutorialUser.users) {
    if (tutorialUser.user.id == userId) {
      return tutorialUser.user.name ?? userId;
    }
  }
  return userId;
}

String formatNameList(List<String> names) {
  final filtered = <String>[];
  final seen = <String>{};
  for (final name in names) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      continue;
    }
    if (seen.add(trimmed)) {
      filtered.add(trimmed);
    }
  }

  if (filtered.isEmpty) {
    return '';
  }
  if (filtered.length == 1) {
    return filtered.first;
  }
  if (filtered.length == 2) {
    return '${filtered[0]} and ${filtered[1]}';
  }
  final allButLast = filtered.sublist(0, filtered.length - 1).join(', ');
  return '$allButLast, and ${filtered.last}';
}

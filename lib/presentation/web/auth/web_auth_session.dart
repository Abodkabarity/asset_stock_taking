import 'package:flutter/foundation.dart';

@immutable
class WebAppUser {
  final String id;
  final String email;
  final String userName;
  final String role;
  final bool isActive;

  const WebAppUser({
    required this.id,
    required this.email,
    required this.userName,
    required this.role,
    required this.isActive,
  });

  String get roleLabel =>
      role.toLowerCase() == 'admin' ? 'Administrator' : role;

  String get initials {
    final words = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (words.isEmpty) return 'AP';
    return words.map((word) => word[0].toUpperCase()).join();
  }
}

class WebAuthSession {
  WebAuthSession._();

  static final ValueNotifier<WebAppUser?> currentUser =
      ValueNotifier<WebAppUser?>(null);

  static void setUser(WebAppUser user) => currentUser.value = user;

  static void clear() => currentUser.value = null;
}

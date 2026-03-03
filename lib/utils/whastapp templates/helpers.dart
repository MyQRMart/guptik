import 'package:flutter/foundation.dart';

List<String> extractVariables(String text) {
  final RegExp regex = RegExp(r'\{\{(\d+)\}\}');
  final matches = regex.allMatches(text);
  return matches.map((m) => m.group(0)!).toSet().toList();
}

String formatPhoneNumber(String phone) {
  return phone.replaceAll('+', '').replaceAll(' ', '').replaceAll('-', '');
}

void logDebug(String message) {
  debugPrint('📱 WhatsApp: $message');
}

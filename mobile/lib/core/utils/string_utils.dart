import 'dart:io';

String toTurkishTitleCase(String text) {
  if (text.trim().isEmpty) return text;
  return text.trim().split(RegExp(r'\s+')).map((word) {
    if (word.isEmpty) return '';
    final firstChar = word[0];
    final rest = word.substring(1).toLowerCase();
    String upperFirst;
    if (firstChar == 'i' || firstChar == 'İ') {
      upperFirst = 'İ';
    } else if (firstChar == 'ı' || firstChar == 'I') {
      upperFirst = 'I';
    } else {
      upperFirst = firstChar.toUpperCase();
    }
    return '$upperFirst$rest';
  }).join(' ');
}

String? getFormattedImageUrl(String? rawUrl) {
  if (rawUrl == null || rawUrl.trim().isEmpty) return null;
  final trimmed = rawUrl.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return trimmed;
  }
  final baseUrl = Platform.isAndroid ? 'http://10.0.2.2:3000' : 'http://localhost:3000';
  if (trimmed.startsWith('/')) {
    return '$baseUrl$trimmed';
  }
  return '$baseUrl/$trimmed';
}


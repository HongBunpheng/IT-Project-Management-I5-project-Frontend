import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';

/// Safe wrapper for Locales.string that handles null cases
String safeLocaleString(BuildContext context, String key, {String? fallback}) {
  try {
    return Locales.string(context, key);
  } catch (e) {
    // Return fallback or key if locale string fails
    return fallback ?? key;
  }
}

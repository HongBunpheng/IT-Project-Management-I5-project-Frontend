import 'package:flutter/material.dart';
import 'package:flutter_locales/flutter_locales.dart';

/// Safe wrapper for Locales.string that handles null cases
String safeLocaleString(BuildContext context, String key, {String? fallback}) {
  try {
    final value = Locales.string(context, key);

    // Some locale files may accidentally contain "$key" placeholders.
    // Treat those as missing so we fall back to a human-readable string.
    if (value == '\$$key') {
      return fallback ?? key;
    }

    return value;
  } catch (e) {
    // Return fallback or key if locale string fails
    return fallback ?? key;
  }
}

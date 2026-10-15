import 'package:flutter/foundation.dart';

/// Debug-only logger. Calls are no-ops in profile/release builds, so nothing
/// is written to the device log of a Play Store build.
///
/// Never pass tokens, passwords, OTPs or other credentials to this logger.
void appLog(String message) {
  if (kDebugMode) {
    debugPrint(message);
  }
}

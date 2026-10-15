import 'package:url_launcher/url_launcher.dart';

/// Opens [url] in the external browser, falling back to the platform default.
/// Returns `false` when no application could handle the URL.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.parse(url);
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
    return await launchUrl(uri);
  } catch (_) {
    return false;
  }
}

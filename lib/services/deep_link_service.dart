import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DeepLinkService {
  final FirebaseDynamicLinks _dynamicLinks;

  DeepLinkService({FirebaseDynamicLinks? dynamicLinks})
      : _dynamicLinks = dynamicLinks ?? FirebaseDynamicLinks.instance;

  Future<String> createDynamicLink({
    required String path,
    required Map<String, String> parameters,
    String? title,
    String? description,
    String? imageUrl,
  }) async {
    final dynamicLinkParams = DynamicLinkParameters(
      uriPrefix: 'https://yourdomain.page.link',
      link: Uri.parse('https://yourdomain.com/$path?${_buildQueryString(parameters)}'),
      androidParameters: const AndroidParameters(
        packageName: 'com.yourcompany.yourapp',
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.yourcompany.yourapp',
        minimumVersion: '1.0',
        appStoreId: '123456789',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: title,
        description: description,
        imageUrl: imageUrl != null ? Uri.parse(imageUrl) : null,
      ),
    );

    final dynamicLink = await _dynamicLinks.buildLink(dynamicLinkParams);
    return dynamicLink.toString();
  }

  Future<Map<String, String>?> handleDynamicLink() async {
    final initialLink = await _dynamicLinks.getInitialLink();
    if (initialLink != null) {
      return _extractParameters(initialLink.link);
    }

    _dynamicLinks.onLink.listen((pendingLink) {
      _extractParameters(pendingLink.link);
    });

    return null;
  }

  Map<String, String> _extractParameters(Uri uri) {
    return uri.queryParameters;
  }

  String _buildQueryString(Map<String, String> params) {
    return params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
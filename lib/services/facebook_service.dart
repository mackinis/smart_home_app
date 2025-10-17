import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FacebookService {
  static Future<Map<String, dynamic>?> signIn() async {
    try {
      final result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final userData = await FacebookAuth.instance.getUserData();
        return userData;
      }
      return null;
    } catch (e) {
      print('❌ Error Facebook: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    await FacebookAuth.instance.logOut();
  }
}
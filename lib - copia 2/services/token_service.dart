import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class TokenService {
  static const String _key = 'user';

  static Future<void> saveUser(UserModel user) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final sp = await SharedPreferences.getInstance();
    final data = sp.getString(_key);
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  static Future<void> clearUser() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_key);
  }
}
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/device.dart';

const _key = 'devices';

Future<void> saveDevices(List<Device> devices) async {
  final sp = await SharedPreferences.getInstance();
  final list = devices.map((d) => jsonEncode(d.toJson())).toList();
  await sp.setStringList(_key, list);
}

Future<List<Device>> loadDevices() async {
  final sp = await SharedPreferences.getInstance();
  final list = sp.getStringList(_key) ?? [];
  return list.map((s) => Device.fromJson(jsonDecode(s))).toList();
}
import 'device.dart';

class Room {
  final String id;
  String name;
  final List<Device> devices;

  Room({required this.id, required this.name, List<Device>? devices})
      : devices = devices ?? [];
}
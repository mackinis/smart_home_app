import 'device_type.dart';
import 'device_action.dart';

class Device {
  final String id;
  String name;
  String room;
  String broker;
  int port;
  String username;
  String password;
  String topicCmd;
  String topicStatus;
  final DeviceType type;

  Device({
    required this.id,
    required this.name,
    required this.room,
    required this.broker,
    required this.port,
    this.username = '',
    this.password = '',
    required this.topicCmd,
    required this.topicStatus,
    this.type = DeviceType.accessControl,
  });

  List<DeviceAction> get actions => type.actions;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'room': room,
        'broker': broker,
        'port': port,
        'username': username,
        'password': password,
        'topicCmd': topicCmd,
        'topicStatus': topicStatus,
        'type': type.name,
      };

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['id'],
        name: j['name'],
        room: j['room'],
        broker: j['broker'],
        port: j['port'],
        username: j['username'] ?? '',
        password: j['password'] ?? '',
        topicCmd: j['topicCmd'],
        topicStatus: j['topicStatus'],
        type: DeviceType.values.byName(j['type']),
      );
}
import 'dart:io';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient buildMqttClient(String broker, int port, String clientId) {
  final client = MqttServerClient(broker, clientId)
    ..port = port
    ..useWebSocket = false
    ..secure = true
    ..securityContext = SecurityContext.defaultContext;
  return client;
}
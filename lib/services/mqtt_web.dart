import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

MqttClient buildMqttClient(String broker, int port, String clientId) {
  final uri = 'wss://$broker:$port/mqtt';
  return MqttBrowserClient(uri, clientId);
}
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import '../models/device.dart';
import '../widgets/action_button.dart';
// 2️⃣ Quitamos: import 'dart:io';
import '../models/device_type.dart';
import '../services/mqtt_wrapper.dart';

class DeviceCardScreen extends StatefulWidget {
  final Device device;
  const DeviceCardScreen({super.key, required this.device});

  @override
  State<DeviceCardScreen> createState() => _DeviceCardScreenState();
}

class _DeviceCardScreenState extends State<DeviceCardScreen> {
  late MqttClient client;   // 3️⃣
  bool _connected = false;
  String _lastResponse = '';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    final d = widget.device;

    // 4️⃣ URI WebSocket (wss si es seguro)
    client = buildMqttClient(d.broker, d.port, 'flutter_${d.id}');

    client.port = d.port;
    client.logging(on: false);
    client.onConnected = () => setState(() => _connected = true);
    client.onDisconnected = () => setState(() => _connected = false);

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_${d.id}')
        .startClean()
        .authenticateAs(d.username, d.password);
    client.connectionMessage = connMess;

    // 6️⃣ Quitamos SecurityContext

    try {
      await client.connect();
    } catch (e) {
      print('>>> ERROR MQTT: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      client.subscribe(d.topicStatus, MqttQos.atLeastOnce);
      client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
        final recMess = c![0].payload as MqttPublishMessage;
        final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
        final natural = _extractNatural(pt);
        setState(() => _lastResponse = natural);
      });
    }
  }

  String _extractNatural(String raw) {
    try {
      final json = Map<String, dynamic>.from(_jsonDecode(raw));
      if (json.containsKey('detail')) return json['detail'].toString();
      if (json.containsKey('status') && json.containsKey('detail')) {
        return '${json['status']}. ${json['detail']}';
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  Map<String, dynamic> _jsonDecode(String src) {
    final m = <String, dynamic>{};
    final reg = RegExp(r'"(\w+)":"([^"]*)"');
    for (final match in reg.allMatches(src)) {
      m[match.group(1)!] = match.group(2)!;
    }
    return m;
  }

  void _sendCommand(String cmd) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(cmd);
    client.publishMessage(widget.device.topicCmd, MqttQos.atLeastOnce, builder.payload!);
  }

  void _fetchInfo() => _sendCommand('info');

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.name)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Zona: ${widget.device.room}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Broker: ${widget.device.broker}:${widget.device.port}', style: const TextStyle(fontSize: 14)),
            Text('Topic CMD: ${widget.device.topicCmd}', style: const TextStyle(fontSize: 14)),
            Text('Topic STATUS: ${widget.device.topicStatus}', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('Info'),
                onPressed: _connected ? _fetchInfo : null,
              ),
            ),
            const SizedBox(height: 20),
            Text('Última respuesta:', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_lastResponse, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 2.2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: (widget.device.actions ?? DeviceType.accessControl.actions)
                    .map((action) => ActionButton(
                          action: action,
                          onExecute: (cmd) => _sendCommand(cmd),
                          enabled: _connected,
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
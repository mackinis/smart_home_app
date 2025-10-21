import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';
import '../models/device.dart';
import '../models/room.dart';
import '../models/device_action.dart';
import '../services/mqtt_wrapper.dart';
import 'add_device_screen.dart';

class DevicesListScreen extends StatefulWidget {
  final Room room;
  const DevicesListScreen({super.key, required this.room});

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  late Room _room;
  late MqttClient _mqttClient;
  final Map<String, bool> _connected = {};
  final Map<String, String?> _detail = {};
  final Map<String, Timer> _timers = {};

  @override
  void initState() {
    super.initState();
    _room = widget.room;
    _connectMqtt();
  }

  Future<void> _connectMqtt() async {
    if (_room.devices.isEmpty) return;
    final d = _room.devices.first;

    _mqttClient = buildMqttClient(d.broker, d.port, 'flutter_room_${d.room}');
    _mqttClient.port = d.port;
    _mqttClient.logging(on: false);

    final connMess = MqttConnectMessage()
        .withClientIdentifier('flutter_room_${d.room}')
        .startClean()
        .authenticateAs(d.username, d.password);
    _mqttClient.connectionMessage = connMess;

    try {
      await _mqttClient.connect();
      _room.devices.forEach((dev) => _connected[dev.id] = true);
      _subscribeToStatus();
    } catch (e) {
      print('>>> ERROR MQTT: $e');
      _mqttClient.disconnect();
      _room.devices.forEach((dev) => _connected[dev.id] = false);
    }
    if (mounted) setState(() {});
  }

  void _subscribeToStatus() {
    for (final d in _room.devices) {
      _mqttClient.subscribe(d.topicStatus, MqttQos.atLeastOnce);
    }

    _mqttClient.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? msgs) {
      if (msgs == null || msgs.isEmpty) return;
      final msg = msgs[0].payload as MqttPublishMessage;
      final topic = msg.variableHeader!.topicName;
      final payload = MqttPublishPayload.bytesToStringAsString(msg.payload.message);
      final device = _room.devices.firstWhere((d) => topic == d.topicStatus);

      String? onlyDetail = _extractDetail(payload);
      if (onlyDetail == null) return;

      if (mounted) {
        setState(() => _detail[device.id] = onlyDetail);
      }
      _timers[device.id]?.cancel();
      _timers[device.id] = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _detail[device.id] = null);
        }
      });
    });
  }

  String? _extractDetail(String raw) {
    try {
      final json = Map<String, dynamic>.from(_jsonDecode(raw));
      return json['detail']?.toString();
    } catch (_) {
      return raw.trim().isEmpty ? null : raw.trim();
    }
  }

  Map<String, dynamic> _jsonDecode(String src) {
    final m = <String, dynamic>{};
    RegExp(r'"(\w+)":"([^"]*)"').allMatches(src).forEach((m2) {
      m[m2.group(1)!] = m2.group(2)!;
    });
    return m;
  }

  void _sendCommand(Device d, String cmd) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(cmd);
    _mqttClient.publishMessage(d.topicCmd, MqttQos.atLeastOnce, builder.payload!);
  }

  void _fetchInfo(Device d) {
    _sendCommand(d, 'info');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Info - ${d.name}'),
        content: SingleChildScrollView(
          child: Text(_detail[d.id] ?? 'Esperando respuesta...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_),
              child: const Text('CERRAR')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList('devices') ?? [];
    final others = raw.map((s) => Device.fromJson(jsonDecode(s)))
        .where((dev) => dev.room != _room.name)
        .toList();
    final updated = <Device>[...others, ..._room.devices];
    await sp.setStringList('devices',
        updated.map((d) => jsonEncode(d.toJson())).toList());
  }

  void _addDevice() async {
    final newDev = await Navigator.push<Device>(
      context,
      MaterialPageRoute(
          builder: (_) => AddDeviceScreen(room: _room.name)),
    );
    if (newDev != null) {
      setState(() => _room.devices.add(newDev));
      _connected[newDev.id] = _mqttClient.connectionStatus?.state ==
          MqttConnectionState.connected;
      await _save();
    }
  }

  void _toggleDevice(Device d) async {
    if (_mqttClient.connectionStatus?.state != MqttConnectionState.connected) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sin conexión MQTT')));
      return;
    }
    setState(() => d.status = !d.status);
    _connected[d.id] = d.status;
    await _save();
  }

  void _deleteDevice(Device d) async {
    setState(() => _room.devices.remove(d));
    await _save();
  }

  void _editDevice(Device d) async {
    final edited = await Navigator.push<Device>(
      context,
      MaterialPageRoute(
          builder: (_) => AddDeviceScreen(room: _room.name, device: d)),
    );
    if (edited != null) {
      final index = _room.devices.indexWhere((e) => e.id == d.id);
      if (index != -1) {
        setState(() => _room.devices[index] = edited);
        await _save();
      }
    }
  }

  Future<void> _executeAction(Device d, DeviceAction action) async {
    if (!_connected[d.id]!) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dispositivo desconectado')));
      return;
    }

    if (action.params.isNotEmpty) {
      final values = <String, String>{};
      for (final p in action.params) {
        final ctrl = TextEditingController();
        final value = await showDialog<String>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(action.label),
            content: TextField(
              controller: ctrl,
              decoration: InputDecoration(labelText: p.label),
              obscureText: p.obscure,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(_, null),
                  child: const Text('CANCELAR')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(_, ctrl.text.trim()),
                  child: const Text('ENVIAR')),
            ],
          ),
        );
        if (value == null || value.isEmpty) return;
        if (p.regex != null && !RegExp(p.regex!).hasMatch(value)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Formato inválido: ${p.label}')));
          return;
        }
        values[p.key] = value;
      }
      String cmd = action.commandTemplate;
      values.forEach((k, v) => cmd = cmd.replaceAll('{$k}', v));
      _sendCommand(d, cmd);
      return;
    }
    _sendCommand(d, action.commandTemplate);
  }

  @override
  void dispose() {
    _mqttClient.disconnect();
    _timers.values.forEach((t) => t.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 100,
              alignment: Alignment.center,
              child: Image.asset('assets/logo.png', height: 80),
            ),
            const Text(
              'Dispositivos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'back',
                    onPressed: () => Navigator.pop(context),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 12),
                  FloatingActionButton.small(
                    heroTag: 'add',
                    onPressed: _addDevice,
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _room.devices.isEmpty
                  ? const Center(child: Text('Sin dispositivos'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _room.devices.length,
                      itemBuilder: (_, i) {
                        final d = _room.devices[i];
                        final bool on = _connected[d.id] ?? false;
                        final String? detail = _detail[d.id];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 4,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // STACK: fondo = texto centrado, frente = contenido normal
                              Stack(
                                children: [
                                  // Capa inferior: texto centrado
                                  if (detail != null)
                                    Positioned.fill(
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          detail,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Capa superior: ListTile original
                                  ListTile(
                                    leading: Icon(d.type.icon,
                                        color: on ? Colors.green : Colors.grey),
                                    title: Text(d.name),
                                    subtitle: Text(on ? 'Encendido' : 'Apagado'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.info_outline,
                                              color: Colors.blue),
                                          onPressed: () => _fetchInfo(d),
                                        ),
                                        Switch(
                                            value: on,
                                            onChanged: (_) => _toggleDevice(d)),
                                        IconButton(
                                            icon: const Icon(Icons.edit_outlined,
                                                color: Colors.indigo),
                                            onPressed: () => _editDevice(d)),
                                        IconButton(
                                            icon: const Icon(Icons.delete_outline,
                                                color: Colors.red),
                                            onPressed: () => _deleteDevice(d)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 8),
                                    ...d.actions.map((a) => Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.send, size: 18),
                                            label: Text(a.label),
                                            onPressed: on
                                                ? () => _executeAction(d, a)
                                                : null,
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
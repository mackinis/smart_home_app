import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/device.dart';
import '../models/room.dart';
import '../models/device_action.dart'; // <-- agregado para que compile
import '../widgets/logo_scaffold.dart';
import 'add_device_screen.dart';

class DevicesListScreen extends StatefulWidget {
  final Room room;
  const DevicesListScreen({super.key, required this.room});

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  late Room _room;

  @override
  void initState() {
    super.initState();
    _room = widget.room;
  }

  /* ---------- Persistencia ---------- */
  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getStringList('devices') ?? [];
    final others = raw.map((s) => Device.fromJson(jsonDecode(s))).where((d) => d.room != _room.name).toList();
    final updated = <Device>[...others, ..._room.devices];
    await sp.setStringList('devices', updated.map((d) => jsonEncode(d.toJson())).toList());
  }

  /* ---------- Nuevo dispositivo ---------- */
  void _addDevice() async {
    final newDev = await Navigator.push<Device>(
      context,
      MaterialPageRoute(builder: (_) => AddDeviceScreen(room: _room.name)), // <-- TU CONSTRUCTOR ORIGINAL
    );
    if (newDev != null) {
      setState(() => _room.devices.add(newDev));
      await _save();
    }
  }

  /* ---------- ON / OFF (IGUAL QUE ANTES) ---------- */
  void _toggleDevice(Device d) async {
    setState(() => d.status = !d.status);
    await _save();
  }

  /* ---------- BORRAR (IGUAL QUE ANTES) ---------- */
  void _deleteDevice(Device d) async {
    setState(() => _room.devices.remove(d));
    await _save();
  }

  /* ---------- EDITAR (EXTRA) ---------- */
  void _editDevice(Device d) async {
    final edited = await Navigator.push<Device>(
      context,
      MaterialPageRoute(builder: (_) => AddDeviceScreen(room: _room.name, device: d)), // <-- TU CONSTRUCTOR ORIGINAL
    );
    if (edited != null) {
      final index = _room.devices.indexWhere((e) => e.id == d.id);
      if (index != -1) {
        setState(() => _room.devices[index] = edited);
        await _save();
      }
    }
  }

  /* ---------- COMANDOS CON TU MQTT REAL ---------- */
  Future<void> _executeAction(Device d, DeviceAction action) async {
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
              TextButton(onPressed: () => Navigator.pop(_), child: const Text('CANCELAR')),
              ElevatedButton(onPressed: () => Navigator.pop(_, ctrl.text.trim()), child: const Text('ENVIAR')),
            ],
          ),
        );
        if (value == null || value.isEmpty) return;
        if (p.regex != null && !RegExp(p.regex!).hasMatch(value)) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Formato inválido: ${p.label}')));
          return;
        }
        values[p.key] = value;
      }
      String cmd = action.commandTemplate;
      values.forEach((k, v) => cmd = cmd.replaceAll('{$k}', v));
      _sendCommand(d, cmd);
      return;
    }
    // Sin parámetros: mandamos directo
    _sendCommand(d, action.commandTemplate);
  }

  /* ---------- ENVÍO POR MQTT (TU CÓDIGO) ---------- */
  void _sendCommand(Device d, String cmd) {
    // >>>>>>>>>  ACÁ PONÉS TU CÓDIGO MQTT REAL  <<<<<<<<<
    // Ejemplo con tu cliente (ya lo tenías andando antes):
    // client.publishMessage(d.topicCmd, MqttQos.atLeastOnce, Uint8List.fromList(utf8.encode(cmd)));
    // Mientras tanto mostramos el comando y lo imprimimos:
    print('>>> ENVÍO MQTT a ${d.topicCmd} : $cmd');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Comando enviado: $cmd')));
  }

  /* ---------- UI - TU CARD ORIGINAL ---------- */
  @override
  Widget build(BuildContext context) {
    return LogoScaffold(
      title: 'Dispositivos',
      showBackButton: true,
      body: _room.devices.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sin dispositivos'),
                const SizedBox(height: 12),
                FilledButton.icon(onPressed: _addDevice, icon: const Icon(Icons.add), label: const Text('Agregar dispositivo')),
              ],
            ))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _room.devices.length,
              itemBuilder: (_, i) {
                final d = _room.devices[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 4,
                  child: ExpansionTile(
                    leading: Icon(d.type.icon, color: d.status ? Colors.green : Colors.grey),
                    title: Text(d.name),
                    subtitle: Text(d.status ? 'Encendido' : 'Apagado'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(value: d.status, onChanged: (_) => _toggleDevice(d)),
                        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.indigo), onPressed: () => _editDevice(d)),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _deleteDevice(d)),
                      ],
                    ),
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Comandos:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...d.actions.map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.send, size: 18),
                                    label: Text(a.label),
                                    onPressed: () => _executeAction(d, a),
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
    );
  }
}
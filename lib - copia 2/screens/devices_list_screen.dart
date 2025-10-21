import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../models/room.dart';
import '../models/device.dart';
import '../models/device_type.dart';
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
    // dispositivos que NO pertenecen a esta habitación
    final others = raw
        .map((s) => Device.fromJson(jsonDecode(s)))
        .where((d) => d.room != _room.name)
        .toList();
    // unificamos
    final updated = <Device>[...others, ..._room.devices];
    await sp.setStringList(
        'devices', updated.map((d) => jsonEncode(d.toJson())).toList());
  }

  /* ---------- Nuevo dispositivo ---------- */
  void _addDevice() async {
    final newDev = await Navigator.push<Device>(
      context,
      MaterialPageRoute(
        builder: (_) => AddDeviceScreen(roomName: _room.name),
      ),
    );
    if (newDev != null) {
      setState(() => _room.devices.add(newDev));
      await _save();
    }
  }

  /* ---------- ON / OFF ---------- */
  void _toggleDevice(Device d) async {
    setState(() => d.status = !d.status);
    await _save();
  }

  /* ---------- Borrar (long-press) ---------- */
  void _deleteDevice(Device d) async {
    setState(() => _room.devices.remove(d));
    await _save();
  }

  /* ---------- UI ---------- */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: Text(_room.name),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _addDevice),
        ],
      ),
      body: _room.devices.isEmpty
          ? const Center(child: Text('Sin dispositivos\nPresioná + para agregar'))
          : ListView.builder(
              itemCount: _room.devices.length,
              itemBuilder: (_, i) {
                final d = _room.devices[i];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 4,
                  child: ListTile(
                    leading: Icon(
                      d.type.icon,
                      color: d.status ? Colors.green : Colors.grey,
                    ),
                    title: Text(d.name),
                    subtitle: Text(d.status ? 'Encendido' : 'Apagado'),
                    trailing: Switch(
                      value: d.status,
                      onChanged: (_) => _toggleDevice(d),
                    ),
                    onLongPress: () => _deleteDevice(d),
                  ),
                );
              },
            ),
    );
  }
}
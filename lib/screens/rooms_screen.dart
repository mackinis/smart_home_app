import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_device_screen.dart';
import 'devices_list_screen.dart';
import '../models/room.dart';
import '../models/device.dart';
import '../models/device_type.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final List<Room> _rooms = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList('devices') ?? [];
    final devices = list.map((s) => Device.fromJson(jsonDecode(s))).toList();
    final map = <String, Room>{};
    for (final d in devices) {
      map.putIfAbsent(d.room, () => Room(id: d.room, name: d.room));
      map[d.room]!.devices.add(d);
    }
    setState(() => _rooms..clear()..addAll(map.values));
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    final devices = _rooms.expand((r) => r.devices).toList();
    await sp.setStringList('devices', devices.map((d) => jsonEncode(d.toJson())).toList());
  }

  void _addRoom() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva zona'),
        content: TextField(autofocus: true, onSubmitted: (n) => Navigator.pop(_, n)),
        actions: [TextButton(onPressed: () => Navigator.pop(_, null), child: const Text('CANCELAR'))],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => _rooms.add(Room(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name)));
      await _save();
    }
  }

  void _editRoom(Room room) async {
    final ctrl = TextEditingController(text: room.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar zona'),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, null), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(_, ctrl.text), child: const Text('GUARDAR')),
        ],
      ),
    );
    if (newName != null && newName.isNotEmpty) {
      setState(() => room.name = newName);
      await _save();
    }
  }

  void _deleteRoom(Room room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Borrar zona?'),
        content: const Text('Se perderán todos sus dispositivos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(_, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(_, true), child: const Text('BORRAR')),
        ],
      ),
    );
    if (ok == true) {
      setState(() => _rooms.remove(room));
      await _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        title: const Text('Zonas'),
        actions: [
          IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _addRoom),
        ],
      ),
      body: _rooms.isEmpty
          ? const Center(child: Text('Sin zonas\nPresioná + para agregar'))
          : ListView.builder(
              itemCount: _rooms.length,
              itemBuilder: (_, i) => Card(
                child: ListTile(
                  title: Text(_rooms[i].name),
                  subtitle: Text('${_rooms[i].devices.length} dispositivos'),
                  trailing: PopupMenuButton<int>(
                    onSelected: (val) {
                      if (val == 1) _editRoom(_rooms[i]);
                      if (val == 2) _deleteRoom(_rooms[i]);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 1, child: Text('Editar')),
                      const PopupMenuItem(value: 2, child: Text('Borrar')),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DevicesListScreen(room: _rooms[i])),
                  ),
                ),
              ),
            ),
    );
  }
}
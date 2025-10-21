import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/room.dart';
import '../models/device.dart';
import 'devices_list_screen.dart';

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
    await sp.setStringList('devices',
        devices.map((d) => jsonEncode(d.toJson())).toList());
  }

  void _addRoom() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nueva zona'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre de la zona'),
          onSubmitted: (n) => Navigator.pop(_, n),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_, null),
              child: const Text('CANCELAR')),
          ElevatedButton(
              onPressed: () => Navigator.pop(_, ctrl.text.trim()),
              child: const Text('ACEPTAR')),
        ],
      ),
    );
    if (name != null && name.trim().isNotEmpty) {
      setState(() => _rooms.add(Room(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: name.trim())));
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
          TextButton(
              onPressed: () => Navigator.pop(_, null),
              child: const Text('CANCELAR')),
          ElevatedButton(
              onPressed: () => Navigator.pop(_, ctrl.text.trim()),
              child: const Text('GUARDAR')),
        ],
      ),
    );
    if (newName != null && newName.trim().isNotEmpty) {
      setState(() => room.name = newName.trim());
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
          TextButton(
              onPressed: () => Navigator.pop(_, false),
              child: const Text('CANCELAR')),
          ElevatedButton(
              onPressed: () => Navigator.pop(_, true),
              child: const Text('BORRAR')),
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
              'Zonas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _rooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Sin zonas'),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _addRoom,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar zona'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _rooms.length,
                      itemBuilder: (_, i) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(_rooms[i].name),
                          subtitle: Text('${_rooms[i].devices.length} dispositivos'),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => DevicesListScreen(room: _rooms[i])),
                          ),
                          trailing: PopupMenuButton<int>(
                            onSelected: (v) {
                              if (v == 1) _editRoom(_rooms[i]);
                              if (v == 2) _deleteRoom(_rooms[i]);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 1, child: Text('Editar')),
                              const PopupMenuItem(value: 2, child: Text('Borrar')),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRoom,
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/device.dart';
import 'add_device_screen.dart';
import 'device_card.dart';


class DevicesListScreen extends StatefulWidget {
  final Room room;
  const DevicesListScreen({super.key, required this.room});

  @override
  State<DevicesListScreen> createState() => _DevicesListScreenState();
}

class _DevicesListScreenState extends State<DevicesListScreen> {
  void _addDevice() async {
    final newDev = await Navigator.of(context).push<Device>(
      MaterialPageRoute(builder: (_) => AddDeviceScreen(room: widget.room.name)),
    );
    if (newDev != null) setState(() => widget.room.devices.add(newDev));
  }

  void _editDevice(Device dev) async {
    final edited = await Navigator.of(context).push<Device>(
      MaterialPageRoute(builder: (_) => AddDeviceScreen(room: widget.room.name, device: dev)),
    );
    if (edited != null) {
      setState(() {
        final idx = widget.room.devices.indexOf(dev);
        if (idx != -1) widget.room.devices[idx] = edited;
      });
    }
  }

  void _deleteDevice(Device dev) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Borrar dispositivo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('BORRAR')),
        ],
      ),
    );
    if (ok == true) setState(() => widget.room.devices.remove(dev));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.room.name)),
      body: widget.room.devices.isEmpty
          ? const Center(child: Text('Sin dispositivos en esta zona'))
          : ListView.builder(
              itemCount: widget.room.devices.length,
              itemBuilder: (_, i) {
                final dev = widget.room.devices[i];
                return Card(
                  child: ListTile(
                    title: Text(dev.name),
                    subtitle: Text('${dev.broker}:${dev.port}  ${dev.topicCmd}'),
                    trailing: PopupMenuButton<int>(
                      onSelected: (val) {
                        if (val == 1) _editDevice(dev);
                        if (val == 2) _deleteDevice(dev);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 1, child: Text('Editar')),
                        const PopupMenuItem(value: 2, child: Text('Borrar')),
                      ],
                    ),
onTap: () => Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => DeviceCardScreen(device: dev)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: _addDevice,
      ),
    );
  }
}
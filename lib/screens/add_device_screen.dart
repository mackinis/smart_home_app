import 'package:flutter/material.dart';
import '../models/device.dart';
import '../models/device_type.dart';

class AddDeviceScreen extends StatelessWidget {
  final String room;
  final Device? device; // null → alta, !null → edición
  const AddDeviceScreen({super.key, required this.room, this.device});

  @override
  Widget build(BuildContext context) {
    final name = TextEditingController(text: device?.name ?? '');
    final roomCtrl = TextEditingController(text: room);
    final broker = TextEditingController(text: device?.broker ?? '');
    final port = TextEditingController(text: (device?.port ?? 1883).toString());
    final user = TextEditingController(text: device?.username ?? '');
    final pass = TextEditingController(text: device?.password ?? '');
    final cmdTopic = TextEditingController(text: device?.topicCmd ?? '');
    final statTopic = TextEditingController(text: device?.topicStatus ?? '');

    DeviceType type = device?.type ?? DeviceType.accessControl;

    return Scaffold(
      appBar: AppBar(title: Text(device == null ? 'Agregar dispositivo' : 'Editar dispositivo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: roomCtrl, readOnly: true, decoration: const InputDecoration(labelText: 'Zona')),
            TextField(controller: broker, decoration: const InputDecoration(labelText: 'Broker IP')),
            TextField(controller: port, decoration: const InputDecoration(labelText: 'Puerto'), keyboardType: TextInputType.number),
            TextField(controller: user, decoration: const InputDecoration(labelText: 'Usuario (opcional)')),
            TextField(controller: pass, decoration: const InputDecoration(labelText: 'Clave (opcional)')),
            TextField(controller: cmdTopic, decoration: const InputDecoration(labelText: 'Topic CMD (ej: casa)')),
            TextField(controller: statTopic, decoration: const InputDecoration(labelText: 'Topic STATUS (ej: casa/response)')),
            const SizedBox(height: 12),
            DropdownButtonFormField<DeviceType>(
              value: type,
              decoration: const InputDecoration(labelText: 'Tipo de dispositivo'),
              items: DeviceType.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => type = v!,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                final dev = Device(
                  id: device?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name.text,
                  room: roomCtrl.text,
                  broker: broker.text,
                  port: int.tryParse(port.text) ?? 1883,
                  username: user.text,
                  password: pass.text,
                  topicCmd: cmdTopic.text,
                  topicStatus: statTopic.text,
                  type: type,
                );
                Navigator.pop(context, dev);
              },
              child: const Text('GUARDAR'),
            ),
          ],
        ),
      ),
    );
  }
}
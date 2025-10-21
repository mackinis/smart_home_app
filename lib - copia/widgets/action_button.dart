import 'package:flutter/material.dart';
import '../models/device_action.dart';

class ActionButton extends StatelessWidget {
  final DeviceAction action;
  final Function(String) onExecute;
  final bool enabled;

  const ActionButton({
    super.key,
    required this.action,
    required this.onExecute,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      icon: const Icon(Icons.send, size: 18),
      label: Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      onPressed: enabled ? () => _showParamSheet(context) : null,
    );
  }

  void _showParamSheet(BuildContext context) {
    if (action.params.isEmpty) {
      onExecute(action.buildCommand({}));
      return;
    }

    final formKey = GlobalKey<FormState>();
    final values = <String, String>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(_).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(action.label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...action.params.map((p) => TextFormField(
                      decoration: InputDecoration(labelText: p.label),
                      obscureText: p.obscure,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (!p.validate(v)) return 'Formato inválido';
                        return null;
                      },
                      onSaved: (v) => values[p.key] = v!.trim(),
                    )),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(_);
                      onExecute(action.buildCommand(values));
                    }
                  },
                  child: const Text('EJECUTAR'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
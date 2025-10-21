import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _email = TextEditingController();
  bool _sent = false;

  Future<void> _sendReset() async {
    final reset = FirebaseFunctions.instance.httpsCallable('resetPassword');
    await reset({'email': _email.text.trim()});
    setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Restablecer contraseña'),
      content: _sent
          ? TextField(
              decoration: const InputDecoration(labelText: 'Nuevo código recibido'),
              onSubmitted: (code) async {
                final verify = FirebaseFunctions.instance.httpsCallable('verifyResetToken');
                await verify({'email': _email.text.trim(), 'token': code});
                Navigator.pop(context);
              },
            )
          : TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        if (!_sent) TextButton(onPressed: _sendReset, child: const Text('ENVIAR')),
      ],
    );
  }
}
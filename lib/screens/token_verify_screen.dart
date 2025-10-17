import 'package:flutter/material.dart';
import '../services/email_service.dart';
import '../services/token_service.dart';
import 'home_screen.dart';

class TokenVerifyScreen extends StatelessWidget {
  final _token = TextEditingController();

  TokenVerifyScreen({super.key});

  void _verify(BuildContext context) {
    if (EmailService.verifyToken(_token.text)) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token incorrecto')));
    }
  }

  void _resend() async {
    final user = await TokenService.getUser();
    if (user != null) {
      await EmailService.sendToken(user.email);
      ScaffoldMessenger.of(globalContext).showSnackBar(const SnackBar(content: Text('Token reenviado')));
    }
  }

  late BuildContext globalContext;

  @override
  Widget build(BuildContext context) {
    globalContext = context;
    return Scaffold(
      appBar: AppBar(title: const Text('Verificación')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Ingresá el token que te enviamos por email'),
            const SizedBox(height: 16),
            TextField(controller: _token, decoration: const InputDecoration(labelText: 'Token')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _verify(context),
              child: const Text('VERIFICAR'),
            ),
            TextButton(
              onPressed: _resend,
              child: const Text('Reenviar token'),
            ),
          ],
        ),
      ),
    );
  }
}
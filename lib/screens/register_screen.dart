import 'package:flutter/material.dart';
import 'home_screen.dart';

class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();

  void _register(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta (modo mágico)')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Nombre completo')),
            const SizedBox(height: 12),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Teléfono')),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _user, decoration: const InputDecoration(labelText: 'Usuario (login)')),
            const SizedBox(height: 12),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => _register(context),
              child: const Text('REGISTRARME'),
            ),
          ],
        ),
      ),
    );
  }
}
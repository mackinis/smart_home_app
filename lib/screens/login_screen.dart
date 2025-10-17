import 'package:flutter/material.dart';
import '../services/magic_auth.dart';
import '../services/google_service.dart';
import '../services/facebook_service.dart';
import '../services/token_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  final _username = TextEditingController();
  final _password = TextEditingController();

  LoginScreen({super.key});

  /* ---------- LOGIN NORMAL + MÁGICO ---------- */
  void _login(BuildContext context) async {
    // 1) Si coincide el usuario mágico → entra directo
    if (MagicAuth.login(_username.text.trim(), _password.text.trim())) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      return;
    }
    // 2) Sino, prueba contra el usuario guardado localmente
    final user = await TokenService.getUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay usuario registrado')));
      return;
    }
    if (_username.text == user.username && _password.text == user.password) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credenciales incorrectas')));
    }
  }

  /* ---------- GOOGLE ---------- */
  void _googleLogin(BuildContext context) async {
    final account = await GoogleService.signIn();
    if (account != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  /* ---------- FACEBOOK ---------- */
  void _facebookLogin(BuildContext context) async {
    final userData = await FacebookService.signIn();
    if (userData != null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('IoT MQTT', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(controller: _username, decoration: const InputDecoration(labelText: 'Usuario')),
              const SizedBox(height: 12),
              TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _login(context),
                child: const Text('INGRESAR'),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Image.asset('assets/google.png', height: 32),
                    onPressed: () => _googleLogin(context),
                  ),
                  IconButton(
                    icon: Image.asset('assets/facebook.png', height: 32),
                    onPressed: () => _facebookLogin(context),
                  ),
                ],
              ),
              TextButton(
                child: const Text('Crear cuenta'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
              ),
              const SizedBox(height: 8),
              const Text('Usuario mágico: admin / Smart2025!', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
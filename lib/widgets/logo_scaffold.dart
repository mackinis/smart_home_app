import 'package:flutter/material.dart';

class LogoScaffold extends StatelessWidget {
  final String? title;        // "Zonas", "Dispositivos", etc.
  final Widget body;
  final bool showBackButton;
  final List<Widget>? actions; // (+) u otros botones a la derecha

  const LogoScaffold({
    super.key,
    this.title,
    required this.body,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Logo fijo, siempre arriba
            Container(
              width: double.infinity,
              height: 100,
              alignment: Alignment.center,
              child: Image.asset('assets/logo.png', height: 80),
            ),
            // Título opcional debajo del logo
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  title!,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
            // Contenido de la pantalla
            Expanded(child: body),
          ],
        ),
      ),
      floatingActionButton: showBackButton
          ? FloatingActionButton.small(
              onPressed: () => Navigator.maybePop(context),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              child: const Icon(Icons.arrow_back),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.startTop,
    );
  }
}
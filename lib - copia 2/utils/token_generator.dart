import 'dart:math';

String generateToken() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#\$%&*';
  final rnd = Random.secure();
  return List.generate(24, (_) => chars[rnd.nextInt(chars.length)]).join();
}
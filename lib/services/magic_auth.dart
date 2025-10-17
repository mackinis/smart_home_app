class MagicAuth {
  static const String _user = 'admin';
  static const String _pass = 'Smart2025!';

  static bool login(String u, String p) => u == _user && p == _pass;
}
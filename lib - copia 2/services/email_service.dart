import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../utils/token_generator.dart';

class EmailService {
  static final _smtpServer = gmail(
    'soloxelmail@gmail.com',          // <-- cambiá por tu mail
    'tiyqkjmapvsudngj',       // <-- la que generaste arriba
  );

  static String? _lastToken;

  static Future<String> sendToken(String recipient) async {
    _lastToken = generateToken();
    final message = Message()
      ..from = const Address('TU_CORREO@gmail.com', 'Smart Home App')
      ..recipients.add(recipient)
      ..subject = 'Código de verificación Smart Home'
      ..text = 'Tu código es: $_lastToken\n'
               'Copialo y pegalo en la app. Valido por 15 minutos.';

    try {
      await send(message, _smtpServer);
      print('📧 Mail enviado a $recipient con token $_lastToken');
      return _lastToken!;
    } on MailerException catch (e) {
      print('❌ Error al enviar mail: $e');
      rethrow;
    }
  }

  static bool verifyToken(String input) => input == _lastToken;
}
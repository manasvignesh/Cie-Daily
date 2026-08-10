import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class LiveKitTokenService {
  static const String apiKey = 'APIRdnqfgkFQ6CP';
  static const String apiSecret = 'vcFGzW6W2NV5qzSdlXtuN2vbFcMytIXyO90sAXV7NQF';
  static const String liveKitUrl = 'wss://cie-daily-79ts1icb.livekit.cloud';

  static String generateToken({
    required String roomName,
    required String participantIdentity,
    required String participantName,
  }) {
    final jwt = JWT(
      {
        'sub': participantIdentity,
        'name': participantName,
        'video': {
          'room': roomName,
          'roomJoin': true,
        },
      },
      issuer: apiKey,
    );

    // LiveKit tokens typically expire in a few hours
    final token = jwt.sign(
      SecretKey(apiSecret),
      expiresIn: const Duration(hours: 4),
    );

    return token;
  }
}

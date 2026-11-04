import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class PinHasher {
  static const _rounds = 5000;

  String newSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String hash(String pin, String salt) {
    List<int> digest = utf8.encode('$salt:$pin');
    for (var i = 0; i < _rounds; i++) {
      digest = sha256.convert(digest).bytes;
    }
    return base64Encode(digest);
  }
}

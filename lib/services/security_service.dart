import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LockedBody {
  const LockedBody({
    required this.cipherText,
    required this.pinSalt,
    required this.pinHash,
  });

  final String cipherText;
  final String pinSalt;
  final String pinHash;
}

class SecurityService {
  SecurityService();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _pepperKey = 'abidlife_private_note_pepper_v1';
  final _cipher = AesGcm.with256bits();
  final Map<String, SecretKey> _sessionKeys = <String, SecretKey>{};
  String? _pepper;

  Future<String> _loadPepper() async {
    if (_pepper case final value?) return value;
    final existing = await _storage.read(key: _pepperKey);
    if (existing != null) return _pepper = existing;
    final value = base64UrlEncode(_randomBytes(32));
    await _storage.write(key: _pepperKey, value: value);
    return _pepper = value;
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  Future<SecretKey> _deriveKey(String pin, Uint8List salt) async {
    final pepper = await _loadPepper();
    final derivation = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 120000,
      bits: 256,
    );
    return derivation.deriveKey(
      secretKey: SecretKey(utf8.encode('$pin:$pepper')),
      nonce: salt,
    );
  }

  Future<String> _hashPin(String pin, String salt) async {
    final pepper = await _loadPepper();
    return crypto.sha256.convert(utf8.encode('$pepper:$salt:$pin')).toString();
  }

  Future<LockedBody> lock(String noteId, String body, String pin) async {
    final saltBytes = _randomBytes(24);
    final salt = base64UrlEncode(saltBytes);
    final key = await _deriveKey(pin, saltBytes);
    _sessionKeys[noteId] = key;
    return LockedBody(
      cipherText: await _encrypt(body, key),
      pinSalt: salt,
      pinHash: await _hashPin(pin, salt),
    );
  }

  Future<String?> unlock({
    required String noteId,
    required String encryptedBody,
    required String pin,
    required String salt,
    required String expectedHash,
  }) async {
    final candidate = await _hashPin(pin, salt);
    if (!_constantTimeEquals(candidate, expectedHash)) return null;
    final key = await _deriveKey(pin, base64Url.decode(salt));
    try {
      final clear = await _decrypt(encryptedBody, key);
      _sessionKeys[noteId] = key;
      return clear;
    } on SecretBoxAuthenticationError {
      return null;
    }
  }

  Future<String> encryptForOpenSession(String noteId, String body) async {
    final key = _sessionKeys[noteId];
    if (key == null) throw StateError('Private note session is locked');
    return _encrypt(body, key);
  }

  Future<String> decryptForOpenSession(String noteId, String body) async {
    final key = _sessionKeys[noteId];
    if (key == null) throw StateError('Private note session is locked');
    return _decrypt(body, key);
  }

  bool isOpen(String noteId) => _sessionKeys.containsKey(noteId);
  void forget(String noteId) => _sessionKeys.remove(noteId);

  Future<String> _encrypt(String clear, SecretKey key) async {
    final box = await _cipher.encrypt(utf8.encode(clear), secretKey: key);
    return jsonEncode(<String, String>{
      'nonce': base64Encode(box.nonce),
      'cipher': base64Encode(box.cipherText),
      'mac': base64Encode(box.mac.bytes),
    });
  }

  Future<String> _decrypt(String encoded, SecretKey key) async {
    final value = jsonDecode(encoded) as Map<String, dynamic>;
    final box = SecretBox(
      base64Decode(value['cipher'] as String),
      nonce: base64Decode(value['nonce'] as String),
      mac: Mac(base64Decode(value['mac'] as String)),
    );
    return utf8.decode(await _cipher.decrypt(box, secretKey: key));
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return difference == 0;
  }
}

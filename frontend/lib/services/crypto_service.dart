import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoService {
  /// Derives an AES key using SHA-256 on the combination of roomSecret and pageNumber.
  static encrypt.Key _deriveKey(String roomSecret, int pageNumber) {
    var bytes = utf8.encode('$roomSecret$pageNumber');
    var digest = sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(digest.bytes));
  }

  /// Encrypts the [payload] (the annotation text) using AES-256.
  static String encryptPayload(String payload, String roomSecret, int pageNumber) {
    final key = _deriveKey(roomSecret, pageNumber);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(payload, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// Decrypts the [encryptedPackage] using the key derived from the target page.
  static String? decryptPayload(String encryptedPackage, String roomSecret, int pageNumber) {
    try {
      final parts = encryptedPackage.split(':');
      if (parts.length != 2) return null;

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);
      
      final key = _deriveKey(roomSecret, pageNumber);
      final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

      return encrypter.decrypt(encryptedData, iv: iv);
    } catch (e) {
      return null;
    }
  }
}

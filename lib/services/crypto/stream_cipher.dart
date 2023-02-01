import 'dart:typed_data';

/// Encrypts the given data stream with AES-GCM using the given key and initialization vector (IV).
/// Returns a stream of the encrypted data with concatenated MAC.
Stream<Uint8List> encryptAesGcmStream(Stream<List<int>> inputStream, Uint8List key, Uint8List iv) {
  throw UnimplementedError();
}

/// Decrypts the given data stream with AES-GCM using the given key and initialization vector (IV).
/// Returns a stream of the decrypted data. Throws if terminated with an invalid MAC.
Stream<Uint8List> decryptAesGcmStream(Stream<List<int>> inputStream, Uint8List key, Uint8List iv, int expectedLength) {
  throw UnimplementedError();
}

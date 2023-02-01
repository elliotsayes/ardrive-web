import 'dart:typed_data';

import '../../utils/stream.dart';

const _aesBlockSizeBytes = 16;

/// Encrypts the given data stream with AES-256GCM using the given key and initialization vector (IV).
/// Returns a stream of the encrypted data with concatenated MAC.
Stream<Uint8List> encryptAes256GcmStream(Stream<List<int>> inputStream, Uint8List key, Uint8List iv) {
  final blockStream = inputStream.transform(chunkTransformer(_aesBlockSizeBytes));
  throw UnimplementedError();
}

/// Decrypts the given data stream with AES-256GCM using the given key and initialization vector (IV).
/// Returns a stream of the decrypted data. Throws if terminated with an invalid MAC.
Stream<Uint8List> decryptAes256GcmStream(Stream<List<int>> inputStream, Uint8List key, Uint8List iv, int expectedLength) {
  throw UnimplementedError();
}

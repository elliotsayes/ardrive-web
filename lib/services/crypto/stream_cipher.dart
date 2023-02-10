import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:pointycastle/export.dart';

const _chacha20NonceLengthBytes = 8;

FutureOr<Uint8List> chacha20Nonce() {
  final rng = Random.secure();
  return Uint8List.fromList(List.generate(_chacha20NonceLengthBytes, (_) => rng.nextInt(256)));
}

const _bufferSizeBytes = 256 * 1024;

Stream<Uint8List> _processStreamCipher(StreamCipher streamCipher, Stream<Uint8List> dataStream) async* {
  final chunker = ChunkedStreamReader(dataStream);

  while (true) {
    final sourceBuffer = await chunker.readBytes(_bufferSizeBytes);
    final sourceBufferLength = sourceBuffer.length;
    if (sourceBufferLength == 0) break;

    final sinkBuffer = Uint8List(sourceBufferLength);
    final processedBytes = streamCipher.processBytes(sourceBuffer, 0, sourceBufferLength, sinkBuffer, 0);

    yield sinkBuffer;
  }
}

/// Encrypts the given data stream with ChaCha20 using the given key and initialization vector (IV).
/// Returns a stream of the encrypted data.
StreamTransformer<Uint8List, Uint8List> chacha20EncryptionTransformer(Uint8List key, Uint8List iv) {
  final parameters = ParametersWithIV(
    KeyParameter(key),
    iv,
  );
  final encryptor = StreamCipher('ChaCha20/20')
    ..init(true, parameters);
  
  return StreamTransformer.fromBind(
    (Stream<Uint8List> dataStream) => _processStreamCipher(encryptor, dataStream),
  );
}

/// Decrypts the given data stream with ChaCha20 using the given key and initialization vector (IV).
/// Returns a stream of the decrypted data.
StreamTransformer<Uint8List, Uint8List> chacha20DecryptionTransformer(Uint8List key, Uint8List iv) {
  throw UnimplementedError();
}

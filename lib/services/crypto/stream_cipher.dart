import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:pointycastle/export.dart';

const _aesBlockSizeBytes = 16;
const _bufferSizeBytes = 256 * 1024;

Stream<Uint8List> _encryptBlockStream(GCMBlockCipher encrypter, Stream<Uint8List> dataStream) async* {
  final chunker = ChunkedStreamReader(dataStream);

  while (true) {
    final sourceBuffer = await chunker.readBytes(_bufferSizeBytes);
    
    final bufferLength = sourceBuffer.length;
    if (bufferLength == 0) break;
    final sinkBuffer = Uint8List(bufferLength);

    var bufferOffset = 0;
    while (true) {
      final bufferRemaining = bufferLength - bufferOffset;
      final blockLength = min(_aesBlockSizeBytes, bufferRemaining);
      if (blockLength == 0) break;

      encrypter.processBlock(sourceBuffer, bufferOffset, sinkBuffer, bufferOffset);
      bufferOffset += blockLength;
    }

    yield sinkBuffer;
  }

  final macBuffer = Uint8List(encrypter.macSize);
  final macBytesCount = encrypter.doFinal(macBuffer, 0);
  
  if (macBytesCount != macBuffer.length) throw StateError('MAC size mismatch: $macBytesCount != ${macBuffer.length}');
  
  yield macBuffer;
}

/// Encrypts the given data stream with AES-256GCM using the given key and initialization vector (IV).
/// Returns a stream of the encrypted data with concatenated MAC.
StreamTransformer<Uint8List, Uint8List> aes256GcmEncryptionTransformer(Uint8List key, Uint8List iv) {
  final parameters = AEADParameters(
    KeyParameter(key),
    _aesBlockSizeBytes * 8, // in bits
    iv,
    Uint8List(0),
  );
  final encrypter = GCMBlockCipher(AESEngine())
    ..init(true, parameters);
  
  return StreamTransformer.fromBind(
    (Stream<Uint8List> blockStream) => _encryptBlockStream(encrypter, blockStream),
  );
}

/// Decrypts the given data stream with AES-256GCM using the given key and initialization vector (IV).
/// Returns a stream of the decrypted data. Throws if terminated with an invalid MAC.
StreamTransformer<Uint8List, Uint8List> aes256GcmStreamDecryptionTransformer(Uint8List key, Uint8List iv, int expectedLength) {
  throw UnimplementedError();
}

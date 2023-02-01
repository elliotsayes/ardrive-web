import 'dart:async';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import '../../utils/stream.dart';

const _aesBlockSizeBytes = 16;
final _blockChunker = chunkTransformer(_aesBlockSizeBytes);

Stream<Uint8List> _encryptBlockStream(GCMBlockCipher encrypter, Stream<Uint8List> blockStream) async * {
  await for (final block in blockStream) {
    final encryptedBlockBuffer = Uint8List(block.length);
    /*final blockProcessedBytesCount = */encrypter.processBlock(block, 0, encryptedBlockBuffer, 0);
    yield encryptedBlockBuffer/*.sublist(0, blockProcessedBytesCount)*/;
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
  
  final blockEncrypter = StreamTransformer.fromBind(
    (Stream<Uint8List> blockStream) => _encryptBlockStream(encrypter, blockStream),
  );

  return StreamTransformer.fromBind((stream) =>
    stream.transform(_blockChunker).transform(blockEncrypter),
  );
}

/// Decrypts the given data stream with AES-256GCM using the given key and initialization vector (IV).
/// Returns a stream of the decrypted data. Throws if terminated with an invalid MAC.
StreamTransformer<Uint8List, Uint8List> aes256GcmStreamDecryptionTransformer(Uint8List key, Uint8List iv, int expectedLength) {
  throw UnimplementedError();
}

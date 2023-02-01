import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:pointycastle/export.dart';

const _aesBlockSizeBytes = 16;
const _bufferSizeBytes = 1024;

Stream<Uint8List> _encryptBlockStream(GCMBlockCipher encrypter, Stream<Uint8List> dataStream) async* {
  var sinkBuffer = Uint8List(_bufferSizeBytes);
  var sinkBufferOffset = 0;

  List<Uint8List> handleSink(Uint8List data, {bool flush = false}) {
    final toYield = <Uint8List>[];

    // yield & reset buffer if adding would result in an overflow
    if (sinkBufferOffset + data.length > _bufferSizeBytes - 1) {
      toYield.add(Uint8List.sublistView(sinkBuffer, 0, sinkBufferOffset));
      sinkBuffer = Uint8List(_bufferSizeBytes);
      sinkBufferOffset = 0;
    }
    
    // add to sink buffer
    sinkBuffer.setAll(sinkBufferOffset, data);
    sinkBufferOffset += data.length;

    // yield remaining when flushing
    if (flush) {
      toYield.add(Uint8List.sublistView(sinkBuffer, 0, sinkBufferOffset));
    }

    return toYield;
  }

  final chunker = ChunkedStreamReader(dataStream);
  while (true) {
    final block = await chunker.readBytes(_aesBlockSizeBytes);
    if (block.isEmpty) break;

    final encryptedBlockBuffer = Uint8List(block.length);
    final blockProcessedBytesCount = encrypter.processBlock(block, 0, encryptedBlockBuffer, 0);
    
    final toYield = handleSink(Uint8List.sublistView(encryptedBlockBuffer, 0, blockProcessedBytesCount));
    for (final chunk in toYield) {
      yield chunk;
    }
  }

  final macBuffer = Uint8List(encrypter.macSize);
  final macBytesCount = encrypter.doFinal(macBuffer, 0);
  
  if (macBytesCount != macBuffer.length) throw StateError('MAC size mismatch: $macBytesCount != ${macBuffer.length}');
  
  final toYield = handleSink(macBuffer, flush: true);
  for (final chunk in toYield) {
    yield chunk;
  }
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

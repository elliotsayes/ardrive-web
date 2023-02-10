import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:async/async.dart';
import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/export.dart' hide Mac;

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
    streamCipher.processBytes(sourceBuffer, 0, sourceBufferLength, sinkBuffer, 0);

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
  final parameters = ParametersWithIV(
    KeyParameter(key),
    iv,
  );
  final decryptor = StreamCipher('ChaCha20/20')
    ..init(false, parameters);
  
  return StreamTransformer.fromBind(
    (Stream<Uint8List> dataStream) => _processStreamCipher(decryptor, dataStream),
  );
}

const _aesBlockSizeBytes = 16;

Stream<Uint8List> _processNativeStreamCipher(
  Future<Uint8List> Function(Uint8List input, int blockOffset) processBytes,
  Stream<Uint8List> dataStream
) async* {
  final chunker = ChunkedStreamReader(dataStream);

  var streamOffset = 0;
  while (true) {
    final sourceBuffer = await chunker.readBytes(_bufferSizeBytes);
    final sourceBufferLength = sourceBuffer.length;
    if (sourceBufferLength == 0) break;

    yield await processBytes(sourceBuffer, streamOffset);
    streamOffset += sourceBufferLength;
  }
}

final aes256Ctr = AesCtr.with256bits(macAlgorithm: MacAlgorithm.empty);

StreamTransformer<Uint8List, Uint8List> aes256CtrEncryptionTransformer(SecretKey key, Uint8List iv) {
  encryptBytes(Uint8List clearText, int blockOffset) async {
    final secretBox = await aes256Ctr.encrypt(
      clearText, 
      secretKey: key,
      nonce: iv,
      keyStreamIndex: blockOffset,
    );
    return secretBox.concatenation(nonce: false, mac: false);
  }

  return StreamTransformer.fromBind(
    (Stream<Uint8List> dataStream) => _processNativeStreamCipher(encryptBytes, dataStream),
  );
}

StreamTransformer<Uint8List, Uint8List> aes256CtrDecryptionTransformer(SecretKey key, Uint8List iv) {
  decryptBytes(Uint8List cipherText, int blockOffset) async {
    final secretBox = SecretBox(cipherText, nonce: iv, mac: Mac.empty);
    return await aes256Ctr.decrypt(
      secretBox, 
      secretKey: key,
      keyStreamIndex: blockOffset,
    ) as Uint8List;
  }

  return StreamTransformer.fromBind(
    (Stream<Uint8List> dataStream) => _processNativeStreamCipher(decryptBytes, dataStream),
  );
}

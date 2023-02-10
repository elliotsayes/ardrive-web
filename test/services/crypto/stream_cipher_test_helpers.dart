import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:pointycastle/export.dart' hide Mac;

Future<Uint8List> chacha20BufferEncrypt(Uint8List data, Uint8List key, Uint8List iv) async {
  final syncEncrypt = StreamCipher('ChaCha20/20');
  syncEncrypt.init(true, ParametersWithIV(
    KeyParameter(key),
    iv,
  ));

  return syncEncrypt.process(data);
}

Future<Uint8List> chacha20BufferDecrypt(Uint8List data, Uint8List key, Uint8List iv) async {
  final syncEncrypt = StreamCipher('ChaCha20/20');
  syncEncrypt.init(false, ParametersWithIV(
    KeyParameter(key),
    iv,
  ));

  return syncEncrypt.process(data);
}

final aes256Ctr = AesCtr.with256bits(macAlgorithm: MacAlgorithm.empty);

Future<Uint8List> aes256CtrBufferEncrypt(Uint8List data, SecretKey key, Uint8List iv) async {
  final clearText = await aes256Ctr.encrypt(data, secretKey: key, nonce: iv);
  return clearText.concatenation(nonce: false, mac: false);
}

Future<Uint8List> aes256CtrBufferDecrypt(Uint8List data, SecretKey key, Uint8List iv) async {
  final secretBox = SecretBox(data, nonce: iv, mac: Mac.empty);
  final clearText = await aes256Ctr.decrypt(secretBox, secretKey: key);
  return clearText as Uint8List;
}

Stream<Uint8List> generateMebibytesOfData(int mebibytes, {int? finalSizeBytes}) async* {
  for (var i = 0; i < mebibytes; i++) {
    yield Uint8List(1024 * 1024);
  }
  if (finalSizeBytes != null) {
    yield Uint8List.fromList(List.generate(finalSizeBytes, (index) => index % 256));
  }
}

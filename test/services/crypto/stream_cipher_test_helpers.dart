import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

final _syncEncrypt = AesGcm.with256bits();

Future<Uint8List> bufferEncrypt(List<int> data, Uint8List key, Uint8List iv) async {
  final encryptedSyncResult = await _syncEncrypt.encrypt(
    data,
    secretKey: SecretKey(key),
    nonce: iv,
  );
  final encryptedSyncData = encryptedSyncResult.concatenation(nonce: false);
  return encryptedSyncData;
}

Stream<Uint8List> generateMegabytesOfData(int megabytes, {int? finalSizeBytes}) async* {
  for (var i = 0; i < megabytes; i++) {
    yield Uint8List(1024 * 1024);
  }
  if (finalSizeBytes != null) {
    yield Uint8List.fromList(List.generate(finalSizeBytes, (index) => index % 256));
  }
}

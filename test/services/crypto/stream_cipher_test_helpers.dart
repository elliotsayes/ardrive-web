import 'dart:typed_data';

import 'package:pointycastle/export.dart';

Future<Uint8List> bufferEncrypt(Uint8List data, Uint8List key, Uint8List iv) async {
  final syncEncrypt = StreamCipher('ChaCha20/20');
  syncEncrypt.init(true, ParametersWithIV(
    KeyParameter(key),
    iv,
  ));

  return syncEncrypt.process(data);
}

Stream<Uint8List> generateMebibytesOfData(int mebibytes, {int? finalSizeBytes}) async* {
  for (var i = 0; i < mebibytes; i++) {
    yield Uint8List(1024 * 1024);
  }
  if (finalSizeBytes != null) {
    yield Uint8List.fromList(List.generate(finalSizeBytes, (index) => index % 256));
  }
}
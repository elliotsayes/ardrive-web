import 'package:ardrive/services/crypto/stream_cipher.dart';
import 'package:async/async.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stream_cipher_test_helpers.dart';

const _blockSize = 16;
final _testKey = Uint8List.fromList(List.generate(256 ~/ 8, (index) => index % 256));
final _testIV = Uint8List.fromList(List.generate(12, (index) => index % 256));

void main() {
  group('encryptAes256GcmStream function', () {    
    test('should match sync method when a multiple of block size', () async {
      final encryptionTransformer = aes256GcmEncryptionTransformer(_testKey, _testIV);
      
      dataGenerator() => generateKilobytesOfData(1, finalSizeBytes: _blockSize * 3);
      final dataStream = dataGenerator();
      final dataBuffer = await collectBytes(dataGenerator());
      expect(dataBuffer.length % _blockSize, equals(0));

      final encryptionStream = dataStream.transform(encryptionTransformer);
      final streamEncryptedData = await collectBytes(encryptionStream);

      final bufferEncryptedData = await bufferEncrypt(dataBuffer, _testKey, _testIV);
      
      expect(streamEncryptedData.length, equals(bufferEncryptedData.length));
      expect(streamEncryptedData, equals(bufferEncryptedData));
    });

    test('should match sync method when not a multiple of block size', () async {
      final encryptionTransformer = aes256GcmEncryptionTransformer(_testKey, _testIV);
      
      dataGenerator() => generateKilobytesOfData(1, finalSizeBytes: _blockSize + 3);
      final dataStream = dataGenerator();
      final dataBuffer = await collectBytes(dataGenerator());
      expect(dataBuffer.length % _blockSize, isNot(equals(0)));

      final encryptionStream = dataStream.transform(encryptionTransformer);
      final streamEncryptedData = await collectBytes(encryptionStream);

      final bufferEncryptedData = await bufferEncrypt(dataBuffer, _testKey, _testIV);
      
      expect(streamEncryptedData.length, equals(bufferEncryptedData.length));
      expect(streamEncryptedData, equals(bufferEncryptedData));
    });

    test('should match sync method when zero length', () async {
      final encryptionTransformer = aes256GcmEncryptionTransformer(_testKey, _testIV);  
      
      dataGenerator() => generateKilobytesOfData(0);
      final dataStream = dataGenerator();
      final dataBuffer = await collectBytes(dataGenerator());
      expect(dataBuffer.length, equals(0));

      final encryptionStream = dataStream.transform(encryptionTransformer);
      final streamEncryptedData = await collectBytes(encryptionStream);

      final bufferEncryptedData = await bufferEncrypt(dataBuffer, _testKey, _testIV);
      
      expect(streamEncryptedData.length, equals(bufferEncryptedData.length));
      expect(streamEncryptedData, equals(bufferEncryptedData));
    });

    test('should encrypt a lot of data', () async {
      final encryptionTransformer = aes256GcmEncryptionTransformer(_testKey, _testIV);
      
      final dataStream = generateKilobytesOfData(200, finalSizeBytes: 255);
      final encryptionStream = dataStream.transform(encryptionTransformer);
      
      await for (final _ in encryptionStream) {
        print(_.length);
      }
      
      expect(true, isTrue);
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}

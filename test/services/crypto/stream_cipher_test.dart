import 'dart:typed_data';

import 'package:ardrive/services/crypto/stream_cipher.dart';
import 'package:async/async.dart';
import 'package:test/test.dart';

import 'stream_cipher_test_helpers.dart';

const _blockSize = 16;
final _testKey = Uint8List.fromList(List.generate(32, (index) => index % 256));
final _testIV = Uint8List.fromList(List.generate(8, (index) => index % 256));

void main() {
  group('encryptAes256GcmStream function', () {    
    test('should match sync method when a multiple of block size', () async {
      final encryptionTransformer = chacha20EncryptionTransformer(_testKey, _testIV);
      
      dataGenerator() => generateMebibytesOfData(1, finalSizeBytes: _blockSize * 3);
      final dataStream = dataGenerator();
      final dataBuffer = await collectBytes(dataGenerator());
      expect(dataBuffer.length % _blockSize, equals(0));

      final encryptionStream = dataStream.transform(encryptionTransformer);
      final streamEncryptedData = await collectBytes(encryptionStream);

      expect(streamEncryptedData.length, equals(dataBuffer.length));

      final bufferEncryptedData = await bufferEncrypt(dataBuffer, _testKey, _testIV);
      
      expect(streamEncryptedData.length, equals(bufferEncryptedData.length));
      expect(streamEncryptedData, equals(bufferEncryptedData));
    });

    test('should match sync method when not a multiple of block size', () async {
      final encryptionTransformer = chacha20EncryptionTransformer(_testKey, _testIV);
      
      dataGenerator() => generateMebibytesOfData(1, finalSizeBytes: _blockSize + 3);
      final dataStream = dataGenerator();
      final dataBuffer = await collectBytes(dataGenerator());
      expect(dataBuffer.length % _blockSize, isNot(equals(0)));

      final encryptionStream = dataStream.transform(encryptionTransformer);
      final streamEncryptedData = await collectBytes(encryptionStream);

      expect(streamEncryptedData.length, equals(dataBuffer.length));

      final bufferEncryptedData = await bufferEncrypt(dataBuffer, _testKey, _testIV);
      
      expect(streamEncryptedData.length, equals(bufferEncryptedData.length));
      expect(streamEncryptedData, equals(bufferEncryptedData));
    });

    test('should match sync method when zero length', () async {
      final encryptionTransformer = chacha20EncryptionTransformer(_testKey, _testIV);  
      
      dataGenerator() => generateMebibytesOfData(0);
      final dataStream = dataGenerator();
      final dataBuffer = await collectBytes(dataGenerator());
      expect(dataBuffer.length, equals(0));

      final encryptionStream = dataStream.transform(encryptionTransformer);
      final streamEncryptedData = await collectBytes(encryptionStream);

      expect(streamEncryptedData.length, equals(dataBuffer.length));

      final bufferEncryptedData = await bufferEncrypt(dataBuffer, _testKey, _testIV);
      
      expect(streamEncryptedData.length, equals(bufferEncryptedData.length));
      expect(streamEncryptedData, equals(bufferEncryptedData));
    });

    test('should encrypt a lot of data', () async {
      final encryptionTransformer = chacha20EncryptionTransformer(_testKey, _testIV);

      const testSizeMebibytes = 20;

      dataGenerator() => generateMebibytesOfData(testSizeMebibytes);
      final dataStream = dataGenerator();
      final dataBuffer = await collectBytes(dataGenerator());

      final encryptionStream = dataStream.transform(encryptionTransformer);
      
      DateTime start, end;
      start = DateTime.now();
      await for (final _ in encryptionStream) {
        // print(_.length);
      }
      end = DateTime.now();
      final streamTime = end.difference(start);
      // print('Stream time: $streamTime');

      const targetMebibytesPerSecond = 2; // Conservative for CI/CD environment
      final actualMebibytesPerSecond = testSizeMebibytes / streamTime.inSeconds;
      expect(actualMebibytesPerSecond, greaterThan(targetMebibytesPerSecond), reason: 'Stream speed should be greater than $targetMebibytesPerSecond MiB/s');

      start = DateTime.now();
      await bufferEncrypt(dataBuffer, _testKey, _testIV);
      end = DateTime.now();
      final bufferTime = end.difference(start);
      // print('Buffer time: $bufferTime');
      
      final relativeTime = streamTime.inMilliseconds / bufferTime.inMilliseconds;
      expect(relativeTime, lessThan(1.1), reason: 'Stream time should be less than 1.1x buffer time');
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
import 'dart:async';
import 'dart:typed_data';

import 'package:ardrive/services/crypto/stream_cipher.dart';
import 'package:async/async.dart';
import 'package:cryptography/cryptography.dart';
import 'package:test/test.dart';

import 'stream_cipher_test_helpers.dart';

const _chunkSize = 256 * 1024;
final _testKey = Uint8List.fromList(List.generate(32, (index) => index % 256));
final _testBox = SecretKey(_testKey);
final _testIV = Uint8List.fromList(List.generate(8, (index) => index % 256));

void main() {
  group('chacha20{En,De}cryptionTransformer function parity', () {    
    expectParity(Stream<Uint8List> Function() dataGen) async {
      encryptionTransformer() => chacha20EncryptionTransformer(_testKey, _testIV);
      decryptionTransformer() => chacha20DecryptionTransformer(_testKey, _testIV);

      expect(await collectBytes(dataGen()), equals(await collectBytes(dataGen())));
      final dataBuffer = await collectBytes(dataGen());

      encryptionGen() => dataGen().transform(encryptionTransformer());
      expect(await collectBytes(encryptionGen()), equals(await collectBytes(encryptionGen())));
      final dataStreamEncrypted = await collectBytes(encryptionGen());
      expect(dataStreamEncrypted.length, equals(dataBuffer.length));

      final dataBufferEncrypted = await chacha20BufferEncrypt(dataBuffer, _testKey, _testIV);
      
      expect(dataStreamEncrypted.length, equals(dataBufferEncrypted.length));
      expect(dataStreamEncrypted, equals(dataBufferEncrypted));

      decryptionGen() => encryptionGen().transform(decryptionTransformer());
      expect(await collectBytes(decryptionGen()), equals(await collectBytes(decryptionGen())));
      final dataStreamDecrypted = await collectBytes(decryptionGen());

      expect(dataStreamDecrypted.length, equals(dataBuffer.length));
      expect(dataStreamDecrypted, equals(dataBuffer));
    }

    test('should match sync method & original data when a multiple of chunk size', () async {
      dataGen() => generateMebibytesOfData(1, finalSizeBytes: _chunkSize);
      await expectParity(dataGen);
    });

    test('should match sync method & original data when not a multiple of chunk size', () async {
      dataGen() => generateMebibytesOfData(1, finalSizeBytes: 1);
      await expectParity(dataGen);
    });

    test('should match sync method & original data when zero length', () async {
      dataGen() => generateMebibytesOfData(0);
      await expectParity(dataGen);
    });
  });
  
  group('chacha20{En,De}cryptionTransformer function speed', () {
    expectSpeed(
      StreamTransformer<Uint8List, Uint8List> transformer,
      Future<Uint8List> Function(Uint8List, Uint8List, Uint8List) bufferFunc,
      String processName,
    ) async {
      const testSizeMebibytes = 20;
      const targetMebibytesPerSecond = 2; // Conservative for CI/CD environment
      const targetBufferFactor = 1.2; // Conservative for small test size

      dataGen() => generateMebibytesOfData(testSizeMebibytes);
      final dataStream = dataGen();
      final dataBuffer = await collectBytes(dataGen());

      transformGen() => dataStream.transform(transformer);
      
      DateTime start, end;
      start = DateTime.now();
      await for (final _ in transformGen()) {
        // print(_.length);
      }
      end = DateTime.now();
      final streamTime = end.difference(start);
      // print('$processName stream time: $streamTime');

      final actualMebibytesPerSecond = testSizeMebibytes / streamTime.inSeconds;
      expect(actualMebibytesPerSecond, greaterThan(targetMebibytesPerSecond), reason: '$processName stream speed should be greater than $targetMebibytesPerSecond MiB/s');

      start = DateTime.now();
      await bufferFunc(dataBuffer, _testKey, _testIV);
      end = DateTime.now();
      final bufferTime = end.difference(start);
      // print('$processName buffer time: $bufferTime');
      
      final relativeTime = streamTime.inMilliseconds / bufferTime.inMilliseconds;
      expect(relativeTime, lessThan(targetBufferFactor), reason: '$processName stream time should be less than ${targetBufferFactor}x buffer time');
    }

    test('should encrypt a lot of data quickly', () async {
      final encryptionTransformer = chacha20EncryptionTransformer(_testKey, _testIV);
      await expectSpeed(encryptionTransformer, chacha20BufferEncrypt, 'Encrypt');
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('should decrypt a lot of data quickly', () async {
      final decryptionTransformer = chacha20DecryptionTransformer(_testKey, _testIV);
      await expectSpeed(decryptionTransformer, chacha20BufferDecrypt, 'Decrypt');
    }, timeout: const Timeout(Duration(minutes: 1)));
  });

  group('aes256Ctr{En,De}cryptionTransformer function parity', () {    
    expectParity(Stream<Uint8List> Function() dataGen) async {
      encryptionTransformer() => aes256CtrEncryptionTransformer(_testBox, _testIV);
      decryptionTransformer() => aes256CtrDecryptionTransformer(_testBox, _testIV);

      expect(await collectBytes(dataGen()), equals(await collectBytes(dataGen())));
      final dataBuffer = await collectBytes(dataGen());

      encryptionGen() => dataGen().transform(encryptionTransformer());
      expect(await collectBytes(encryptionGen()), equals(await collectBytes(encryptionGen())));
      final dataStreamEncrypted = await collectBytes(encryptionGen());
      expect(dataStreamEncrypted.length, equals(dataBuffer.length));

      final dataBufferEncrypted = await aes256CtrBufferEncrypt(dataBuffer, _testBox, _testIV);
      
      expect(dataStreamEncrypted.length, equals(dataBufferEncrypted.length));
      expect(dataStreamEncrypted, equals(dataBufferEncrypted));

      decryptionGen() => encryptionGen().transform(decryptionTransformer());
      expect(await collectBytes(decryptionGen()), equals(await collectBytes(decryptionGen())));
      final dataStreamDecrypted = await collectBytes(decryptionGen());

      expect(dataStreamDecrypted.length, equals(dataBuffer.length));
      expect(dataStreamDecrypted, equals(dataBuffer));
    }

    test('should match sync method & original data when a multiple of chunk size', () async {
      dataGen() => generateMebibytesOfData(1, finalSizeBytes: _chunkSize);
      await expectParity(dataGen);
    });

    test('should match sync method & original data when not a multiple of chunk size', () async {
      dataGen() => generateMebibytesOfData(1, finalSizeBytes: 1);
      await expectParity(dataGen);
    });

    test('should match sync method & original data when zero length', () async {
      dataGen() => generateMebibytesOfData(0);
      await expectParity(dataGen);
    });
  });
  
  group('aes256Ctr{En,De}cryptionTransformer function speed', () {
    expectSpeed(
      StreamTransformer<Uint8List, Uint8List> transformer,
      Future<Uint8List> Function(Uint8List, SecretKey, Uint8List) bufferFunc,
      String processName,
    ) async {
      const testSizeMebibytes = 20;
      const targetMebibytesPerSecond = 2; // Conservative for CI/CD environment
      const targetBufferFactor = 1.5; // Conservative for small test size

      dataGen() => generateMebibytesOfData(testSizeMebibytes);
      final dataStream = dataGen();
      final dataBuffer = await collectBytes(dataGen());

      transformGen() => dataStream.transform(transformer);
      
      DateTime start, end;
      start = DateTime.now();
      await for (final _ in transformGen()) {
        // print(_.length);
      }
      end = DateTime.now();
      final streamTime = end.difference(start);
      // print('$processName stream time: $streamTime');

      final actualMebibytesPerSecond = testSizeMebibytes / streamTime.inSeconds;
      expect(actualMebibytesPerSecond, greaterThan(targetMebibytesPerSecond), reason: '$processName stream speed should be greater than $targetMebibytesPerSecond MiB/s');

      start = DateTime.now();
      await aes256CtrBufferEncrypt(dataBuffer, _testBox, _testIV);
      end = DateTime.now();
      final bufferTime = end.difference(start);
      // print('$processName buffer time: $bufferTime');
      
      final relativeTime = streamTime.inMilliseconds / bufferTime.inMilliseconds;
      expect(relativeTime, lessThan(targetBufferFactor), reason: '$processName stream time should be less than ${targetBufferFactor}x buffer time');
    }

    test('should encrypt a lot of data quickly', () async {
      final encryptionTransformer = aes256CtrEncryptionTransformer(_testBox, _testIV);
      await expectSpeed(encryptionTransformer, aes256CtrBufferEncrypt, 'Encrypt');
    }, timeout: const Timeout(Duration(minutes: 1)));

    test('should decrypt a lot of data quickly', () async {
      final decryptionTransformer = aes256CtrDecryptionTransformer(_testBox, _testIV);
      await expectSpeed(decryptionTransformer, aes256CtrBufferDecrypt, 'Decrypt');
    }, timeout: const Timeout(Duration(minutes: 1)));
  });
}
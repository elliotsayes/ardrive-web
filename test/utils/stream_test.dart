import 'package:ardrive/utils/stream.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'stream_test_helpers.dart';

void main() {
  group('chunkStream', () {
    test('test when multiple of chunk size', () async {
      const chunkSize = 16;
      final inputChunkSizes = [20, 12, 15, 17];

      expect(inputChunkSizes.reduce((a, b) => a + b) % chunkSize, equals(0));

      final originalData = generateChunksOfSizes(inputChunkSizes);
      final originalDataStream = Stream.fromIterable(originalData);

      final chunkedStream = originalDataStream.transform<Uint8List>(chunkTransformer(chunkSize));

      expect(
        chunkedStream, 
        emitsInOrder(
          List.generate(4, (index) => hasLength(16)),
        ),
      );
    });

    test('test when not multiple of chunk size', () async {
      const chunkSize = 16;
      final inputChunkSizes = [20, 12, 15, 19];
      
      expect(inputChunkSizes.reduce((a, b) => a + b) % chunkSize, isNot(equals(0)));

      final originalData = generateChunksOfSizes(inputChunkSizes);
      final originalDataStream = Stream.fromIterable(originalData);

      final chunkedStream = originalDataStream.transform<Uint8List>(chunkTransformer(chunkSize));

      expect(
        chunkedStream, 
        emitsInOrder(
          List.generate(4, (index) => hasLength(16))
            ..add(isNot(hasLength(16))),
        ),
      );
    });

    test('test when less than chunk size', () async {
      const chunkSize = 16;
      final inputChunkSizes = [12];

      final originalData = generateChunksOfSizes(inputChunkSizes);
      final originalDataStream = Stream.fromIterable(originalData);

      final chunkedStream = originalDataStream.transform<Uint8List>(chunkTransformer(chunkSize));

      expect(
        chunkedStream, 
        emits(
          hasLength(inputChunkSizes[0]),
        ),
      );
    });
  });
}

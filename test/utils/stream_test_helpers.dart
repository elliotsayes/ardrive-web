import 'package:flutter/foundation.dart';

List<Uint8List> generateChunksOfSizes(List<int> chunkSizes) {
  return List.generate(chunkSizes.length, (chunkIndex) => 
    Uint8List.fromList(List.generate(chunkSizes[chunkIndex], (index) => index % 256)),
  );
}

import 'dart:async';
import 'dart:typed_data';

import 'package:async/async.dart';

StreamTransformer<Uint8List, Uint8List> chunkTransformer(int chunkSize)  {
  Stream<Uint8List> chunkStream(Stream<List<int>> inputStream, int chunkSize) async* {
    final chunker = ChunkedStreamReader(inputStream);
    while (true) {
      final chunk = await chunker.readBytes(chunkSize);

      if (chunk.isEmpty) break;
      yield chunk;
      
      if (chunk.length < chunkSize) break;
    }
  }
  return StreamTransformer.fromBind(((stream) => chunkStream(stream, chunkSize)));
}

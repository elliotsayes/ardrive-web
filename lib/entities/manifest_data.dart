import 'dart:convert';

import 'package:ardrive/entities/entities.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/utils/logger/logger.dart';
import 'package:ardrive_utils/ardrive_utils.dart';
import 'package:arweave/arweave.dart';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Uint8List;
import 'package:json_annotation/json_annotation.dart'
    show JsonKey, JsonSerializable;
import 'package:package_info_plus/package_info_plus.dart';

part 'manifest_data.g.dart';

@JsonSerializable()
class ManifestIndex {
  @JsonKey()
  final String path;

  ManifestIndex(this.path);

  factory ManifestIndex.fromJson(Map<String, dynamic> json) =>
      _$ManifestIndexFromJson(json);
  Map<String, dynamic> toJson() => _$ManifestIndexToJson(this);
}

@JsonSerializable()
class ManifestTx {
  @JsonKey()
  final String id;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? fileId;

  ManifestTx(
    this.id, {
    this.fileId,
  });

  factory ManifestTx.fromJson(Map<String, dynamic> json) =>
      _$ManifestTxFromJson(json);
  Map<String, dynamic> toJson() => _$ManifestTxToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ManifestData {
  @JsonKey()
  String manifest = 'arweave/paths';
  @JsonKey()
  String version = '0.1.0';
  @JsonKey()
  final ManifestIndex index;
  @JsonKey()
  final Map<String, ManifestTx> paths;

  ManifestData(
    this.index,
    this.paths,
  );

  int get size => jsonData.lengthInBytes;
  Uint8List get jsonData => utf8.encode(json.encode(this)) as Uint8List;

  Future<DataItem> asPreparedDataItem({
    required ArweaveAddressString owner,
  }) async {
    final manifestDataItem = DataItem.withBlobData(data: jsonData)
      ..setOwner(owner)
      ..addApplicationTags(
        version: (await PackageInfo.fromPlatform()).version,
      )
      ..addTag(EntityTag.contentType, ContentType.manifest);

    return manifestDataItem;
  }

  static ManifestData fromFolderNode({
    required FolderNode folderNode,
    // required Selectable<NetworkTransaction>? pendingTransactions,
  }) {
    final fileList = folderNode
        .getRecursiveFiles()
        // We will not include any existing manifests in the new manifest
        .where((f) => f.dataContentType != ContentType.manifest);

    final indexFile = () {
      final indexHtml = folderNode.files.values.firstWhereOrNull(
        (f) => f.name == 'index.html',
      );

      if (indexHtml != null) {
        // Link index field to any index.html file that exists in the root folder
        return indexHtml;
      }

      // Otherwise link it to the first file in the folder
      return fileList.first;
    }();

    final rootFolderPath = folderNode.folder.path;
    final index = ManifestIndex(
      prepareManifestPath(
          filePath: indexFile.path, rootFolderPath: rootFolderPath),
    );

    final paths = {
      for (final file in fileList)
        prepareManifestPath(
          filePath: file.path,
          rootFolderPath: rootFolderPath,
        ): ManifestTx(file.dataTxId, fileId: file.id)
    };

    logger.d('Files relative to root folder $rootFolderPath: $paths');

    // final fileDataTxIds = fileList.map((f) => f.dataTxId).toSet();
    // final Future<bool>? hasPendingTransactions;
    // if (pendingTransactions == null) {
    //   hasPendingTransactions = null;
    // } else {
    //   hasPendingTransactions = pendingTransactions.get().then(
    //         (txs) => txs.any(
    //           (tx) => fileDataTxIds.contains(tx.id),
    //         ),
    //       );
    // }

    return ManifestData(
      index,
      paths,
      // hasPendingTransactions: hasPendingTransactions,
    );
  }

  factory ManifestData.fromJson(Map<String, dynamic> json) =>
      _$ManifestDataFromJson(json);
  Map<String, dynamic> toJson() => _$ManifestDataToJson(this);
}

/// Utility function to remove base path of the target folder and
/// replace spaces with underscores for arweave.net URL compatibility
String prepareManifestPath({
  required String filePath,
  required String rootFolderPath,
}) {
  return filePath.substring(rootFolderPath.length + 1).replaceAll(' ', '_');
}

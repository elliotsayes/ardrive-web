import 'package:ardrive/blocs/upload/upload_handles/file_data_item_upload_handle.dart';
import 'package:ardrive/blocs/upload/upload_handles/folder_data_item_upload_handle.dart';
import 'package:ardrive/blocs/upload/upload_handles/upload_handle.dart';
import 'package:ardrive/entities/entities.dart';
import 'package:ardrive/models/daos/daos.dart';
import 'package:ardrive/services/services.dart';
import 'package:ardrive/utils/logger/logger.dart';
import 'package:arweave/arweave.dart';
import 'package:flutter/foundation.dart';

class BundleUploadHandle implements UploadHandle {
  final List<FileDataItemUploadHandle> fileDataItemUploadHandles;
  final List<FolderDataItemUploadHandle> folderDataItemUploadHandles;

  late Transaction bundleTx;
  late DataItem bundleDataItem;
  late String bundleId;
  late Iterable<FileEntity> fileEntities;

  BundleUploadHandle._create({
    this.fileDataItemUploadHandles = const [],
    this.folderDataItemUploadHandles = const [],
    this.size = 0,
    this.hasError = false,
  }) {
    fileEntities = fileDataItemUploadHandles.map((item) => item.entity);
  }

  static Future<BundleUploadHandle> create({
    List<FileDataItemUploadHandle> fileDataItemUploadHandles = const [],
    List<FolderDataItemUploadHandle> folderDataItemUploadHandles = const [],
  }) async {
    final bundle = BundleUploadHandle._create(
      fileDataItemUploadHandles: fileDataItemUploadHandles,
      folderDataItemUploadHandles: folderDataItemUploadHandles,
    );
    bundle.size = await bundle.computeBundleSize();
    return bundle;
  }

  BigInt get cost {
    return bundleTx.reward;
  }

  int get numberOfFiles => fileEntities.length;

  @override
  double uploadProgress = 0;

  void setUploadProgress(double progress) {
    uploadProgress = progress;
  }

  Future<void> prepareAndSignBundleTransaction({
    required ArweaveService arweaveService,
    required TurboUploadService turboUploadService,
    required PstService pstService,
    required Wallet wallet,
    bool isArConnect = false,
    bool useTurbo = false,
  }) async {
    final bundle = await DataBundle.fromHandles(
      parallelize: !isArConnect,
      handles: List.castFrom<FileDataItemUploadHandle, DataItemHandle>(
              fileDataItemUploadHandles) +
          List.castFrom<FolderDataItemUploadHandle, DataItemHandle>(
              folderDataItemUploadHandles),
    );

    logger.i('Bundle mounted');

    logger.i('Creating bundle transaction');
    if (useTurbo) {
      logger.i('Using turbo upload');
      bundleDataItem = await arweaveService.prepareBundledDataItem(
        bundle,
        wallet,
      );
      bundleId = bundleDataItem.id;
    } else {
      // Create bundle tx
      bundleTx = await arweaveService.prepareDataBundleTxFromBlob(
        bundle.blob,
        wallet,
      );

      bundleId = bundleTx.id;

      logger.i('Bundle transaction created');

      logger.i('Adding tip');

      await pstService.addCommunityTipToTx(bundleTx);

      logger.i('Tip added');

      logger.i('Signing bundle');

      await bundleTx.sign(wallet);

      logger.i('Bundle signed');
    }
  }

  // TODO: this should not be done here. Implement a new class that handles
  Future<void> writeBundleItemsToDatabase({
    required DriveDao driveDao,
  }) async {
    if (hasError) return;

    debugPrint('Writing bundle items to database');

    // Write entities to database
    for (var folder in folderDataItemUploadHandles) {
      await folder.writeFolderToDatabase(driveDao: driveDao);
    }
    for (var file in fileDataItemUploadHandles) {
      await file.writeFileEntityToDatabase(
        bundledInTxId: bundleId,
        driveDao: driveDao,
      );
    }
  }

  /// Uploads the bundle, emitting an event whenever the progress is updated.
  // Stream<double> upload(
  //   ArweaveService arweave,
  //   TurboUploadService turboUploadService,
  // ) async* {
  //   if (useTurbo) {
  //     await turboUploadService
  //         .postDataItem(dataItem: bundleDataItem)
  //         .onError((error, stackTrace) {
  //       logger.e(error);
  //       return hasError = true;
  //     });
  //     yield 1;
  //   } else {
  // yield* arweave.client.transactions
  //     .upload(bundleTx, maxConcurrentUploadCount: maxConcurrentUploadCount)
  //     .map((upload) {
  //   uploadProgress = upload.progress;
  //   return uploadProgress;
  // });
  //   }
  // }

  void dispose({bool useTurbo = false}) {
    if (!useTurbo) {
      bundleTx.setData(Uint8List(0));
    }
  }

  Future<int> computeBundleSize() async {
    final fileSizes = <int>[];
    for (var item in fileDataItemUploadHandles) {
      fileSizes.add(await item.estimateDataItemSizes());
    }
    for (var item in folderDataItemUploadHandles) {
      fileSizes.add(item.size);
    }
    var size = 0;
    // Add data item binary size
    size += fileSizes.reduce((value, element) => value + element);
    // Add data item offset and entry id for each data item
    size += (fileSizes.length * 64);
    // Add bytes that denote number of data items
    size += 32;
    this.size = size;
    return size;
  }

  @override
  int size;

  @override
  int get uploadedSize => (size * uploadProgress).round();

  @override
  bool hasError;
}

import 'dart:async';

import 'package:ardrive/blocs/blocs.dart';
import 'package:ardrive/entities/entities.dart';
import 'package:ardrive/entities/manifest_entity.dart';
import 'package:ardrive/entities/string_types.dart';
import 'package:ardrive/misc/misc.dart';
import 'package:ardrive/models/models.dart';
import 'package:ardrive/services/services.dart';
import 'package:arweave/arweave.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:uuid/uuid.dart';

part 'create_manifest_state.dart';

class CreateManifestCubit extends Cubit<CreateManifestState> {
  late FormGroup form;

  // final FolderEntry ghostFolder;
  final ProfileCubit _profileCubit;
  final DriveID driveId;

  final ArweaveService _arweave;
  final DriveDao _driveDao;
  final PstService _pst;

  StreamSubscription? _selectedFolderSubscription;

  CreateManifestCubit({
    // required this.ghostFolder,
    required this.driveId,
    required ProfileCubit profileCubit,
    required ArweaveService arweave,
    required DriveDao driveDao,
    required PstService pst,
  })  : _profileCubit = profileCubit,
        _arweave = arweave,
        _driveDao = driveDao,
        _pst = pst,
        super(CreateManifestInitial()) {
    form = FormGroup({
      'name': FormControl(
        validators: [
          Validators.required,
          Validators.pattern(kFileNameRegex),
          Validators.pattern(kTrimTrailingRegex),
        ],
      ),
    });
  }
  Future<void> loadParentFolder() async {
    final state = this.state as CreateManifestFolderLoadSuccess;
    if (state.viewingFolder.folder.parentFolderId != null) {
      return loadFolder(state.viewingFolder.folder.parentFolderId!);
    }
  }

  Future<void> chooseFolder() async {
    if (form.invalid) {
      // Chosen manifest name must be valid before proceeding
      return;
    }

    await _driveDao
        .driveById(driveId: driveId)
        .getSingle()
        .then((d) => loadFolder(d.rootFolderId));
  }

  Future<void> loadFolder(String folderId) async {
    await _selectedFolderSubscription?.cancel();

    _selectedFolderSubscription =
        _driveDao.watchFolderContents(driveId, folderId: folderId).listen(
              (f) => emit(
                CreateManifestFolderLoadSuccess(
                  viewingRootFolder: f.folder.parentFolderId == null,
                  viewingFolder: f,
                  movingEntryId: f.folder.id,
                ),
              ),
            );
  }

  Future<void> checkForConflicts() async {
    final name = form.control('name').value;
    final parentFolder =
        (state as CreateManifestFolderLoadSuccess).viewingFolder.folder;

    final foldersWithName = await _driveDao
        .foldersInFolderWithName(
            driveId: driveId, parentFolderId: parentFolder.id, name: name)
        .get();
    final filesWithName = await _driveDao
        .filesInFolderWithName(
            driveId: driveId, parentFolderId: parentFolder.id, name: name)
        .get();

    final conflictingFiles =
        filesWithName.where((e) => e.dataContentType != ContentType.manifest);

    if (foldersWithName.isNotEmpty || conflictingFiles.isNotEmpty) {
      // Name conflicts with existing file or folder
      // This is an error case, send user back to naming the manifest
      emit(CreateManifestNameConflict(name: name));
      return;
    }

    final manifestRevisionId = filesWithName
        .firstWhereOrNull((e) => e.dataContentType == ContentType.manifest)
        ?.id;

    if (manifestRevisionId != null) {
      emit(CreateManifestRevisionConfirm(
          id: manifestRevisionId, parentFolder: parentFolder));
      return;
    }

    await uploadManifest(parentFolder: parentFolder);
  }

  Future<void> uploadManifest(
      {FileID? existingManifestFileId,
      required FolderEntry parentFolder}) async {
    emit(CreateManifestUploadInProgress());
    try {
      final wallet = (_profileCubit.state as ProfileLoggedIn).wallet;
      final String manifestName = form.control('name').value;

      if (await _profileCubit.logoutIfWalletMismatch()) {
        emit(CreateManifestWalletMismatch());
        return;
      }

      final folderNode =
          (await _driveDao.getFolderTree(driveId, parentFolder.id));
      final arweaveManifest =
          ManifestEntity.fromFolderNode(folderNode: folderNode);

      final manifestDataItem =
          await arweaveManifest.asPreparedDataItem(wallet: wallet);
      await manifestDataItem.sign(wallet);

      /// Data JSON of the Metadata tx for the manifest
      final manifestFileEntity = FileEntity(
          size: arweaveManifest.size,
          parentFolderId: parentFolder.id,
          name: manifestName,
          lastModifiedDate: DateTime.now(),
          id: existingManifestFileId ?? Uuid().v4(),
          driveId: driveId,
          dataTxId: manifestDataItem.id,
          dataContentType: ContentType.manifest);

      final manifestMetaDataItem =
          await _arweave.prepareEntityDataItem(manifestFileEntity, wallet);
      await manifestMetaDataItem.sign(wallet);
      manifestFileEntity.txId = manifestMetaDataItem.id;

      final bundle = await DataBundle.fromDataItems(
          items: [manifestDataItem, manifestMetaDataItem]);

      final bundleTx = await _arweave.prepareDataBundleTxFromBlob(
        bundle.blob,
        wallet,
      );

      // Add tips to bundle tx
      final bundleTip = await _pst.getPSTFee(bundleTx.reward);
      bundleTx
        ..addTag(TipType.tagName, TipType.dataUpload)
        ..setTarget(await _pst.getWeightedPstHolder())
        ..setQuantity(bundleTip);
      await bundleTx.sign(wallet);

      manifestFileEntity.bundledIn = bundleTx.id;

      await _driveDao.transaction(() async {
        await _driveDao.writeFileEntity(
            manifestFileEntity, '${parentFolder.path}/$manifestName');
        await _driveDao.insertFileRevision(
          manifestFileEntity.toRevisionCompanion(
              performedAction: existingManifestFileId == null
                  ? RevisionAction.create
                  : RevisionAction.uploadNewVersion),
        );
      });

      await _arweave.client.transactions.upload(bundleTx).drain();

      emit(CreateManifestSuccess());
    } catch (err) {
      addError(err);
    }
  }

  @override
  Future<void> close() async {
    await _selectedFolderSubscription?.cancel();
    await super.close();
  }

  void backToName() {
    emit(CreateManifestInitial());
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    emit(CreateManifestFailure());
    super.onError(error, stackTrace);

    print('Failed to create manifest: $error $stackTrace');
  }
}

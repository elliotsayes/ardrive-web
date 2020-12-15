part of 'file_download_cubit.dart';

/// [ProfileFileDownloadCubit] includes logic to allow a user to download files
/// that they have attached to their profile.
class ProfileFileDownloadCubit extends FileDownloadCubit {
  final String driveId;
  final String fileId;

  final ProfileCubit _profileCubit;
  final DriveDao _driveDao;
  final ArweaveService _arweave;

  ProfileFileDownloadCubit({
    @required this.driveId,
    @required this.fileId,
    @required ProfileCubit profileCubit,
    @required DriveDao driveDao,
    @required ArweaveService arweave,
  })  : _profileCubit = profileCubit,
        _driveDao = driveDao,
        _arweave = arweave,
        super(FileDownloadStarting()) {
    download();
  }

  Future<void> download() async {
    try {
      final drive = await _driveDao.getDriveById(driveId);
      final file = await _driveDao.getFileById(driveId, fileId);

      emit(FileDownloadInProgress(
          fileName: file.name, totalByteCount: file.size));

      final dataRes = await http
          .get(_arweave.client.api.gatewayUrl.origin + '/${file.dataTxId}');

      Uint8List dataBytes;

      if (drive.isPublic) {
        dataBytes = dataRes.bodyBytes;
      } else if (drive.isPrivate) {
        final profile = _profileCubit.state as ProfileLoaded;

        final dataTx = await _arweave.getTransactionDetails(file.dataTxId);

        final fileKey =
            await _driveDao.getFileKey(driveId, fileId, profile.cipherKey);

        dataBytes =
            await decryptTransactionData(dataTx, dataRes.bodyBytes, fileKey);
      }

      emit(
        FileDownloadSuccess(
          fileName: file.name,
          fileExtension: extension(file.name),
          fileDataBytes: dataBytes,
        ),
      );
    } catch (err) {
      addError(err);
    }
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    emit(FileDownloadFailure());
    super.onError(error, stackTrace);
  }
}
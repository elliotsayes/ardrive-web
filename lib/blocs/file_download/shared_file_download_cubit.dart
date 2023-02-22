part of 'file_download_cubit.dart';

/// [StreamSharedFileDownloadCubit] includes logic to allow a user to download files that
/// are shared with them without a login.
class StreamSharedFileDownloadCubit extends FileDownloadCubit {
  final SecretKey? fileKey;
  final FileRevision revision;
  final ArweaveService _arweave;
  final DownloadService _downloadService;
  final Decrypt _decrypt;
  final ArDriveIO _ardriveIo;
  final IOFileAdapter _ioFileAdapter;

  StreamSharedFileDownloadCubit({
    this.fileKey,
    required this.revision,
    required ArweaveService arweave,
    required DownloadService downloadService,
    required Decrypt decrypt,
    required ArDriveIO ardriveIo,
    required IOFileAdapter ioFileAdapter,
  })  : _arweave = arweave,
        _downloadService = downloadService,
        _decrypt = decrypt,
        _ardriveIo = ardriveIo,
        _ioFileAdapter = ioFileAdapter,
        super(FileDownloadStarting()) {
    download();
  }

  Future<void> download() async {
    try {
      _downloadFile(revision);
    } catch (err) {
      addError(err);
    }
  }

  Future<void> _downloadFile(FileRevision revision) async {
    emit(
      FileDownloadInProgress(
        fileName: revision.name,
        totalByteCount: revision.size,
      ),
    );

    final dataTx = (await _arweave.getTransactionDetails(revision.dataTxId))!;
    final downloadLength = int.parse(dataTx.data.size);

    final fetchStream = _downloadService.downloadStream(revision.dataTxId, downloadLength);

    final splitStream = StreamSplitter(fetchStream);
    final saveStream = splitStream.split();
    final authStream = splitStream.split();
    unawaited(splitStream.close());

    Stream<Uint8List> decryptedDataStream;
    if (fileKey == null) {
      decryptedDataStream = saveStream;
    } else {
      decryptedDataStream = await _decrypt.decryptTransactionDataStream(
        dataTx,
        saveStream,
        Uint8List.fromList(await fileKey!.extractBytes()),
      );
    }

    final file = await _ioFileAdapter.fromReadStreamGenerator(
      ([s, e]) => decryptedDataStream,
      revision.size,
      name: revision.name,
      lastModifiedDate: revision.lastModifiedDate
    );

    try {
      final authenticatedOwner = authenticateOwner(
        _arweave,
        authStream,
        downloadLength,
        revision.dataTxId,
        dataTx,
      );
      final isAuthentic =  authenticatedOwner.then((value) => value != null);
      final saved = await _ardriveIo.saveFileStream(file, isAuthentic);
      if (!(await isAuthentic)) throw Exception('Failed authentication');
      if (!saved) throw Exception('Failed to save file');

      emit(
        FileDownloadFinishedWithSuccess(
          fileName: revision.name,
        ),
      );
    } on Exception catch (e) {
      emit(
        const FileDownloadFailure(
          FileDownloadFailureReason.unknownError,
        ),
      );
      debugPrint('Failed to download personal file: $e');
      return;
    }
  }

  @override
  void abortDownload() {
    emit(FileDownloadAborted());
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    emit(const FileDownloadFailure(FileDownloadFailureReason.unknownError));
    super.onError(error, stackTrace);

    log('Failed to download shared file: $error $stackTrace');
  }
}

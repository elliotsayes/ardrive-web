part of 'package:ardrive/blocs/sync/sync_cubit.dart';

Future<void> _updateLicenses({
  required DriveDao driveDao,
  required ArweaveService arweave,
  required LicenseService licenseService,
  required List<FileRevision> revisionsToSyncLicense,
}) async {
  final licenseTxIds =
      revisionsToSyncLicense.map((e) => e.licenseTxId!).toList();

  await for (final licenseAssertionTxsBatch
      in arweave.getLicenseAssertions(licenseTxIds)) {
    final licenseAssertionEntities = licenseAssertionTxsBatch
        .map((tx) => LicenseAssertionEntity.fromTransaction(tx));
    final licenseCompanions = licenseAssertionEntities.map((entity) {
      final revision = revisionsToSyncLicense.firstWhere(
        (rev) => rev.licenseTxId == entity.txId,
      );
      final licenseType =
          licenseService.licenseTypeByTxId(entity.licenseDefinitionTxId);
      return entity.toCompanion(
        fileId: revision.fileId,
        driveId: revision.driveId,
        licenseType: licenseType ?? LicenseType.unknown,
      );
    });

    await driveDao.transaction(
      () async => {
        for (final licenseAssertionCompanion in licenseCompanions)
          {await driveDao.insertLicense(licenseAssertionCompanion)}
      },
    );
  }
}
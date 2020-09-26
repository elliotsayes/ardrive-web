import 'dart:convert';
import 'dart:typed_data';

import 'package:arweave/arweave.dart';
import 'package:cryptography/cryptography.dart';
import 'package:drive/services/services.dart';
import 'package:json_annotation/json_annotation.dart';

import 'entities.dart';

part 'drive_entity.g.dart';

@JsonSerializable()
class DriveEntity extends Entity {
  @JsonKey(ignore: true)
  String id;
  @JsonKey(ignore: true)
  String privacy;
  @JsonKey(ignore: true)
  String authMode;

  String rootFolderId;

  DriveEntity({this.id, this.rootFolderId, this.privacy, this.authMode});

  static Future<DriveEntity> fromTransaction(
    TransactionCommonMixin transaction,
    Uint8List data, [
    SecretKey driveKey,
  ]) async {
    final drivePrivacy = transaction.getTag(EntityTag.drivePrivacy);

    final entityJson = drivePrivacy != DrivePrivacy.private
        ? json.decode(utf8.decode(data))
        : await decryptDriveEntityJson(transaction, data, driveKey);

    return DriveEntity.fromJson(entityJson)
      ..id = transaction.getTag(EntityTag.driveId)
      ..privacy = drivePrivacy ?? DrivePrivacy.public
      ..authMode = transaction.getTag(EntityTag.driveAuthMode)
      ..ownerAddress = transaction.owner.address
      ..commitTime = transaction.getCommitTime();
  }

  @override
  Future<Transaction> asTransaction([SecretKey driveKey]) async {
    assert(id != null && rootFolderId != null);

    final tx = driveKey == null
        ? Transaction.withJsonData(data: this)
        : await createEncryptedEntityTransaction(this, driveKey);

    tx
      ..addApplicationTags()
      ..addTag(EntityTag.entityType, EntityType.drive)
      ..addTag(EntityTag.driveId, id);

    if (privacy == DrivePrivacy.private) {
      tx
        ..addTag(EntityTag.drivePrivacy, privacy)
        ..addTag(EntityTag.driveAuthMode, authMode);
    }

    return tx;
  }

  factory DriveEntity.fromJson(Map<String, dynamic> json) =>
      _$DriveEntityFromJson(json);
  Map<String, dynamic> toJson() => _$DriveEntityToJson(this);
}
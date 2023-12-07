import 'package:ardrive/core/arfs/entities/arfs_entities.dart';
import 'package:ardrive_uploader/ardrive_uploader.dart';
import 'package:json_annotation/json_annotation.dart';

part 'plausible_custom_event_properties.g.dart';

@JsonSerializable()
class AppLoadedProperties {
  @JsonKey(name: 'App Version')
  String appVersion;
  @JsonKey(name: 'Platform')
  String platform;
  @JsonKey(name: 'Platform Version')
  String platformVersion;

  AppLoadedProperties({
    required this.appVersion,
    required this.platform,
    required this.platformVersion,
  });

  factory AppLoadedProperties.fromJson(Map<String, dynamic> json) =>
      _$AppLoadedPropertiesFromJson(json);
  Map<String, dynamic> toJson() => _$AppLoadedPropertiesToJson(this);
}

@JsonSerializable()
class NewButtonProperties {
  @JsonKey(name: 'Location')
  NewButtonLocation location;

  NewButtonProperties({
    required this.location,
  });

  factory NewButtonProperties.fromJson(Map<String, dynamic> json) =>
      _$NewButtonPropertiesFromJson(json);
  Map<String, dynamic> toJson() => _$NewButtonPropertiesToJson(this);
}

@JsonSerializable()
class UploadReviewProperties {
  @JsonKey(
    name: 'Drive Privacy',
    fromJson: drivePrivacyFromJson,
    toJson: drivePrivacyToJson,
  )
  DrivePrivacy drivePrivacy;
  @JsonKey(
    name: 'Upload Type',
    fromJson: uploadTypeFromJson,
    toJson: uploadTypeToJson,
  )
  UploadType uploadType;
  @JsonKey(name: 'Drag n Drop')
  bool dragNDrop;

  @JsonKey(name: 'Has Folders')
  bool hasFolders;
  @JsonKey(name: 'Single File')
  bool hasSingleFile;
  @JsonKey(name: 'Multiple Files')
  bool hasMultipleFiles;

  UploadReviewProperties({
    required this.drivePrivacy,
    required this.uploadType,
    required this.dragNDrop,
    required this.hasFolders,
    required this.hasSingleFile,
    required this.hasMultipleFiles,
  });

  factory UploadReviewProperties.fromJson(Map<String, dynamic> json) =>
      _$UploadReviewPropertiesFromJson(json);
  Map<String, dynamic> toJson() => _$UploadReviewPropertiesToJson(this);

  static DrivePrivacy drivePrivacyFromJson(String value) {
    return DrivePrivacy.values.firstWhere((e) => e.toString() == value);
  }

  static String drivePrivacyToJson(DrivePrivacy drivePrivacy) {
    return drivePrivacy.toString();
  }

  static UploadType uploadTypeFromJson(String value) {
    return UploadType.values.firstWhere((e) => e.toString() == value);
  }

  static String uploadTypeToJson(UploadType uploadType) {
    return uploadType.toString();
  }
}

enum NewButtonLocation {
  bottom,
  sidebar,
}

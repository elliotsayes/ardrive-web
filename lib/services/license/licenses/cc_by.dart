import '../license_state.dart';

List<LicenseMeta> ccLicenses = [
  ccByLicenseMeta,
  ccByNCLicenseMeta,
  ccByNCNDLicenseMeta,
  ccByNCSA,
  ccByNDLicenseMeta,
  ccBySA,
];

const ccByLicenseMeta = LicenseMeta(
  licenseType: LicenseType.ccBy,
  licenseDefinitionTxId: 'rz2DNzn9pnYOU6049Wm6V7kr0BhyfWE6ZD_mqrXMv5A',
  name: 'Attribution',
  shortName: 'CC-BY',
  version: '4.0',
  hasParams: true,
);

const ccByNCLicenseMeta = LicenseMeta(
  licenseType: LicenseType.ccByNC,
  licenseDefinitionTxId: '9jG6a1fWgQ_wE4R6OGA2Xg9vGRAwpkrQIMC83nC3kvI',
  name: 'Attribution Non-Commercial',
  shortName: 'CC-BY-NC',
  version: '4.0',
);

const ccByNCNDLicenseMeta = LicenseMeta(
  licenseType: LicenseType.ccByNCND,
  licenseDefinitionTxId: 'OlTlW1xEw75UC0cdmNqvxc3j6iAmFXrS4usWIBfu_3E',
  name: 'Attribution Non-Commercial No-Derivatives',
  shortName: 'CC-BY-NC-ND',
  version: '4.0',
);

const ccByNCSA = LicenseMeta(
  licenseType: LicenseType.ccByNCSA,
  licenseDefinitionTxId: '2PO2MDRNZLJjgA_0hNGUAD7yXg9nneq-3fxTTLP-uo8',
  name: 'Attribution Non-Commercial Share-A-Like',
  shortName: 'CC-BY-NC-SA',
  version: '4.0',
);

const ccByNDLicenseMeta = LicenseMeta(
  licenseType: LicenseType.ccByND,
  licenseDefinitionTxId: 'XaIMRBMNqTUlHa_hzypkopfRFyAKqit-AWo-OxwIxoo',
  name: 'Attribution No-Derivatives',
  shortName: 'CC-BY-ND',
  version: '4.0',
);

const ccBySA = LicenseMeta(
  licenseType: LicenseType.ccBySA,
  licenseDefinitionTxId: 'sKz-PZ96ApDoy5RTBspxhs1GP-cHommw4_9hEiZ6K3c',
  name: 'Attribution Share-A-Like',
  shortName: 'CC-BY-SA',
  version: '4.0',
);

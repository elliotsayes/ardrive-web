import 'package:ardrive/services/license/license_state.dart';
import 'package:ardrive/services/license/licenses/cc.dart';
import 'package:reactive_forms/reactive_forms.dart';

const ccLicensesEnabled = [
  cc0LicenseMeta,
  ccByLicenseMetaV2,
  ccByNCLicenseMeta,
  ccByNCNDLicenseMeta,
  ccByNCSAMeta,
  ccByNDLicenseMeta,
  ccBySAMeta,
];

const ccLicenseDefault = ccByLicenseMetaV2;

FormGroup createCcTypeForm() => FormGroup({
      'ccTypeField': FormControl<LicenseMeta>(
        validators: [Validators.required],
        value: ccLicenseDefault,
      ),
    });

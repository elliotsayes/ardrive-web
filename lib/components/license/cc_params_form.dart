import 'package:ardrive/blocs/fs_entry_license/fs_entry_license_bloc.dart';
import 'package:ardrive/components/labeled_input.dart';
import 'package:ardrive/l11n/validation_messages.dart';
import 'package:ardrive/services/license/license_state.dart';
import 'package:ardrive/services/license/licenses/cc_by.dart';
import 'package:ardrive/utils/app_localizations_wrapper.dart';
import 'package:ardrive_ui/ardrive_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reactive_forms/reactive_forms.dart';

class CcParamsForm extends StatefulWidget {
  const CcParamsForm({super.key, required this.formGroup});

  final FormGroup formGroup;

  @override
  State<CcParamsForm> createState() => _CcParamsFormState();
}

class _CcParamsFormState extends State<CcParamsForm> {
  LicenseMeta get licenseMeta =>
      context.read<FsEntryLicenseBloc>().selectedLicenseMeta;

  @override
  Widget build(BuildContext context) {
    final inputBorder = OutlineInputBorder(
      borderSide: BorderSide(
        color: ArDriveTheme.of(context)
            .themeData
            .colors
            .themeFgDisabled
            .withOpacity(0.3),
        width: 2,
      ),
      borderRadius: BorderRadius.circular(4),
    );

    return ReactiveForm(
      formGroup: widget.formGroup,
      child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: LabeledInput(
                    labelText: 'Type',
                    child: ReactiveDropdownField(
                      formControlName: 'ccAttributionField',
                      decoration: InputDecoration(
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                      ),
                      onChanged: (e) {
                        setState(() {});
                      },
                      showErrors: (control) => control.dirty && control.invalid,
                      validationMessages:
                          kValidationMessages(appLocalizationsOf(context)),
                      items: ccLicenses
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.name),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
            Builder(
              builder: (context) {
                final selectedLicenseMeta = context
                    .watch<FsEntryLicenseBloc>()
                    .ccForm
                    .value['ccAttributionField'] as LicenseMeta;

                return Text(
                  selectedLicenseMeta.shortName,
                  style: ArDriveTypography.body.buttonNormalBold(
                    color: ArDriveTheme.of(context)
                        .themeData
                        .colors
                        .themeFgDisabled,
                  ),
                );
              },
            ),
          ]),
    );
  }
}

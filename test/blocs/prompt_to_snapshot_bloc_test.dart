import 'package:ardrive/blocs/prompt_to_snapshot/prompt_to_snapshot_bloc.dart';
import 'package:ardrive/blocs/prompt_to_snapshot/prompt_to_snapshot_event.dart';
import 'package:ardrive/blocs/prompt_to_snapshot/prompt_to_snapshot_state.dart';
import 'package:ardrive/utils/key_value_store.dart';
import 'package:ardrive/utils/local_key_value_store.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const durationBeforePrompting = Duration(milliseconds: 200);
const numberOfTxsBeforeSnapshot = 3;
const driveId = 'test-drive-id';

void main() {
  late PromptToSnapshotBloc promptToSnapshotBloc;
  late KeyValueStore store;

  WidgetsFlutterBinding.ensureInitialized();

  group('PromptToSnapshotBloc class', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final fakePrefs = await SharedPreferences.getInstance();
      store = await LocalKeyValueStore.getInstance(prefs: fakePrefs);
      promptToSnapshotBloc = PromptToSnapshotBloc(
        store: store,
        durationBeforePrompting: durationBeforePrompting,
        numberOfTxsBeforeSnapshot: numberOfTxsBeforeSnapshot,
      );
    });

    blocTest(
      'can count through txs',
      build: () => promptToSnapshotBloc,
      act: (PromptToSnapshotBloc bloc) async {
        bloc.add(const CountSyncedTxs(
          driveId: driveId,
          txsSyncedWithGqlCount: 1,
          wasDeepSync: false,
        ));
        bloc.add(const CountSyncedTxs(
          driveId: driveId,
          txsSyncedWithGqlCount: 2,
          wasDeepSync: false,
        ));
        bloc.add(const CountSyncedTxs(
          driveId: driveId,
          txsSyncedWithGqlCount: 3,
          wasDeepSync: false,
        ));
      },
      expect: () => [
        // By this point we've counted 6 TXs
      ],
    );

    blocTest(
      'will prompt to snapshot after enough txs',
      build: () => promptToSnapshotBloc,
      act: (PromptToSnapshotBloc bloc) async {
        bloc.add(const SelectedDrive(driveId: driveId));
        const durationAfterPrompting = Duration(milliseconds: 250);
        await Future<void>.delayed(durationAfterPrompting);
      },
      expect: () => [
        const PromptToSnapshotPrompting(driveId: driveId),
      ],
    );

    blocTest(
      'will not prompt to snapshot if drive is deselected',
      build: () => promptToSnapshotBloc,
      act: (PromptToSnapshotBloc bloc) async {
        bloc.add(const SelectedDrive(driveId: driveId));
        bloc.add(const SelectedDrive(driveId: null));
        const durationAfterPrompting = Duration(milliseconds: 250);
        await Future<void>.delayed(durationAfterPrompting);
      },
      expect: () => [
        const PromptToSnapshotIdle(driveId: null),
      ],
    );

    blocTest(
      'selecting an already snapshotted drive does nothing',
      build: () => promptToSnapshotBloc,
      act: (PromptToSnapshotBloc bloc) async {
        bloc.add(const DriveSnapshotted(driveId: driveId));
        bloc.add(const SelectedDrive(driveId: driveId));
        const durationAfterPrompting = Duration(milliseconds: 250);
        await Future<void>.delayed(durationAfterPrompting);
      },
      expect: () => [
        const PromptToSnapshotIdle(driveId: driveId),
      ],
    );

    blocTest(
      'selecting a drive after choosing not to be asked again does nothing',
      build: () => promptToSnapshotBloc,
      act: (PromptToSnapshotBloc bloc) async {
        bloc.add(const DismissDontAskAgain());
        bloc.add(const SelectedDrive(driveId: driveId));
        const durationAfterPrompting = Duration(milliseconds: 250);
        await Future<void>.delayed(durationAfterPrompting);
      },
      expect: () => [
        const PromptToSnapshotIdle(driveId: null),
      ],
    );
  });
}

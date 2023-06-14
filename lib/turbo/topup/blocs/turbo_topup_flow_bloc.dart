import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'turbo_topup_flow_event.dart';
part 'turbo_topup_flow_state.dart';

class TurboTopupFlowBloc
    extends Bloc<TurboTopupFlowEvent, TurboTopupFlowState> {
  int _currentStep = 1;

  TurboTopupFlowBloc() : super(const TurboTopupFlowInitial()) {
    on<TurboTopupFlowEvent>((event, emit) async {
      if (event is TurboTopUpShowEstimationView) {
        emit(TurboTopupFlowShowingEstimationView(
          isMovingForward: _currentStep <= event.stepNumber,
        ));
      }
      _currentStep = event.stepNumber;
    });
  }
}

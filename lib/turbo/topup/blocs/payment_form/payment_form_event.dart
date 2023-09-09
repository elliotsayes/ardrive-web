part of 'payment_form_bloc.dart';

abstract class PaymentFormEvent extends Equatable {
  const PaymentFormEvent();

  @override
  List<Object> get props => [];
}

class PaymentFormLoadSupportedCountries extends PaymentFormEvent {}

class PaymentFormPrePopulateFields extends PaymentFormEvent {}

class PaymentFormUpdateQuote extends PaymentFormEvent {}

class PaymentFormUpdatePromoCode extends PaymentFormEvent {
  const PaymentFormUpdatePromoCode(this.promoCode);

  final String? promoCode;

  @override
  List<Object> get props => [promoCode ?? ''];
}

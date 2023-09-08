import 'package:ardrive/turbo/services/payment_service.dart';
import 'package:equatable/equatable.dart';

class PriceEstimate extends Equatable {
  final PriceForFiat estimate;
  final double priceInCurrency;
  final double estimatedStorage;
  // final double promoDiscountFactor;

  const PriceEstimate({
    required this.estimate,
    required this.priceInCurrency,
    required this.estimatedStorage,
    // required this.promoDiscountFactor,
  });

  factory PriceEstimate.zero() => PriceEstimate(
        estimate: PriceForFiat.zero(),
        priceInCurrency: 0,
        estimatedStorage: 0,
        // promoDiscountFactor: 0,
      );

  @override
  String toString() {
    return 'PriceEstimate{credits: ${estimate.winstonCredits},'
        ' priceInCurrency: $priceInCurrency,'
        ' estimatedStorage: $estimatedStorage,';
  }

  @override
  List<Object?> get props => [
        estimate,
        priceInCurrency,
        estimatedStorage,
      ];
}

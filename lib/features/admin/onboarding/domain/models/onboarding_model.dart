import 'package:equatable/equatable.dart';

class OnboardingData extends Equatable {
  final bool sellerCompleted;
  final bool buyerCompleted;
  final String? shopName;
  final String? category;
  final List<String>? interests;

  const OnboardingData({
    this.sellerCompleted = false,
    this.buyerCompleted = false,
    this.shopName,
    this.category,
    this.interests,
  });

  OnboardingData copyWith({
    bool? sellerCompleted,
    bool? buyerCompleted,
    String? shopName,
    String? shopCategory,
    List<String>? interests,
  }) {
    return OnboardingData(
      sellerCompleted: sellerCompleted ?? this.sellerCompleted,
      buyerCompleted: buyerCompleted ?? this.buyerCompleted,
      shopName: shopName ?? this.shopName,
      category: shopCategory ?? category,
      interests: interests ?? this.interests,
    );
  }

  @override
  List<Object?> get props => [
        sellerCompleted,
        buyerCompleted,
        shopName,
        category,
        interests,
      ];
}

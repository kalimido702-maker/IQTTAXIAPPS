import 'package:equatable/equatable.dart';

/// States for [ReferralCubit].
abstract class ReferralState extends Equatable {
  const ReferralState();

  @override
  List<Object?> get props => [];
}

/// Referral data loaded.
class ReferralLoaded extends ReferralState {
  final String referralCode;
  final bool codeCopied;

  const ReferralLoaded({
    required this.referralCode,
    this.codeCopied = false,
  });

  ReferralLoaded copyWith({String? referralCode, bool? codeCopied}) {
    return ReferralLoaded(
      referralCode: referralCode ?? this.referralCode,
      codeCopied: codeCopied ?? this.codeCopied,
    );
  }

  @override
  List<Object?> get props => [referralCode, codeCopied];
}

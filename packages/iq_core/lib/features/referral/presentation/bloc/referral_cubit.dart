import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_strings.dart';
import 'referral_state.dart';

/// Cubit for the Referral / "أحل واكسب" feature.
///
/// Manages clipboard copy and share actions through state management.
class ReferralCubit extends Cubit<ReferralState> {
  ReferralCubit({required String referralCode})
      : super(ReferralLoaded(referralCode: referralCode));

  /// Copy the referral code to clipboard.
  Future<void> copyCode() async {
    final currentState = state;
    if (currentState is! ReferralLoaded) return;

    await Clipboard.setData(ClipboardData(text: currentState.referralCode));
    emit(currentState.copyWith(codeCopied: true));

    // Reset the copied flag after a delay.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (state is ReferralLoaded) {
      emit((state as ReferralLoaded).copyWith(codeCopied: false));
    }
  }

  /// Share the referral code via platform share sheet.
  Future<void> shareCode() async {
    final currentState = state;
    if (currentState is! ReferralLoaded) return;

    await Share.share(
      '${AppStrings.referralShareMessage} ${currentState.referralCode} ${AppStrings.forDiscount}',
      sharePositionOrigin: const Rect.fromLTWH(0, 0, 100, 100),
    );
  }
}

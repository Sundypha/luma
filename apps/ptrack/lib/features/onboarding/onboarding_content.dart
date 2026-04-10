import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// One step in the first-run onboarding wizard.
@immutable
class OnboardingPageData {
  const OnboardingPageData({
    required this.title,
    required this.body,
    required this.icon,
    this.isRequired = false,
  });

  final String title;
  final String body;
  final IconData icon;

  /// When true, the user must use Continue (no Skip); swipe is disabled.
  final bool isRequired;
}

/// Number of onboarding steps (must match [buildOnboardingPages]).
const int kOnboardingPageCount = 3;

/// Ordered onboarding copy from ARB (privacy, estimates, optional quick-start).
List<OnboardingPageData> buildOnboardingPages(AppLocalizations l10n) {
  return [
    OnboardingPageData(
      title: l10n.onbPrivacyTitle,
      body: l10n.onbPrivacyBody,
      icon: Icons.phone_android,
      isRequired: true,
    ),
    OnboardingPageData(
      title: l10n.onbEstimatesTitle,
      body: l10n.onbEstimatesBody,
      icon: Icons.lightbulb_outline,
      isRequired: true,
    ),
    OnboardingPageData(
      title: l10n.onbReadyTitle,
      body: l10n.onbReadyBody,
      icon: Icons.calendar_today,
      isRequired: false,
    ),
  ];
}

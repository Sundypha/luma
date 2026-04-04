import 'package:flutter/material.dart';

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

/// Ordered onboarding copy: privacy, estimates disclaimer, optional quick-start.
const List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    title: 'Your data stays here',
    body:
        'Everything you log stays on this device. There’s no account to create, '
        'no cloud sync, and no sign-up — just your phone and your entries.',
    icon: Icons.phone_android,
    isRequired: true,
  ),
  OnboardingPageData(
    title: 'Estimates, not medical advice',
    body:
        'Forecasts are based on the history you add here. They’re personal estimates '
        'to help you notice patterns — not a diagnosis, treatment, or substitute for '
        'care from a qualified health professional.',
    icon: Icons.lightbulb_outline,
    isRequired: true,
  ),
  OnboardingPageData(
    title: 'Ready to start',
    body:
        'Log when your period starts to get going. The more you add over time, '
        'the more helpful your estimates can be — and you can always skip for now.',
    icon: Icons.calendar_today,
    isRequired: false,
  ),
];

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../l10n/app_localizations.dart';
import 'onboarding_content.dart';
import 'onboarding_page.dart';
import 'onboarding_state.dart';

/// Multi-step onboarding wizard with required/optional gating and dot indicator.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onboardingState,
    required this.onComplete,
  });

  final OnboardingState onboardingState;
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  late int _currentPage;
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    final maxIndex = kOnboardingPageCount - 1;
    final initial = widget.onboardingState.currentStep.clamp(0, maxIndex);
    _currentPage = initial;
    _controller = PageController(initialPage: initial);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage >= kOnboardingPageCount - 1;

  Future<void> _goToNext() async {
    if (_isAdvancing) return;
    setState(() => _isAdvancing = true);
    try {
      if (!_isLastPage) {
        final next = _currentPage + 1;
        await widget.onboardingState.saveStep(next);
        await _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        await widget.onboardingState.markCompleted();
        widget.onComplete();
      }
    } finally {
      if (mounted) {
        setState(() => _isAdvancing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final pages = buildOnboardingPages(l10n);
    final requiredNow = pages[_currentPage].isRequired;
    final primaryLabel = _isLastPage ? l10n.onbGetStarted : l10n.onbContinue;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                  widget.onboardingState.saveStep(index);
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(data: pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Semantics(
                    label: l10n.onbStepSemantics(
                      _currentPage + 1,
                      pages.length,
                    ),
                    child: SmoothPageIndicator(
                      controller: _controller,
                      count: pages.length,
                      effect: ExpandingDotsEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        expansionFactor: 3,
                        spacing: 6,
                        activeDotColor: scheme.primary,
                        dotColor: scheme.outline.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (requiredNow)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isAdvancing ? null : _goToNext,
                        child: Text(primaryLabel),
                      ),
                    )
                  else if (_isLastPage)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isAdvancing ? null : _goToNext,
                        child: Text(primaryLabel),
                      ),
                    )
                  else
                    Row(
                      children: [
                        TextButton(
                          onPressed: _isAdvancing ? null : _goToNext,
                          child: Text(l10n.onbSkip),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: _isAdvancing ? null : _goToNext,
                          child: Text(primaryLabel),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

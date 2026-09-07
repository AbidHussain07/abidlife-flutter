import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../ui/ui.dart';
import '../ui/widgets/logo.dart';

/// First-run onboarding flow.
///
/// Walks the user through the 5 modules — Notes, Tasks, Habits, Money,
/// Insights — with a single "Get started" CTA. Re-playable from the
/// Settings sheet (sets `abidlife.onboarded = false`).
class Onboarding extends StatefulWidget {
  const Onboarding({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final _controller = PageController();
  int _page = 0;

  static const _steps = <_Step>[
    _Step(
      icon: LucideIcons.notebookPen,
      color: 'amber',
      title: 'Notes',
      body: 'Capture ideas with rich text, checklists, images and PIN-locked private notes.',
    ),
    _Step(
      icon: LucideIcons.checkCircle2,
      color: 'blue',
      title: 'Tasks',
      body: 'Track what to do, with priorities, due dates, reminders and repeat rules.',
    ),
    _Step(
      icon: LucideIcons.flame,
      color: 'green',
      title: 'Habits',
      body: 'Build streaks with daily or weekly habits. Tap once to check off today.',
    ),
    _Step(
      icon: LucideIcons.wallet,
      color: 'teal',
      title: 'Money',
      body: 'Track income and expenses for yourself and anyone you manage — in INR.',
    ),
    _Step(
      icon: LucideIcons.sparkles,
      color: 'violet',
      title: 'Insights',
      body: 'A single dashboard ties it all together with smart, contextual nudges.',
    ),
  ];

  void _next() {
    buzz(7);
    if (_page == _steps.length - 1) {
      widget.onDone();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
    setState(() => _page++);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: TextButton(
                  onPressed: widget.onDone,
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: c.ink3,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _steps[i];
                  final accent = c.accent(s.color);
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const LumaLogo(size: 56),
                        const SizedBox(height: 24),
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: c.tint(s.color, 14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, size: 40, color: accent),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          s.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: c.ink2,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: active ? c.brand : c.surface3,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.brand,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: Text(
                        _page == _steps.length - 1 ? 'Get started' : 'Next',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
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

class _Step {
  final IconData icon;
  final String color;
  final String title;
  final String body;
  const _Step({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });
}

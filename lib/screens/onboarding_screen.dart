import 'package:abidlife/core/app_theme.dart';
import 'package:abidlife/core/brand_mark.dart';
import 'package:abidlife/providers/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  var _index = 0;

  static const _slides = <({String title, String body, IconData icon, Color color})>[
    (
      title: 'Everything you need, in one place.',
      body: 'Notes, tasks, habits and money — one calm home for your whole day.',
      icon: Icons.auto_awesome_rounded,
      color: AppColors.brand,
    ),
    (
      title: 'Organize thoughts, tasks and habits.',
      body: 'Capture ideas in seconds, finish what matters, and build streaks that stick.',
      icon: Icons.task_alt_rounded,
      color: AppColors.green,
    ),
    (
      title: 'Keep track of money and progress.',
      body: 'Friendly personal finance and honest insights, calculated only from your data.',
      icon: Icons.account_balance_wallet_rounded,
      color: AppColors.teal,
    ),
  ];

  Future<void> _done() => ref.read(appControllerProvider).finishOnboarding();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  const BrandMark(size: 34),
                  const SizedBox(width: 10),
                  Text(
                    'LifeDeck',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(onPressed: _done, child: const Text('Skip')),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            color: slide.color.withValues(alpha: .12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(slide.icon, size: 68, color: slide.color),
                        ),
                        const SizedBox(height: 44),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 14),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                children: <Widget>[
                  Row(
                    children: List<Widget>.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: index == _index ? 25 : 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: index == _index
                              ? AppColors.brand
                              : Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      if (_index == _slides.length - 1) {
                        _done();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                    label: Text(_index == _slides.length - 1 ? 'Get started' : 'Next'),
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class WelcomeCarousel extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomeCarousel({super.key, required this.onGetStarted});

  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_OnboardingSlide> _slides = [
    const _OnboardingSlide(
      title: 'Welcome to Desk Sense',
      description:
          'Your intelligent companion for natural language file management.',
      icon: Icons.smart_toy_outlined,
      color: Colors.blue,
    ),
    const _OnboardingSlide(
      title: 'Tag Files with @',
      description:
          'Type @ in the chat to tag files or folders. I\'ll use them as context for your questions.',
      icon: Icons.alternate_email,
      color: Colors.purple,
    ),
    const _OnboardingSlide(
      title: 'Natural Language Search',
      description:
          'Ask me to "find all pdfs from last week" or "search for project notes in my documents".',
      icon: Icons.search,
      color: Colors.green,
    ),
    const _OnboardingSlide(
      title: 'Smart Organization',
      description:
          'Let me help you organize your workspace. "Move all screenshots to a new folder called Images".',
      icon: Icons.folder_open,
      color: Colors.orange,
    ),
    const _OnboardingSlide(
      title: 'Ready to Begin?',
      description:
          'Start a conversation and see how I can simplify your workflow.',
      icon: Icons.auto_awesome,
      color: Colors.teal,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      children: [
        // Skip button top-right
        Positioned(
          top: 12,
          right: 12,
          child: TextButton(
            onPressed: widget.onGetStarted,
            child: const Text('Skip'),
          ),
        ),
        Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Carousel
                SizedBox(
                  height: 350,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) =>
                        setState(() => _currentIndex = index),
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: slide.color.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                slide.icon,
                                size: 64,
                                color: slide.color,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              slide.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              slide.description,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Indicator & Action
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Dots
                      Row(
                        children: List.generate(
                          _slides.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentIndex == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),

                      // Button
                      if (_currentIndex == _slides.length - 1)
                        FilledButton.icon(
                          onPressed: widget.onGetStarted,
                          icon: const Icon(Icons.rocket_launch),
                          label: const Text('Get Started'),
                        )
                      else
                        TextButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Text('Next'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

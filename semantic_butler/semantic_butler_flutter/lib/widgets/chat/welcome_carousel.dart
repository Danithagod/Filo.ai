import 'package:flutter/material.dart';
import '../home/filo_hero_logo.dart';

class WelcomeCarousel extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomeCarousel({super.key, required this.onGetStarted});

  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<WelcomeSlide> _slides = [
    WelcomeSlide(
      title: 'Welcome to Filo',
      description:
          'The intelligent way to search and organize your local files.',
      icon: Icons.auto_awesome,
    ),
    WelcomeSlide(
      title: 'Semantic Search',
      description: 'Find what you need by meaning, not just keywords.',
      icon: Icons.search_rounded,
    ),
    WelcomeSlide(
      title: 'Privacy First',
      description: 'Your data stays on your machine. Broad indexing is local.',
      icon: Icons.security_rounded,
    ),
    WelcomeSlide(
      title: 'Instant Actions',
      description: 'Organize, summarize, and move files with ease.',
      icon: Icons.bolt_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Use the FiloHeroLogo as a persistent header
              const SizedBox(height: 32),
              SizedBox(
                height: 80,
                child: FiloHeroLogo(
                  size: 80,
                ),
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final data = _slides[index];
                    final color = [
                      colorScheme.primary,
                      colorScheme.tertiary,
                      colorScheme.secondary,
                      colorScheme.primary,
                    ][index];

                    return Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              data.icon,
                              size: 64,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            data.title,
                            textAlign: TextAlign.center,
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            data.description,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Indicators and Button
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _currentPage == _slides.length - 1
                            ? widget.onGetStarted
                            : () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              ),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          _currentPage == _slides.length - 1
                              ? 'Get Started'
                              : 'Next',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeSlide {
  final String title;
  final String description;
  final IconData icon;

  WelcomeSlide({
    required this.title,
    required this.description,
    required this.icon,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingCarousel extends StatefulWidget {
  final VoidCallback onFinish;
  final Function(double)? onScroll;

  const OnboardingCarousel({super.key, required this.onFinish, this.onScroll});

  @override
  State<OnboardingCarousel> createState() => _OnboardingCarouselState();
}

class _OnboardingCarouselState extends State<OnboardingCarousel> {
  final PageController _pageController = PageController();
  double _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Welcome to Filo',
      description:
          'The intelligent way to search and organize your local files using AI power.',
      icon: Icons.auto_awesome_rounded,
      color: Colors.blue,
    ),
    OnboardingData(
      title: 'Semantic Search',
      description:
          'Search by meaning, not just keywords. Find "that PDF about taxes from last year" instantly.',
      icon: Icons.search_rounded,
      color: Colors.deepPurple,
    ),
    OnboardingData(
      title: 'Privacy First',
      description:
          'Your data stays on your machine. We index locally for maximum security and speed.',
      icon: Icons.security_rounded,
      color: Colors.teal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      setState(() {
        _currentPage = page;
      });
      widget.onScroll?.call(page);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(index);
            },
          ),
        ),
        _buildBottomBar(colorScheme),
      ],
    );
  }

  Widget _buildPage(int index) {
    final data = _pages[index];
    final double pageOffset = index - _currentPage;

    // Parallax and fade effects
    final double opacity = (1 - pageOffset.abs()).clamp(0.0, 1.0);
    final double scale = (1 - (pageOffset.abs() * 0.2)).clamp(0.8, 1.0);
    final double iconTranslation = pageOffset * 200;
    final double textTranslation = pageOffset * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(iconTranslation, 0),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: data.color.withValues(alpha: 0.1),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: index == 0
                      ? SvgPicture.asset(
                          'assets/filo_logo.svg',
                          width: 80,
                          height: 80,
                          colorFilter: ColorFilter.mode(
                            data.color,
                            BlendMode.srcIn,
                          ),
                        )
                      : Icon(
                          data.icon,
                          size: 100,
                          color: data.color,
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 64),
          Transform.translate(
            offset: Offset(textTranslation, 0),
            child: Opacity(
              opacity: opacity,
              child: Column(
                children: [
                  Text(
                    data.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 18,
                      height: 1.6,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ColorScheme colorScheme) {
    final bool isLastPage = _currentPage.round() == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Custom Page Indicator
          Row(
            children: List.generate(
              _pages.length,
              (index) {
                final double selectedness =
                    (1 - (index - _currentPage).abs()).clamp(0.0, 1.0);
                final double width = 8 + (16 * selectedness);
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  height: 8,
                  width: width,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      colorScheme.outlineVariant,
                      _pages[index].color,
                      selectedness,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              },
            ),
          ),

          // Action Button
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              onPressed: () {
                if (_currentPage.round() < _pages.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.fastOutSlowIn,
                  );
                } else {
                  widget.onFinish();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastPage
                    ? _pages[_pages.length - 1].color
                    : colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.all(
                  Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  isLastPage ? 'Get Started' : 'Next',
                  key: ValueKey(isLastPage),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

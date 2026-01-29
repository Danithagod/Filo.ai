import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/settings_service.dart';
import '../widgets/onboarding/onboarding_carousel.dart';
import '../widgets/onboarding/onboarding_background.dart';
import '../widgets/onboarding/permission_request_widget.dart';
import '../widgets/onboarding/profile_setup_widget.dart';
import 'home_screen.dart';

class SplashLandingScreen extends ConsumerStatefulWidget {
  const SplashLandingScreen({super.key});

  @override
  ConsumerState<SplashLandingScreen> createState() =>
      _SplashLandingScreenState();
}

class _SplashLandingScreenState extends ConsumerState<SplashLandingScreen> {
  bool _showOnboarding = false;
  bool _showProfileSetup = false;
  bool _showPermissions = false;
  bool _isLoading = true;
  final ValueNotifier<double> _scrollPosition = ValueNotifier(0.0);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _scrollPosition.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    // Wait for a minimum time to show the splash
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    final settings = ref.read(settingsProvider).value;
    if (settings != null) {
      if (!settings.hasSeenOnboarding) {
        setState(() {
          _showOnboarding = true;
          _isLoading = false;
        });
      } else {
        _navigateToHome();
      }
    } else {
      // Fallback if settings aren't loaded yet
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
      _showProfileSetup = true;
    });
  }

  void _onProfileSetupComplete(String name) {
    // Save name
    ref.read(settingsProvider.notifier).setUserName(name);

    setState(() {
      _showProfileSetup = false;
      _showPermissions = true;
    });
  }

  Future<void> _onPermissionsHandled() async {
    // Save that onboarding is seen
    await ref.read(settingsProvider.notifier).setOnboardingSeen(true);
    _navigateToHome();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final List<Color> pageColors = [
      colorScheme.primary,
      colorScheme.tertiary,
      colorScheme.secondary,
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Persistent animated background
          OnboardingBackground(
            scrollPosition: _scrollPosition,
            pageColors: pageColors,
          ),

          // Main Content
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              child: _buildContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildSplash();
    }
    if (_showOnboarding) {
      return OnboardingCarousel(
        onFinish: _onOnboardingComplete,
        onScroll: (pos) => _scrollPosition.value = pos,
      );
    }
    if (_showProfileSetup) {
      return ProfileSetupWidget(
        onContinue: _onProfileSetupComplete,
      );
    }
    if (_showPermissions) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: PermissionRequestWidget(
            onPermissionGranted: _onPermissionsHandled,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSplash() {
    return Center(
      key: const ValueKey('splash'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Container(
                    width: 240, // Made bigger
                    height: 240, // Made bigger
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.05),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(
                      'assets/filo_logo.svg',
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colorScheme.primary,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 80),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    strokeCap: StrokeCap.round, // Rounded edges per M3
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../widgets/onboarding/onboarding_carousel.dart';
import '../widgets/onboarding/permission_request_widget.dart';
import 'home_screen.dart';

class SplashLandingScreen extends ConsumerStatefulWidget {
  const SplashLandingScreen({super.key});

  @override
  ConsumerState<SplashLandingScreen> createState() =>
      _SplashLandingScreenState();
}

class _SplashLandingScreenState extends ConsumerState<SplashLandingScreen> {
  bool _showOnboarding = false;
  bool _showPermissions = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Wait for a minimum time to show the splash
    await Future.delayed(const Duration(seconds: 2));

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
      // Fallback if settings aren't loaded yet (shouldn't happen with watch in main)
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
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildSplash();
    }
    if (_showOnboarding) {
      return OnboardingCarousel(onFinish: _onOnboardingComplete);
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
          // Logo placeholder or Animation
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Semantic Butler',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              minHeight: 2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Initializing Intelligence...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

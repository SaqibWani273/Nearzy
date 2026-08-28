import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/secure_storage.dart';
import '../../customer/customer_home_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'Discover Local Shops',
      subtitle:
          'Explore curated storefronts, artisan crafts, and neighborhood treasures right around your community.',
      imagePath: 'assets/images/onboarding/onboarding_1.png',
      badge: 'HYPERLOCAL FIRST',
    ),
    _OnboardingItem(
      title: 'Best Deals & Fair Prices',
      subtitle:
          'Enjoy direct deals from local shopkeepers with transparent pricing and no hidden markups.',
      imagePath: 'assets/images/onboarding/onboarding_2.png',
      badge: 'EXCLUSIVE SAVINGS',
    ),
    _OnboardingItem(
      title: 'Express Delivery & Pickup',
      subtitle:
          'Get your orders delivered to your doorstep in minutes or choose convenient store pickup.',
      imagePath: 'assets/images/onboarding/onboarding_3.png',
      badge: 'FAST & CONVENIENT',
    ),
  ];

  Future<void> _completeOnboarding() async {
    await SecureStorage.storeData(key: 'has_seen_onboarding', value: 'true');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const CustomerHomePage(),
        ),
        transitionDuration: AppSpacing.durationPage,
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Action
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: AppSpacing.borderRadiusSm,
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('Nearzy', style: AppTextStyles.brand.copyWith(fontSize: 20)),
                    ],
                  ),
                  if (_currentPage < _items.length - 1)
                    TextButton(
                      onPressed: _completeOnboarding,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text('Skip', style: AppTextStyles.link),
                    )
                  else
                    const SizedBox(height: 36),
                ],
              ),
            ),

            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration with soft shadow
                        Container(
                          height: size.height * 0.38,
                          decoration: BoxDecoration(
                            borderRadius: AppSpacing.borderRadiusXl,
                            boxShadow: AppSpacing.shadowElevated,
                          ),
                          child: ClipRRect(
                            borderRadius: AppSpacing.borderRadiusXl,
                            child: Image.asset(
                              item.imagePath,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Badge Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: AppSpacing.borderRadiusFull,
                          ),
                          child: Text(
                            item.badge,
                            style: AppTextStyles.badge.copyWith(
                              color: AppColors.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading1.copyWith(fontSize: 24),
                        ),
                        const SizedBox(height: 10),

                        // Subtitle
                        Text(
                          item.subtitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Smooth Indicator Dots
                  Row(
                    children: List.generate(_items.length, (index) {
                      final isSelected = _currentPage == index;
                      return AnimatedContainer(
                        duration: AppSpacing.durationNormal,
                        curve: AppSpacing.curveDefault,
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: isSelected ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.accent : AppColors.divider,
                          borderRadius: AppSpacing.borderRadiusFull,
                        ),
                      );
                    }),
                  ),

                  // Next / Get Started Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage < _items.length - 1) {
                        _pageController.nextPage(
                          duration: AppSpacing.durationNormal,
                          curve: AppSpacing.curveDefault,
                        );
                      } else {
                        _completeOnboarding();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _currentPage == _items.length - 1 ? 'Get Started' : 'Next',
                          style: AppTextStyles.buttonText,
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                      ],
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

class _OnboardingItem {
  final String title;
  final String subtitle;
  final String imagePath;
  final String badge;

  const _OnboardingItem({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.badge,
  });
}

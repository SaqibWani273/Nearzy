import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../../utils/secure_storage.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/pressable_scale.dart';
import '../../../common/widgets/nearzy_logo.dart';
import '../../customer/customer_home_page.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingItem> _items = [
    _OnboardingItem(
      eyebrow: 'HYPERLOCAL FIRST',
      title: 'Shops on your\nstreet, online',
      subtitle:
          'Browse real storefronts a few minutes away — not a warehouse three states over.',
      imagePath: 'assets/images/onboarding/onboarding_1.png',
      icon: Icons.storefront_rounded,
    ),
    _OnboardingItem(
      eyebrow: 'FAIR PRICING',
      title: 'Straight from\nthe shopkeeper',
      subtitle:
          'You pay the shop, not a chain of middlemen. Prices you could have haggled in person.',
      imagePath: 'assets/images/onboarding/onboarding_2.png',
      icon: Icons.sell_outlined,
    ),
    _OnboardingItem(
      eyebrow: 'SAME DAY',
      title: 'Delivered, or\npick it up',
      subtitle:
          'Get it dropped at your door, or reserve it and collect on your way home.',
      imagePath: 'assets/images/onboarding/onboarding_3.png',
      icon: Icons.local_shipping_outlined,
    ),
  ];

  bool get _isLast => _currentPage == _items.length - 1;

  Future<void> _finish() async {
    await SecureStorage.storeData(key: 'has_seen_onboarding', value: 'true');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, animation, _) =>
            FadeTransition(opacity: animation, child: const CustomerHomePage()),
        transitionDuration: Motion.slow,
      ),
    );
  }

  void _next() {
    HapticFeedback.lightImpact();
    if (_isLast) {
      _finish();
      return;
    }
    _pageController.nextPage(duration: Motion.base, curve: Motion.emphasis);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        body: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.gutter,
                  12,
                  AppSpacing.gutter,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const NearzyLogo(size: 24, onInk: true),
                    AnimatedOpacity(
                      opacity: _isLast ? 0 : 1,
                      duration: Motion.duration(context, Motion.quick),
                      child: TextButton(
                        onPressed: _isLast ? null : _finish,
                        child: Text(
                          'Skip',
                          style: AppTextStyles.link
                              .copyWith(color: AppColors.sage),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => _OnboardingPage(
                  item: _items[index],
                  // Re-keying per page restarts the entrance animation each
                  // time a slide comes into view.
                  key: ValueKey(index),
                ),
              ),
            ),

            // ── Controls ────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter,
                24,
                AppSpacing.gutter,
                20 + MediaQuery.of(context).padding.bottom,
              ),
              child: Row(
                children: [
                  _PageDots(count: _items.length, index: _currentPage),
                  const Spacer(),
                  PressableScale(
                    onTap: _next,
                    scale: 0.94,
                    child: AnimatedContainer(
                      duration: Motion.duration(context, Motion.base),
                      curve: Motion.emphasis,
                      height: 56,
                      width: _isLast ? 176 : 56,
                      decoration: BoxDecoration(
                        color: AppColors.lime,
                        borderRadius: AppSpacing.borderRadiusFull,
                      ),
                      alignment: Alignment.center,
                      child: AnimatedSwitcher(
                        duration: Motion.duration(context, Motion.quick),
                        child: _isLast
                            ? Row(
                                key: const ValueKey('start'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Start shopping',
                                    style: AppTextStyles.buttonText
                                        .copyWith(color: AppColors.ink),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_rounded,
                                      size: 18, color: AppColors.ink),
                                ],
                              )
                            : const Icon(
                                Icons.arrow_forward_rounded,
                                key: ValueKey('next'),
                                color: AppColors.ink,
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

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({super.key, required this.item});

  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: AppSpacing.borderRadiusXl,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.inkSoft),
                  Image.asset(
                    item.imagePath,
                    fit: BoxFit.cover,
                    // Onboarding art is bundled, but a missing asset should
                    // still degrade to something intentional.
                    errorBuilder: (_, _, _) => Center(
                      child: Icon(item.icon, size: 72, color: AppColors.sage),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: AppColors.imageScrim),
                  ),
                ],
              ),
            ).animateEntrance(offset: 24, duration: Motion.slow),
          ),
          const SizedBox(height: 28),
          Text(
            item.eyebrow,
            style: AppTextStyles.overline.copyWith(color: AppColors.lime),
          ).animateEntrance(index: 1),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: AppTextStyles.display.copyWith(color: AppColors.paper),
          ).animateEntrance(index: 2),
          const SizedBox(height: 12),
          Text(
            item.subtitle,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.sage),
          ).animateEntrance(index: 3),
        ],
      ),
    );
  }
}

class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: Motion.duration(context, Motion.base),
            curve: Motion.easeOut,
            margin: const EdgeInsets.only(right: 6),
            width: i == index ? 26 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index ? AppColors.lime : AppColors.inkMuted,
              borderRadius: AppSpacing.borderRadiusFull,
            ),
          ),
      ],
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String imagePath;

  /// Shown if the bundled artwork fails to decode.
  final IconData icon;
}

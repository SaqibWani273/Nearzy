import 'package:flutter/material.dart';
import '../../common/widgets/animated_bottom_nav.dart';
import '../../../constants/bottom_navbar_items.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import 'admin_categories_screen.dart';
import 'admin_shops_screen.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;
  late final PageController _pageController;

  void _changeIndex(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: AppSpacing.durationNormal,
      curve: AppSpacing.curveDefault,
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('Nearzy Admin', style: AppTextStyles.brand.copyWith(fontSize: 22)),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Admin logout
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _AdminDashboard(),
          AdminCategoriesScreen(),
          AdminShopsScreen(),
        ],
      ),
      bottomNavigationBar: NearzyBottomNav(
        currentIndex: _currentIndex,
        onTap: _changeIndex,
        items: adminNavItems,
      ),
    );
  }
}

/// Simple admin dashboard with overview cards.
class _AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text('Overview', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.storefront_rounded,
                  label: 'Shops',
                  value: '—',
                  color: AppColors.primaryLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.inventory_2_rounded,
                  label: 'Products',
                  value: '—',
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  value: '—',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.pending_actions_rounded,
                  label: 'Pending',
                  value: '—',
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Quick Actions', style: AppTextStyles.heading3),
          const SizedBox(height: 12),
          _QuickActionTile(
            icon: Icons.add_circle_outline_rounded,
            title: 'Add Category',
            subtitle: 'Create a new product category',
            onTap: () {
              // Navigate to categories tab
            },
          ),
          const SizedBox(height: 8),
          _QuickActionTile(
            icon: Icons.verified_user_outlined,
            title: 'Verify Shops',
            subtitle: 'Review pending shop verifications',
            onTap: () {
              // Navigate to shops tab
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: AppSpacing.shadowSubtle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppSpacing.borderRadiusSm,
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.heading2),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppSpacing.borderRadiusMd,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusMd,
          boxShadow: AppSpacing.shadowSubtle,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: AppSpacing.borderRadiusSm,
              ),
              child: Icon(icon, size: 22, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

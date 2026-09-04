import 'package:flutter/material.dart';
import '../../common/widgets/animated_bottom_nav.dart';
import '../../../constants/bottom_navbar_items.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../../services/api_service.dart';
import '../../../services/session_manager.dart';
import '../../common/animations/entrance.dart';
import '../../common/animations/pressable_scale.dart';
import '../../common/widgets/shimmer_loading.dart';
import 'admin_categories_screen.dart';
import 'demand/admin_demand_map_screen.dart';
import 'verification/admin_verification_screen.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _currentIndex = 0;
  late final PageController _pageController;
  bool _signingOut = false;

  void _changeIndex(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: AppSpacing.durationNormal,
      curve: AppSpacing.curveDefault,
    );
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Ends the admin session. No navigation follows on purpose: `signOutActive`
  /// emits a session event, and the app shell rebuilds itself off the new
  /// active account — replacing this page with whatever the next identity
  /// (or none) should see.
  Future<void> _signOut() async {
    final sessions = SessionManager.instance;
    if (sessions.active == null) return;

    final remaining = sessions.otherAccounts;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: Text(
          remaining.isEmpty
              ? 'You will need your password to sign back in.'
              : 'You will be switched to ${remaining.first.displayName}.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign out',
                style: AppTextStyles.link.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _signingOut = true);
    await sessions.signOutActive();
    if (!mounted) return;
    setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    // Back returns to the overview rather than closing the console. Only the
    // overview itself lets the gesture through.
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _changeIndex(0);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          title: Text('Nearzy Admin',
              style: AppTextStyles.brand.copyWith(fontSize: 22)),
          actions: [
            IconButton(
              onPressed: _signingOut ? null : _signOut,
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _AdminDashboard(onGoToTab: _changeIndex),
            const AdminCategoriesScreen(),
            const AdminVerificationScreen(),
            const AdminDemandMapScreen(),
          ],
        ),
        bottomNavigationBar: NearzyBottomNav(
          currentIndex: _currentIndex,
          onTap: _changeIndex,
          items: adminNavItems,
        ),
      ),
    );
  }
}

/// The admin overview.
///
/// Every counter here used to render a literal em dash, and both quick actions
/// had empty `onTap` bodies — the screen looked finished while telling the
/// operator nothing and doing nothing.
class _AdminDashboard extends StatefulWidget {
  const _AdminDashboard({required this.onGoToTab});

  /// Moves the shell to another tab. The quick actions are shortcuts to tabs
  /// that already exist, so they change the index rather than pushing a
  /// duplicate route the bottom bar would then disagree with.
  final void Function(int) onGoToTab;

  @override
  State<_AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<_AdminDashboard> {
  late Future<Map<String, int>> _stats;

  @override
  void initState() {
    super.initState();
    _stats = ApiService.fetchAdminStats();
  }

  Future<void> _refresh() async {
    final next = ApiService.fetchAdminStats();
    setState(() => _stats = next);
    await next.catchError((_) => <String, int>{});
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.ink,
      backgroundColor: AppColors.card,
      child: FutureBuilder<Map<String, int>>(
        future: _stats,
        builder: (context, snapshot) {
          final loading = snapshot.connectionState == ConnectionState.waiting;
          final stats = snapshot.data ?? const <String, int>{};
          final pending = stats['pendingVerifications'] ?? 0;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: AppSpacing.pagePadding,
            children: [
              const SizedBox(height: AppSpacing.base),
              Text('Overview', style: AppTextStyles.heading2),
              const SizedBox(height: AppSpacing.base),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.storefront_rounded,
                      label: 'Shops',
                      value: stats['shops'],
                      loading: loading,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.inventory_2_rounded,
                      label: 'Products',
                      value: stats['products'],
                      loading: loading,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.category_rounded,
                      label: 'Categories',
                      value: stats['categories'],
                      loading: loading,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pending_actions_rounded,
                      label: 'Pending',
                      value: pending,
                      loading: loading,
                      color: AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text('Quick Actions', style: AppTextStyles.heading3),
              const SizedBox(height: AppSpacing.md),
              _QuickActionTile(
                icon: Icons.verified_user_outlined,
                title: 'Review applications',
                subtitle: pending == 0
                    ? 'Nothing waiting'
                    : '$pending awaiting a decision',
                onTap: () => widget.onGoToTab(2),
              ).animateEntrance(index: 0),
              const SizedBox(height: AppSpacing.sm),
              _QuickActionTile(
                icon: Icons.add_circle_outline_rounded,
                title: 'Add category',
                subtitle: 'Create a new product category',
                onTap: () => widget.onGoToTab(1),
              ).animateEntrance(index: 1),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Null while loading or after a failed fetch — rendered as a skeleton
  /// rather than a zero, which would be a lie the operator might act on.
  final int? value;
  final bool loading;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.loading = false,
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
          if (loading || value == null)
            ShimmerLoading.line(width: 44, height: 22)
          else
            // Counts settle rather than snapping in, per the design system's
            // number-transition rule.
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value!.toDouble()),
              duration: AppSpacing.durationSlow,
              curve: AppSpacing.curveDefault,
              builder: (context, v, _) =>
                  Text('${v.round()}', style: AppTextStyles.heading2),
            ),
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
    return PressableScale(
      onTap: onTap,
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

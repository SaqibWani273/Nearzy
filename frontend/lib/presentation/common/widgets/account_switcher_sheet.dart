import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/bottom_navbar_items.dart';
import '../../../data/models/auth_session.dart';
import '../../../services/session_manager.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_motion.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_text_styles.dart';
import '../../features/customer/authentication/view/customer_login.dart';
import '../../features/shop/shop_authentication/view/shop_auth_screen.dart';
import '../animations/entrance.dart';
import '../animations/nearzy_page_route.dart';
import '../animations/pressable_scale.dart';

/// What a switcher row was asked to do, handed back to the opener so it can
/// react (a sign-out has to leave the screen the user was on, a switch does
/// not — the shell rebuilds under it either way).
enum AccountSwitchResult { switched, addedAccount, signedOut, none }

/// Every account signed in on this device, one tap apart.
///
/// Sign-out used to be the only way to reach another account, which meant
/// retyping a password for every hop between a shopper and a shop. Sessions
/// are kept per account instead, so this sheet just repoints the app.
class AccountSwitcherSheet extends StatefulWidget {
  const AccountSwitcherSheet({super.key});

  static Future<AccountSwitchResult> show(BuildContext context) async {
    final result = await showModalBottomSheet<AccountSwitchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AccountSwitcherSheet(),
    );
    return result ?? AccountSwitchResult.none;
  }

  @override
  State<AccountSwitcherSheet> createState() => _AccountSwitcherSheetState();
}

class _AccountSwitcherSheetState extends State<AccountSwitcherSheet> {
  /// Which row is mid-switch, so it can show a spinner without freezing the
  /// whole sheet.
  String? _busyEmail;

  SessionManager get _sessions => SessionManager.instance;

  Future<void> _switchTo(StoredAccount account) async {
    if (_busyEmail != null) return;
    HapticFeedback.lightImpact();

    // An account whose session cannot be renewed needs a password, not a tap.
    if (account.needsReauth) {
      await _addAccount(role: account.role, prefillEmail: account.email);
      return;
    }

    setState(() => _busyEmail = account.email);
    final ok = await _sessions.switchTo(account.email);
    if (!mounted) return;

    if (!ok) {
      setState(() => _busyEmail = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not switch to ${account.displayName}. '
            'Please sign in again.')),
      );
      return;
    }
    Navigator.pop(context, AccountSwitchResult.switched);
  }

  Future<void> _addAccount({Roles? role, String? prefillEmail}) async {
    final chosen = role ?? await _pickRole();
    if (chosen == null || !mounted) return;

    // Captured before the pop: afterwards this context is defunct, and the
    // login screens need the navigator that sits *inside* the bloc providers
    // — pushing on the root one would put them out of reach of their blocs.
    final navigator = Navigator.of(context);
    Navigator.pop(context, AccountSwitchResult.addedAccount);
    await navigator.push(
      NearzyPageRoute(
        builder: (_) => chosen == Roles.ROLE_SHOP
            ? const ShopAuthScreen()
            : const CustomerLogin(),
      ),
    );
  }

  /// Shoppers and shops sign in through different screens, so adding an
  /// account has to ask which kind first.
  Future<Roles?> _pickRole() => showModalBottomSheet<Roles>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _SheetShell(
          title: 'Add an account',
          subtitle: 'Which kind of account is it?',
          children: [
            _ChoiceRow(
              icon: Icons.person_outline_rounded,
              title: 'Shopper',
              subtitle: 'Browse and order from local shops',
              onTap: () => Navigator.pop(context, Roles.ROLE_CUSTOMER),
            ),
            const SizedBox(height: 10),
            _ChoiceRow(
              icon: Icons.storefront_outlined,
              title: 'Shop',
              subtitle: 'Manage your inventory and orders',
              onTap: () => Navigator.pop(context, Roles.ROLE_SHOP),
            ),
          ],
        ),
      );

  Future<void> _signOut() async {
    final account = _sessions.active;
    if (account == null) return;

    final remaining = _sessions.otherAccounts;
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

    setState(() => _busyEmail = account.email);
    await _sessions.signOutActive();
    if (!mounted) return;
    Navigator.pop(context, AccountSwitchResult.signedOut);
  }

  Future<void> _forget(StoredAccount account) async {
    HapticFeedback.lightImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${account.displayName}?'),
        content: Text(
          'This signs that account out of this device. Your orders and saved '
          'items stay on the account.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove',
                style: AppTextStyles.link.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _sessions.forget(account.email);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final active = _sessions.active;
    final others = _sessions.otherAccounts;

    return _SheetShell(
      title: 'Accounts',
      subtitle: active == null
          ? 'Sign in to order, save and track'
          : 'Switch without signing out',
      children: [
        if (active != null) ...[
          _AccountRow(
            account: active,
            isActive: true,
            busy: _busyEmail == active.email,
            onTap: null,
          ).animateEntrance(),
          const SizedBox(height: 10),
        ],

        for (var i = 0; i < others.length; i++) ...[
          _AccountRow(
            account: others[i],
            isActive: false,
            busy: _busyEmail == others[i].email,
            onTap: () => _switchTo(others[i]),
            onRemove: () => _forget(others[i]),
          ).animateEntrance(index: i + 1),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 4),
        _ChoiceRow(
          icon: Icons.add_rounded,
          title: active == null ? 'Sign in' : 'Add another account',
          subtitle: 'Shopper or shop',
          onTap: _addAccount,
        ).animateEntrance(index: others.length + 1),

        if (active != null) ...[
          const SizedBox(height: 10),
          _ChoiceRow(
            icon: Icons.logout_rounded,
            title: 'Sign out of ${active.displayName}',
            subtitle: others.isEmpty
                ? 'You can sign back in anytime'
                : 'Switches to ${others.first.displayName}',
            destructive: true,
            onTap: _signOut,
          ).animateEntrance(index: others.length + 2),
        ],
      ],
    );
  }
}

/// The sheet chrome the design system asks for: 28px top corners, a drag
/// handle, a 20px gutter and room for the home indicator.
class _SheetShell extends StatelessWidget {
  const _SheetShell({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: AppSpacing.borderRadiusFull,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading2),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.bodySmall),
                    const SizedBox(height: 20),
                    ...children,
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

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.isActive,
    required this.busy,
    required this.onTap,
    this.onRemove,
  });

  final StoredAccount account;
  final bool isActive;
  final bool busy;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    // The live account is a dark block; the rest are cards. One glance is
    // enough to tell which identity the app is currently wearing.
    final onInk = isActive;

    return PressableScale(
      onTap: onTap,
      scale: onTap == null ? 1 : 0.985,
      child: AnimatedContainer(
        duration: Motion.duration(context, Motion.quick),
        curve: Motion.easeOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: onInk ? AppColors.inkGradient : null,
          color: onInk ? null : AppColors.card,
          borderRadius: AppSpacing.borderRadiusLg,
          border: onInk ? null : Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            _Avatar(account: account, onInk: onInk),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.displayName,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: onInk ? AppColors.paper : AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoleChip(account: account, onInk: onInk),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    account.needsReauth
                        ? 'Session ended — tap to sign in'
                        : account.email,
                    style: AppTextStyles.caption.copyWith(
                      color: account.needsReauth
                          ? AppColors.warning
                          : (onInk ? AppColors.sage : AppColors.textTertiary),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (busy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.sageDeep),
              )
            else if (isActive)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: AppColors.lime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 13, color: AppColors.ink),
              )
            else if (onRemove != null)
              IconButton(
                onPressed: onRemove,
                tooltip: 'Remove ${account.displayName}',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.account, required this.onInk});

  final StoredAccount account;
  final bool onInk;

  @override
  Widget build(BuildContext context) {
    final url = account.avatarUrl;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: onInk ? AppColors.inkSoft : AppColors.sageSurface,
        shape: BoxShape.circle,
        border: onInk ? Border.all(color: AppColors.lime, width: 2) : null,
        image: url == null || url.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(url), fit: BoxFit.cover),
      ),
      alignment: Alignment.center,
      child: url == null || url.isEmpty
          ? Text(
              account.initials.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: onInk ? AppColors.lime : AppColors.sageDeep,
              ),
            )
          : null,
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.account, required this.onInk});

  final StoredAccount account;
  final bool onInk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: onInk ? AppColors.inkSoft : AppColors.sageSurface,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Text(
        account.roleLabel,
        style: AppTextStyles.micro.copyWith(
          color: onInk ? AppColors.sage : AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final tint = destructive ? AppColors.error : AppColors.ink;

    return PressableScale(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      scale: 0.985,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: AppSpacing.borderRadiusLg,
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: destructive
                    ? AppColors.errorSurface
                    : AppColors.sageSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: tint),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.labelMedium.copyWith(color: tint),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_motion.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_text_styles.dart';
import '../../../common/animations/entrance.dart';
import '../../../common/animations/pressable_scale.dart';

/// Help & support: contact routes plus the questions a hyperlocal marketplace
/// actually gets asked.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const String _supportEmail = 'support@nearzy.app';
  static const String _supportPhone = '+911940000000';

  static const List<({String question, String answer})> _faqs = [
    (
      question: 'Why can I only order from one shop at a time?',
      answer:
          'Every Nearzy order is fulfilled by a single local shop, which is '
          'what keeps delivery fast and the price the shop’s own. To buy from '
          'two shops, place two orders.',
    ),
    (
      question: 'How is the distance to a shop calculated?',
      answer:
          'It is the straight-line distance from the area you are browsing to '
          'the shop’s registered location — so the real walking or driving '
          'distance will usually be a little longer.',
    ),
    (
      question: 'I changed my location but still see the same shops.',
      answer:
          'Shops are filtered by the radius chip on the Explore screen. If the '
          'radius is wide, nearby areas overlap. Try a smaller radius, or pull '
          'down to refresh.',
    ),
    (
      question: 'Can I collect an order instead of having it delivered?',
      answer:
          'Yes — call the shop from its page to arrange pickup. Their number is '
          'on every shop profile.',
    ),
    (
      question: 'How do refunds work?',
      answer:
          'Refunds are handled by the shop that fulfilled the order, through '
          'the same payment method. Contact the shop first; if you cannot '
          'reach them, write to us and we will step in.',
    ),
  ];

  Future<void> _launch(BuildContext context, Uri uri, String failure) async {
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(title: const Text('Help & support')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.gutter,
          8,
          AppSpacing.gutter,
          40,
        ),
        children: [
          Text('Talk to a person', style: AppTextStyles.sectionTitle)
              .animateEntrance(),
          const SizedBox(height: 12),
          _ContactTile(
            icon: Icons.mail_outline_rounded,
            title: 'Email us',
            subtitle: _supportEmail,
            onTap: () => _launch(
              context,
              Uri(
                scheme: 'mailto',
                path: _supportEmail,
                query: 'subject=Nearzy support request',
              ),
              'No mail app set up on this device',
            ),
          ).animateEntrance(index: 1),
          const SizedBox(height: 10),
          _ContactTile(
            icon: Icons.call_outlined,
            title: 'Call support',
            subtitle: '9am – 7pm, every day',
            onTap: () => _launch(
              context,
              Uri.parse('tel:$_supportPhone'),
              'No dialler on this device',
            ),
          ).animateEntrance(index: 2),

          const SizedBox(height: AppSpacing.sectionGap),
          Text('Common questions', style: AppTextStyles.sectionTitle)
              .animateEntrance(index: 3),
          const SizedBox(height: 12),
          for (var i = 0; i < _faqs.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _FaqTile(
              question: _faqs[i].question,
              answer: _faqs[i].answer,
            ).animateEntrance(index: 4 + i),
          ],
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
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
              decoration: const BoxDecoration(
                color: AppColors.sageSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 19, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
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

/// Expanding FAQ row. Uses [AnimatedSize] rather than an ExpansionTile so the
/// open/close respects the app's motion tokens.
class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: _open,
      child: PressableScale(
        onTap: () => setState(() => _open = !_open),
        scale: 0.99,
        child: AnimatedContainer(
          duration: Motion.duration(context, Motion.quick),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _open ? AppColors.card : AppColors.paperDim,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(
              color: _open ? AppColors.line : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(widget.question,
                        style: AppTextStyles.labelMedium),
                  ),
                  const SizedBox(width: 12),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: Motion.duration(context, Motion.quick),
                    curve: Motion.easeOut,
                    child: const Icon(Icons.expand_more_rounded,
                        size: 20, color: AppColors.textSecondary),
                  ),
                ],
              ),
              AnimatedSize(
                duration: Motion.duration(context, Motion.base),
                curve: Motion.easeOut,
                alignment: Alignment.topCenter,
                child: _open
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10, right: 32),
                        child: Text(widget.answer,
                            style: AppTextStyles.bodySmall),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

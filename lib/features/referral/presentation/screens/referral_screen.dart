import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/localization/localization_service.dart';
import '../../../../core/themming/theme_manager.dart';
import '../../../../widgets/shared/buttons.dart';
import '../controllers/referral_controller.dart';

class ReferralScreen extends StatelessWidget {
  const ReferralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeManager.currentTheme;
    final loc = LocalizationService.of(context);
    final controller = context.watch<ReferralController>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('referral_title')),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderSection(theme, loc),
            const SizedBox(height: 24),
            _buildReferralCodeCard(controller, theme, loc),
            const SizedBox(height: 32),
            _buildBenefitsSection(loc),
            const SizedBox(height: 32),
            _buildActionButtons(context, controller, loc),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme, LocalizationService loc) {
    return Column(
      children: [
        Icon(
          Icons.people_alt_outlined,
          size: 64,
          color: theme.primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          loc.translate('referral_header_title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          loc.translate('referral_header_subtitle'),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildReferralCodeCard(
    ReferralController controller,
    ThemeData theme,
    LocalizationService loc,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              loc.translate('your_referral_code'),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            SelectableText(
              controller.referralCode ?? 'Loading...',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            if (controller.referralLink != null)
              Text(
                controller.referralLink!,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection(LocalizationService loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          loc.translate('referral_benefits_title'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 8),
        ...List.generate(3, (index) => _buildBenefitItem(loc, index)),
      ],
    );
  }

  Widget _buildBenefitItem(LocalizationService loc, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(loc.translate('referral_benefit_$index')),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ReferralController controller,
    LocalizationService loc,
  ) {
    return Column(
      children: [
        AppButton.primary(
          label: loc.translate('share_referral'),
          icon: Icons.share,
          onPressed: () => _shareReferral(context, controller),
          isLoading: controller.isSharing,
        ),
        const SizedBox(height: 12),
        AppButton.secondary(
          label: loc.translate('view_referrals'),
          icon: Icons.list_alt,
          onPressed: () => controller.navigateToReferralList(),
        ),
      ],
    );
  }

  Future<void> _shareReferral(
    BuildContext context,
    ReferralController controller,
  ) async {
    if (controller.referralLink == null) return;

    try {
      await Share.share(
        LocalizationService.of(context).translate(
          'referral_share_message',
          {'link': controller.referralLink!},
        ),
        subject: LocalizationService.of(context).translate('referral_share_subject'),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: ${e.toString()}')),
      );
    }
  }
}
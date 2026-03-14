import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: AppRadius.mdAll,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Settings', style: AppTypography.headingLarge),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      Text('Preferences', style: AppTypography.headingMedium),
                      const SizedBox(height: AppSpacing.md),
                      _SettingsToggle(
                        icon: Icons.volume_up_rounded,
                        label: 'Sound Effects',
                        value: settings['soundEnabled'] ?? true,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier)
                              .updateSetting('soundEnabled', val);
                        },
                      ),
                      _SettingsToggle(
                        icon: Icons.vibration_rounded,
                        label: 'Vibration',
                        value: settings['vibrationEnabled'] ?? true,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier)
                              .updateSetting('vibrationEnabled', val);
                        },
                      ),
                      _SettingsToggle(
                        icon: Icons.notifications_rounded,
                        label: 'Notifications',
                        value: settings['notificationsEnabled'] ?? true,
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier)
                              .updateSetting('notificationsEnabled', val);
                        },
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      Text('About', style: AppTypography.headingMedium),
                      const SizedBox(height: AppSpacing.md),
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        label: 'Version',
                        trailing: Text('1.0.0',
                            style: AppTypography.bodyMedium),
                      ),
                      _SettingsTile(
                        icon: Icons.shield_outlined,
                        label: 'Privacy Policy',
                        onTap: () {},
                      ),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        label: 'Terms of Service',
                        onTap: () {},
                      ),
                      const Spacer(),
                      // Reset
                      Center(
                        child: GestureDetector(
                          onTap: () => _showResetDialog(context, ref),
                          child: Text(
                            'Reset All Progress',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.error.withOpacity(0.7),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.huge),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        title: Text('Reset Progress?', style: AppTypography.headingMedium),
        content: Text(
          'This will erase all your progress, coins, and stats. This cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              final storage = ref.read(storageServiceProvider);
              await storage.clearAll();
              await ref.read(playerDataProvider.notifier).load();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Reset',
                style:
                    AppTypography.labelLarge.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: AppRadius.lgAll,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: AppTypography.bodyLarge),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            inactiveTrackColor: AppColors.surfaceElevated,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: AppRadius.lgAll,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(label, style: AppTypography.bodyLarge),
            ),
            trailing ??
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: AppColors.textTertiary, size: 16),
          ],
        ),
      ),
    );
  }
}

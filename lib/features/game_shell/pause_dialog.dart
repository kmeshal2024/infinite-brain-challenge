import 'package:flutter/material.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/game_button.dart';

/// Shows a polished pause dialog overlay.
Future<PauseAction?> showPauseDialog(BuildContext context) {
  return showDialog<PauseAction>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (ctx) => const _PauseDialog(),
  );
}

enum PauseAction { resume, restart, quit }

class _PauseDialog extends StatelessWidget {
  const _PauseDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: AppRadius.xlAll,
          border: Border.all(
            color: AppColors.surfaceElevated,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pause icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pause_rounded,
                color: AppColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Paused', style: AppTypography.headingLarge),
            const SizedBox(height: AppSpacing.xxl),
            // Resume
            GameButton(
              label: 'Resume',
              icon: Icons.play_arrow_rounded,
              onTap: () => Navigator.pop(context, PauseAction.resume),
              width: double.infinity,
            ),
            const SizedBox(height: AppSpacing.md),
            // Restart
            GameButton(
              label: 'Restart',
              icon: Icons.refresh_rounded,
              onTap: () => Navigator.pop(context, PauseAction.restart),
              isOutlined: true,
              width: double.infinity,
            ),
            const SizedBox(height: AppSpacing.md),
            // Quit
            GameButton(
              label: 'Quit',
              icon: Icons.exit_to_app_rounded,
              onTap: () => Navigator.pop(context, PauseAction.quit),
              isOutlined: true,
              color: AppColors.textTertiary,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}

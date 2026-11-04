import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wallet_app/core/di/injection.dart';
import 'package:wallet_app/core/presentation/view_status.dart';
import 'package:wallet_app/core/router/app_routes.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/app_card.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/core/widgets/section_header.dart';
import 'package:wallet_app/core/widgets/skeleton.dart';
import 'package:wallet_app/core/widgets/state_views.dart';
import 'package:wallet_app/features/auth/presentation/session/session_cubit.dart';
import 'package:wallet_app/features/profile/domain/entities/theme_preference.dart';
import 'package:wallet_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:wallet_app/features/profile/presentation/cubit/settings_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({this.onLock, super.key});

  final VoidCallback? onLock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _ProfileHeader(),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Security'),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.pin_outlined),
                      title: const Text('Change PIN'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push(AppRoutes.changePin),
                    ),
                    const Divider(),
                    const _BiometricTile(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const SectionHeader(title: 'Appearance'),
              const _ThemeSelector(),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Lock wallet',
                icon: Icons.lock_outline_rounded,
                variant: AppButtonVariant.secondary,
                onPressed: onLock ?? () => getIt<SessionCubit>().lock(),
              ),
              const SizedBox(height: AppSpacing.md),
              const _VersionLabel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) => switch (state.status) {
        ViewStatus.failure => FailureView(
          failure: state.failure!,
          onRetry: context.read<ProfileCubit>().load,
        ),
        ViewStatus.success => AppCard(
          onTap: () => context.push(
            AppRoutes.personalDetails,
            extra: context.read<ProfileCubit>(),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: context.scheme.primaryContainer,
                foregroundColor: context.scheme.onPrimaryContainer,
                child: Text(state.profile!.fullName[0]),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.profile!.fullName,
                      style: context.text.titleMedium,
                    ),
                    Text(state.profile!.email, style: context.text.bodySmall),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        _ => const Skeleton(
          child: SkeletonBox(height: 84, radius: AppRadii.md),
        ),
      },
    );
  }
}

class _BiometricTile extends StatelessWidget {
  const _BiometricTile();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SettingsCubit, SettingsState>(
      listenWhen: (previous, current) =>
          current.error != null && previous.error != current.error,
      listener: (context, state) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) => SwitchListTile(
        secondary: const Icon(Icons.fingerprint_rounded),
        title: const Text('Biometric unlock'),
        subtitle: state.biometrics.available
            ? null
            : const Text('Not available on this device'),
        value: state.biometrics.canUse,
        onChanged: state.biometrics.available
            ? (enabled) => context.read<SettingsCubit>().setBiometrics(
                enabled: enabled,
              )
            : null,
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      buildWhen: (previous, current) => previous.theme != current.theme,
      builder: (context, state) => SegmentedButton<ThemePreference>(
        showSelectedIcon: false,
        selected: {state.theme},
        onSelectionChanged: (selection) =>
            context.read<SettingsCubit>().setTheme(selection.first),
        segments: const [
          ButtonSegment(value: ThemePreference.system, label: Text('System')),
          ButtonSegment(value: ThemePreference.light, label: Text('Light')),
          ButtonSegment(value: ThemePreference.dark, label: Text('Dark')),
        ],
      ),
    );
  }
}

class _VersionLabel extends StatefulWidget {
  const _VersionLabel();

  @override
  State<_VersionLabel> createState() => _VersionLabelState();
}

class _VersionLabelState extends State<_VersionLabel> {
  static const _tapsToUnlock = 7;
  int _taps = 0;

  void _onTap() {
    _taps++;
    if (_taps < _tapsToUnlock) return;
    _taps = 0;
    context.push(AppRoutes.developer);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Text(
          'Wallet demo 1.0.0',
          textAlign: TextAlign.center,
          style: context.text.bodySmall,
        ),
      ),
    );
  }
}

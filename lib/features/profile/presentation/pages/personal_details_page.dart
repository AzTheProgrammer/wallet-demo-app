import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/utils/formatters.dart';
import 'package:wallet_app/core/utils/validators.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/app_text_field.dart';
import 'package:wallet_app/core/widgets/responsive_center.dart';
import 'package:wallet_app/features/profile/domain/entities/profile.dart';
import 'package:wallet_app/features/profile/presentation/cubit/profile_cubit.dart';

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});

  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  late final Profile _profile = context.read<ProfileCubit>().state.profile!;
  late final _name = TextEditingController(text: _profile.fullName);
  late final _email = TextEditingController(text: _profile.email);
  late final _phone = TextEditingController(text: _profile.phone);
  String? _nameError;
  String? _emailError;
  String? _phoneError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    setState(() {
      _nameError = Validators.required(_name.text, 'your name');
      _emailError = Validators.email(_email.text);
      _phoneError = Validators.mobileNumber(_phone.text);
    });
    if (_nameError != null || _emailError != null || _phoneError != null) {
      return;
    }
    context.read<ProfileCubit>().save(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
    );
  }

  void _onStateChanged(BuildContext context, ProfileState state) {
    final messenger = ScaffoldMessenger.of(context);
    if (state.saved) {
      messenger.showSnackBar(const SnackBar(content: Text('Details saved')));
    } else if (state.saveFailure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(state.saveFailure!.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal details')),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.isSaving && !current.isSaving,
        listener: _onStateChanged,
        builder: (context, state) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: ResponsiveCenter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Full name',
                  controller: _name,
                  errorText: _nameError,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'Email',
                  controller: _email,
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  label: 'Mobile number',
                  controller: _phone,
                  errorText: _phoneError,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Member since ${formatMonthYear(_profile.memberSince)}',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Save changes',
                  isLoading: state.isSaving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

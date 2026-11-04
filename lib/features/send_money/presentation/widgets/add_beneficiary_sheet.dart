import 'package:flutter/material.dart';
import 'package:wallet_app/core/theme/tokens.dart';
import 'package:wallet_app/core/theme/wallet_colors.dart';
import 'package:wallet_app/core/utils/validators.dart';
import 'package:wallet_app/core/widgets/app_button.dart';
import 'package:wallet_app/core/widgets/app_text_field.dart';
import 'package:wallet_app/features/send_money/domain/entities/send_money_request.dart';

class AddBeneficiarySheet extends StatefulWidget {
  const AddBeneficiarySheet({super.key});

  @override
  State<AddBeneficiarySheet> createState() => _AddBeneficiarySheetState();
}

class _AddBeneficiarySheetState extends State<AddBeneficiarySheet> {
  final _name = TextEditingController();
  final _bank = TextEditingController();
  final _account = TextEditingController();
  String? _nameError;
  String? _bankError;
  String? _accountError;

  @override
  void dispose() {
    _name.dispose();
    _bank.dispose();
    _account.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() {
      _nameError = Validators.required(_name.text, 'a name');
      _bankError = Validators.required(_bank.text, 'a bank');
      _accountError = Validators.accountNumber(_account.text);
    });
    if (_nameError != null || _bankError != null || _accountError != null) {
      return;
    }
    Navigator.of(context).pop(
      NewBeneficiary(
        name: _name.text,
        bank: _bank.text,
        accountNumber: _account.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add someone new', style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: 'Full name',
              controller: _name,
              errorText: _nameError,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Bank',
              controller: _bank,
              errorText: _bankError,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: 'Account number',
              controller: _account,
              errorText: _accountError,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: 'Save and continue', onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

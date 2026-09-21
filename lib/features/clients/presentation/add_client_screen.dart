import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lynx_app/core/theme/app_colors.dart';
import 'package:lynx_app/core/theme/app_spacing.dart';
import 'package:lynx_app/core/theme/app_text_styles.dart';
import 'package:lynx_app/core/utils/app_exception.dart';
import 'package:lynx_app/features/clients/data/client_repository.dart';
import 'package:lynx_app/l10n/app_localizations.dart';
import 'package:lynx_app/shared/providers/current_user_provider.dart';
import 'package:lynx_app/shared/widgets/app_button.dart';
import 'package:lynx_app/shared/widgets/app_text_field.dart';
import 'package:lynx_app/shared/widgets/app_toast.dart';

/// Creates an account-less client (person + client role).
class AddClientScreen extends ConsumerStatefulWidget {
  const AddClientScreen({super.key});

  @override
  ConsumerState<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends ConsumerState<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_first, _last, _email, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    setState(() => _saving = true);
    try {
      await ClientRepository.createClient(
        tenantId: user.tenantId,
        createdBy: user.personId,
        firstName: _first.text,
        lastName: _last.text,
        email: _email.text,
        phone: _phone.text,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        AppToast.show(context, title: e.message, blur: false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        AppToast.show(context, title: l.somethingWentWrong, blur: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.newClient, style: AppTextStyles.heading3)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppTextField(
                label: l.firstName,
                controller: _first,
                hintText: '',
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l.nameRequired : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l.lastName,
                controller: _last,
                hintText: '',
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l.emailLabel,
                controller: _email,
                hintText: l.emailHint,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l.phone,
                controller: _phone,
                hintText: '',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton(
                label: l.save,
                isExpanded: true,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/external_links.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../authentication/presentation/auth_controller.dart';

/// Confirmation dialog for permanent account deletion.
///
/// Asks for the current password, calls the backend through [AuthController]
/// and pops with `true` once the account has been deleted and the local
/// session has been cleared. Server errors (e.g. wrong password) are shown
/// inline so the attendee can retry.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isDeleting) return;
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthController>();
    final deleted = await auth.deleteAccount(_passwordController.text);
    if (!mounted) return;

    if (deleted) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isDeleting = false;
        _errorMessage = auth.errorMessage ?? 'Unable to delete the account. Please try again.';
      });
    }
  }

  Future<void> _openWebDeletionPage() async {
    final opened = await openExternalUrl(ApiConstants.accountDeletionUrl);
    if (!opened && mounted) {
      setState(() => _errorMessage = 'Could not open the browser. Please try again later.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.crimsonError.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.delete_forever_rounded, color: AppColors.crimsonError, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Delete Account',
              style: AppTypography.headlineMedium.copyWith(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This permanently deletes your Tec-Verse account, registration and digital event pass. '
                'This action cannot be undone.\n\nEnter your current password to confirm.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _passwordController,
                label: 'Current Password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Please enter your current password.' : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.crimsonError),
                ),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: _isDeleting ? null : _openWebDeletionPage,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Request deletion on the web'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.crimsonError,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('DELETE'),
        ),
      ],
    );
  }
}

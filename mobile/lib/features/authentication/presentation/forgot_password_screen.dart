import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/futuristic_background.dart';
import '../../../core/widgets/tech_button.dart';
import 'auth_controller.dart';

/// Interactive 3-Step Password Recovery with C-DAC SMTP OTP Verification:
/// Step 1: Enter registered email address -> OTP sent via SMTP
/// Step 2: Enter 6-digit OTP code -> Validates against backend
/// Step 3: Enter new password and confirm password -> Hashes & updates in DB
/// Step 4: Success confirmation card
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep = 1; // 1: Email, 2: OTP, 3: New Password, 4: Success

  /// One-time token returned by the OTP verification step. Held in memory
  /// only (never persisted) and discarded after use or when leaving step 3.
  String? _resetToken;

  Timer? _resendTimer;
  int _resendCountdown = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown({int seconds = 45}) {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        setState(() => _resendCountdown = 0);
        timer.cancel();
      }
    });
  }

  /// Step 1: Send OTP to email
  Future<void> _handleSendOtp() async {
    if (_resendCountdown > 0) return;
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final authController = context.read<AuthController>();
    authController.clearError();

    final cooldownSeconds = await authController.requestPasswordReset(email);
    if (cooldownSeconds != null && mounted) {
      _startResendCountdown(seconds: cooldownSeconds > 0 ? cooldownSeconds : 45);
      setState(() => _currentStep = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cooldownSeconds > 0
              ? 'Please wait ${cooldownSeconds}s before requesting another OTP.'
              : 'If the account exists, an OTP was sent.'),
          backgroundColor: AppColors.emeraldSuccess,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Step 2: Verify OTP
  Future<void> _handleVerifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit OTP code.'),
          backgroundColor: AppColors.crimsonError,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final authController = context.read<AuthController>();
    authController.clearError();

    final resetToken = await authController.verifyResetOtp(
      identifier: email,
      otp: otp,
    );

    if (resetToken != null && mounted) {
      setState(() {
        _resetToken = resetToken;
        _currentStep = 3;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP code verified. Please set your new password.'),
          backgroundColor: AppColors.emeraldSuccess,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Step 3: Set New Password & Confirm Password
  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final resetToken = _resetToken;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirm password do not match.'),
          backgroundColor: AppColors.crimsonError,
        ),
      );
      return;
    }

    if (resetToken == null || resetToken.isEmpty) {
      // Token lost (e.g. user navigated back): the OTP must be verified again.
      setState(() => _currentStep = 2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify the OTP code again to continue.'),
          backgroundColor: AppColors.crimsonError,
        ),
      );
      return;
    }

    final authController = context.read<AuthController>();
    authController.clearError();

    final success = await authController.resetPassword(
      identifier: email,
      resetToken: resetToken,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    if (success && mounted) {
      setState(() {
        _resetToken = null;
        _currentStep = 4;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 14),
          alignment: Alignment.center,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.textPrimary),
              onPressed: () {
                if (_currentStep > 1 && _currentStep < 4) {
                  setState(() {
                    _currentStep--;
                    _resetToken = null;
                  });
                } else {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),
        title: Text(
          'ACCOUNT RECOVERY',
          style: AppTypography.headlineMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        centerTitle: true,
      ),
      body: FuturisticBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Consumer<AuthController>(
                  builder: (context, auth, _) {
                    if (_currentStep == 4) {
                      return _buildSuccessCard();
                    }

                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Progress Step Indicator
                          _buildStepIndicator(),

                          const SizedBox(height: 24),

                          // Error banner if any
                          if (auth.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.crimsonError.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.crimsonError.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: AppColors.crimsonError, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      auth.errorMessage!,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: const Color(0xFFDC2626),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Dynamic Step Content Card
                          Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.borderSubtle, width: 1.0),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF102A43).withValues(alpha: 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_currentStep == 1) _buildStep1Email(auth),
                                if (_currentStep == 2) _buildStep2Otp(auth),
                                if (_currentStep == 3) _buildStep3NewPassword(auth),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Visual 3-Step Breadcrumb Bar
  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _stepDot(1, 'Email', _currentStep >= 1, _currentStep == 1),
        _stepLine(_currentStep >= 2),
        _stepDot(2, 'OTP Code', _currentStep >= 2, _currentStep == 2),
        _stepLine(_currentStep >= 3),
        _stepDot(3, 'New Password', _currentStep >= 3, _currentStep == 3),
      ],
    );
  }

  Widget _stepDot(int step, String label, bool isDone, bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDone ? AppColors.primaryOrange : AppColors.surfaceElevated,
            border: Border.all(
              color: isActive ? AppColors.primaryOrange : (isDone ? AppColors.primaryOrange : AppColors.borderSubtle),
              width: 1.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primaryOrange.withValues(alpha: 0.35),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isDone && !isActive
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: isDone ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primaryOrange : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _stepLine(bool isDone) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
      color: isDone ? AppColors.primaryOrange : AppColors.borderSubtle,
    );
  }

  /// Step 1 View: Email Address Input
  Widget _buildStep1Email(AuthController auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.mark_email_read_outlined, size: 24, color: AppColors.primaryOrange),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Reset Your Password',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your registered email address. We will send a 6-digit OTP code to verify your identity.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 24),

        CustomTextField(
          controller: _emailController,
          label: 'Registered Email Address',
          hint: 'e.g. attendee@cdac.in',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Enter your registered email address';
            if (!val.contains('@') || !val.contains('.')) return 'Enter a valid email address';
            return null;
          },
        ),

        const SizedBox(height: 24),

        TechButton(
          text: _resendCountdown > 0 ? 'WAIT ${_resendCountdown}s' : 'SEND VERIFICATION OTP',
          isLoading: auth.isLoading,
          onPressed: auth.isLoading || _resendCountdown > 0 ? null : _handleSendOtp,
        ),
      ],
    );
  }

  /// Step 2 View: 6-Digit OTP Input
  Widget _buildStep2Otp(AuthController auth) {
    final email = _emailController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.verified_user_outlined, size: 24, color: AppColors.primaryOrange),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Enter Verification Code',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.4),
            children: [
              const TextSpan(text: 'A 6-digit OTP has been sent via SMTP to\n'),
              TextSpan(
                text: email,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryOrange),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        CustomTextField(
          controller: _otpController,
          label: '6-Digit Verification OTP',
          hint: 'Enter 6-digit code',
          prefixIcon: Icons.security_rounded,
          keyboardType: TextInputType.number,
          validator: (val) {
            if (val == null || val.trim().isEmpty) return 'Enter 6-digit OTP';
            if (val.trim().length != 6) return 'OTP must be exactly 6 digits';
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Resend timer and change email row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentStep = 1;
                  _resetToken = null;
                });
              },
              child: Text(
                'Change Email',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primaryOrange,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            if (_resendCountdown > 0)
              Text(
                'Resend in ${_resendCountdown}s',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              )
            else
              GestureDetector(
                onTap: auth.isLoading ? null : _handleSendOtp,
                child: Text(
                  'Resend OTP Code',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),

        TechButton(
          text: 'VERIFY CODE & CONTINUE',
          isLoading: auth.isLoading,
          onPressed: auth.isLoading ? null : _handleVerifyOtp,
        ),
      ],
    );
  }

  /// Step 3 View: New Password & Confirm Password
  Widget _buildStep3NewPassword(AuthController auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryOrange.withValues(alpha: 0.12),
              border: Border.all(color: AppColors.primaryOrange.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.lock_reset_rounded, size: 24, color: AppColors.primaryOrange),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Set New Password',
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(fontSize: 19, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Create a strong password for your Tec-Verse attendee account.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // New Password Field
        CustomTextField(
          controller: _newPasswordController,
          label: 'New Password',
          hint: 'Minimum 6 characters',
          isPassword: true,
          prefixIcon: Icons.lock_outline_rounded,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Enter new password';
            if (val.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Confirm Password Field
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm New Password',
          hint: 'Re-enter your new password',
          isPassword: true,
          prefixIcon: Icons.lock_clock_outlined,
          validator: (val) {
            if (val == null || val.isEmpty) return 'Confirm your new password';
            if (val != _newPasswordController.text) return 'Passwords do not match';
            return null;
          },
        ),

        const SizedBox(height: 24),

        TechButton(
          text: 'SUBMIT & UPDATE PASSWORD',
          isLoading: auth.isLoading,
          onPressed: auth.isLoading ? null : _handleResetPassword,
        ),
      ],
    );
  }

  /// Step 4 View: Success Confirmation Card
  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.emeraldSuccess.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF102A43).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emeraldSuccess.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 54, color: AppColors.emeraldSuccess),
          ),
          const SizedBox(height: 18),
          Text(
            'Password Changed!',
            style: AppTypography.headlineMedium.copyWith(fontSize: 21, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Your new password has been securely updated and hashed in the database. You can now login with your updated credentials.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.45),
          ),
          const SizedBox(height: 28),
          TechButton(
            text: 'RETURN TO LOGIN',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

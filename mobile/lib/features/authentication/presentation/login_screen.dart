import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/futuristic_background.dart';
import '../../../core/widgets/institution_logos_bar.dart';
import '../../../core/widgets/tech_button.dart';
import '../presentation/auth_controller.dart';
import 'forgot_password_screen.dart';

/// Premium government-grade 2026 Authentication Screen.
/// Responsive for Mobile (fluid safe-area) and Windows/Desktop (centered elevated panel).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();

  final _identifierFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (_isSubmitting) return;
    final authController = context.read<AuthController>();
    if (authController.isLoading) {
      return;
    }

    // Clear keyboard focus
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    debugPrint('[LOGIN] Button clicked');

    try {
      final success = await authController.login(
        identifier: _identifierController.text.trim(),
        password: _passwordController.text,
      );

      if (success && mounted) {
        // Navigate to Home replacing login so user cannot pop back
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  Future<void> _launchRegistrationUrl() async {
    final uri = Uri.parse(ApiConstants.websiteRegistrationUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open registration portal: ${ApiConstants.websiteRegistrationUrl}'),
            backgroundColor: AppColors.crimsonError,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isWideScreen = size.width > 700;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FuturisticBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWideScreen ? 32 : 20,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWideScreen ? 460 : double.infinity,
                ),
                child: isWideScreen
                    ? Container(
                        padding: const EdgeInsets.all(36),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.borderSubtle.withValues(alpha: 0.9),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF102A43).withValues(alpha: 0.10),
                              blurRadius: 32,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: _buildLoginFormContent(),
                      )
                    : _buildLoginFormContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginFormContent() {
    return Consumer<AuthController>(
      builder: (context, auth, _) {
        return Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo badge & Header
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cyanAccent.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/tecverselogo.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Title & Slogan
              Text(
                'TEC-VERSE 2026',
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium.copyWith(
                  letterSpacing: 1.0,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bridging Research. Building the Future.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.cyanAccent,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),

              // Error banner if any
              if (auth.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 18,
                        color: AppColors.crimsonError,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          auth.errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Email Address Field
              CustomTextField(
                controller: _identifierController,
                focusNode: _identifierFocusNode,
                label: 'Email Address',
                hint: 'enter your gmail',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                semanticLabel: 'Email address input',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your registered email address';
                  }
                  final trimmed = value.trim();
                  final bool isEmail = trimmed.contains('@') && trimmed.contains('.');
                  final bool isMobile = RegExp(r'^[0-9]{10}$').hasMatch(trimmed);
                  if (!isEmail && !isMobile) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_passwordFocusNode);
                },
              ),

              const SizedBox(height: 18),

              // Password Field with Toggle
              CustomTextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                label: 'Password',
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline_rounded,
                isPassword: true,
                textInputAction: TextInputAction.done,
                semanticLabel: 'Password input field',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 4) {
                    return 'Password must be at least 4 characters';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submitLogin(),
              ),

              // Forgot Password link
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: auth.isLoading ? null : 
                  _navigateToForgotPassword,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  ),
                  child: Text(
                    'Forgot Password?',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.cyanAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Primary LOGIN Button
              TechButton(
                text: 'LOGIN',
                loadingText: 'AUTHENTICATING...',
                isLoading: auth.isLoading || _isSubmitting,
                onPressed: (auth.isLoading || _isSubmitting) ? null : _submitLogin,
              ),

              const SizedBox(height: 22),

              // Registration on Website Link
              Center(
                child: Column(
                  children: [
                    Text(
                      "Don't have an account?",
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: _launchRegistrationUrl,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Register on TEC-VERSE Website',
                                style: AppTypography.labelLarge.copyWith(
                                  color: AppColors.cyanAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: AppColors.cyanAccent,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 14,
                                color: AppColors.cyanAccent,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Approved Institutional Logos (MeitY, C-DAC, SAMEER, C-MET)
              const InstitutionLogosBar(compact: true),
            ],
          ),
        );
      },
    );
  }
}

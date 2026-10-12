import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/storage/session_manager.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../authentication/presentation/auth_controller.dart';
import 'digital_pass_card.dart';
import 'digital_pass_controller.dart';

/// Dedicated Digital Event Pass screen with live refresh capability.
class DigitalPassScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const DigitalPassScreen({super.key, this.onBackPressed});

  @override
  State<DigitalPassScreen> createState() => _DigitalPassScreenState();
}

class _DigitalPassScreenState extends State<DigitalPassScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPassIfNeeded();
    });
  }

  void _loadPassIfNeeded() {
    final authController = context.read<AuthController>();
    final sessionManager = context.read<SessionManager>();
    final passController = context.read<DigitalPassController>();

    if (authController.currentUser != null && sessionManager.accessToken != null) {
      passController.loadPass(
        token: sessionManager.accessToken!,
        user: authController.currentUser!,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 56,
        leading: Center(
          child: Container(
            width: 38,
            height: 38,
            margin: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.chevron_left_rounded, size: 26, color: Color(0xFF102A43)),
              tooltip: 'Back',
              onPressed: () {
                if (widget.onBackPressed != null) {
                  widget.onBackPressed!();
                } else if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),
        title: const Text(
          'DIGITAL EVENT PASS',
          style: TextStyle(
            letterSpacing: 0.6,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF102A43),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer<DigitalPassController>(
          builder: (context, controller, _) {
            if (controller.isLoading && controller.pass == null) {
              return _buildLoadingSkeleton();
            }

            if (controller.errorMessage != null && controller.pass == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.crimsonError),
                      const SizedBox(height: 16),
                      Text(controller.errorMessage!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      if (controller.requiresSignIn || controller.canRetry)
                        ElevatedButton.icon(
                          onPressed: controller.requiresSignIn
                              ? _returnToSignIn
                              : _loadPassIfNeeded,
                          icon: Icon(controller.requiresSignIn
                              ? Icons.login_rounded
                              : Icons.refresh_rounded),
                          label: Text(controller.requiresSignIn ? 'Sign In' : 'Retry'),
                        ),
                    ],
                  ),
                ),
              );
            }

            final pass = controller.pass;
            if (pass == null) {
              return const Center(child: Text('No active digital pass found.'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Center(
                child: Column(
                  children: [
                    DigitalPassCard(pass: pass),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _returnToSignIn() async {
    final authController = context.read<AuthController>();
    final passController = context.read<DigitalPassController>();
    await authController.handleSessionExpired();
    passController.clearPass();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Widget _buildLoadingSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 340,
            ),
            child: AspectRatio(
              aspectRatio: 340 / 460,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF0E5DE)),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading official digital event credential...',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


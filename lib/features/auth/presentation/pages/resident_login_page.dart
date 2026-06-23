import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_role.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/gradient_background.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../../../l10n/app_strings.dart';

class ResidentLoginPage extends ConsumerStatefulWidget {
  const ResidentLoginPage({super.key});

  @override
  ConsumerState<ResidentLoginPage> createState() => _ResidentLoginPageState();
}

class _ResidentLoginPageState extends ConsumerState<ResidentLoginPage> {
  final _emailController = TextEditingController(text: 'resident@phh.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _isLoading = false;
  bool _isSignUp = false;

  void _handleAuth() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);

      if (_isSignUp) {
        await authService.signUpWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
          'Demo Resident',
          'resident',
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up successful! Please log in.')),
        );
        setState(() => _isSignUp = false);
      } else {
        await authService.signInWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );

        // Load the role so we can route admin/guard/resident to the right area.
        await refreshUserRole();
        if (!mounted) return;
        context.go(homeRouteForRole(appUserRoleNotifier.value));
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unexpected error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Gradient brand logo badge
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand.withOpacity(0.35),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.holiday_village_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      ref.tr('login.title'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(child: LanguageSwitcher()),
                    if (_isSignUp) ...[
                      const SizedBox(height: 8),
                      Text(
                        ref.tr('login.createAccount'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    // White card holding the form
                    PremiumCard(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          GlassTextField(
                            hintText: ref.tr('login.email'),
                            prefixIcon: Icons.email_outlined,
                            controller: _emailController,
                          ),
                          const SizedBox(height: 16),
                          GlassTextField(
                            hintText: ref.tr('login.password'),
                            prefixIcon: Icons.lock_outline,
                            isPassword: true,
                            controller: _passwordController,
                          ),
                          const SizedBox(height: 24),
                          // Bold gradient primary button
                          _GradientButton(
                            label: _isSignUp
                                ? ref.tr('login.signup')
                                : ref.tr('login.login'),
                            isLoading: _isLoading,
                            onPressed: _isLoading ? null : _handleAuth,
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () =>
                                setState(() => _isSignUp = !_isSignUp),
                            child: Text(
                              _isSignUp
                                  ? ref.tr('login.haveAccount')
                                  : ref.tr('login.needAccount'),
                              style: const TextStyle(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bold, brand-gradient primary action button with a built-in loading state.
class _GradientButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GradientButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.7 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withOpacity(0.32),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 56,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

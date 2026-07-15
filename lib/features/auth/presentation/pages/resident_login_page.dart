import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/brand.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_role.dart';
import '../../../../theme/app_colors.dart';
import '../../../../core/widgets/glass_text_field.dart';
import '../../../../core/widgets/premium_card.dart';
import '../../../../core/widgets/language_switcher.dart';
import '../../../../l10n/app_strings.dart';

class ResidentLoginPage extends ConsumerStatefulWidget {
  const ResidentLoginPage({super.key});

  @override
  ConsumerState<ResidentLoginPage> createState() => _ResidentLoginPageState();
}

class _ResidentLoginPageState extends ConsumerState<ResidentLoginPage> {
  // Empty in production. Local test builds can inject credentials with
  // --dart-define=TEST_EMAIL=... --dart-define=TEST_PASSWORD=...
  // (optionally --dart-define=TEST_AUTOLOGIN=true to submit automatically).
  final _emailController = TextEditingController(
    text: const String.fromEnvironment('TEST_EMAIL'),
  );
  final _passwordController = TextEditingController(
    text: const String.fromEnvironment('TEST_PASSWORD'),
  );

  @override
  void initState() {
    super.initState();
    const autologin = bool.fromEnvironment('TEST_AUTOLOGIN');
    if (autologin && _emailController.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleAuth());
    }
  }
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;

  void _showMessage(String message, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : const Color(0xFF10B981),
      ),
    );
  }

  /// Translate raw GoTrue errors into something the user can act on.
  String _friendlyAuthError(AuthException e) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) {
      return 'Email or password is incorrect. Please check your email is '
          'typed correctly (for example: name@gmail.com).';
    }
    if (m.contains('email not confirmed')) {
      return 'This email has not been confirmed yet. Please check your inbox.';
    }
    if (m.contains('already registered')) {
      return 'This email is already registered — please log in instead.';
    }
    return e.message;
  }

  void _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in email and password.');
      return;
    }
    if (_isSignUp) {
      if (_nameController.text.trim().length < 2) {
        _showMessage('Please enter your full name.');
        return;
      }
      if (password.length < 6) {
        _showMessage('Password must be at least 6 characters.');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);

      if (_isSignUp) {
        final res = await authService.signUpWithEmailPassword(
          email,
          password,
          _nameController.text.trim(),
        );
        if (!mounted) return;
        if (res.session != null) {
          // Email confirmation is disabled → signed in immediately.
          await refreshUserRole();
          if (!mounted) return;
          context.go(homeRouteForRole(appUserRoleNotifier.value));
        } else {
          _showMessage(
            'Account created! Please confirm your email, then log in.',
            error: false,
          );
          setState(() => _isSignUp = false);
        }
      } else {
        await authService.signInWithEmailPassword(email, password);

        // Load the role so we can route admin/guard/resident to the right area.
        await refreshUserRole();
        if (!mounted) return;
        context.go(homeRouteForRole(appUserRoleNotifier.value));
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyAuthError(e));
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unexpected error occurred');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleSignUp() {
    setState(() {
      _isSignUp = !_isSignUp;
      if (_isSignUp) {
        // Clear the prefilled demo credentials — registering with them would
        // hit "already registered".
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // PHH keeps its original plain gradient; HCA gets the housing-area
          // wallpaper in the logo palette.
          if (Brand.isPhh)
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.canvasGradient),
            )
          else ...[
            Image.asset('assets/branding/login_bg.jpg', fit: BoxFit.cover),
            // Soft veil so the form stays readable over the illustration.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.30),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ],
          SafeArea(
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
                      padding: EdgeInsets.all(Brand.isPhh ? 0 : 9),
                      decoration: BoxDecoration(
                        color: Brand.isPhh ? null : Colors.white,
                        gradient: Brand.isPhh ? AppColors.brandGradient : null,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.brand.withOpacity(0.35),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Brand.isPhh
                          ? const Icon(
                              Icons.holiday_village_rounded,
                              color: Colors.white,
                              size: 44,
                            )
                          : Image.asset(Brand.logoAsset, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      Brand.appName,
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
                          if (_isSignUp) ...[
                            GlassTextField(
                              hintText: 'Full Name',
                              prefixIcon: Icons.person_outline,
                              controller: _nameController,
                            ),
                            const SizedBox(height: 16),
                          ],
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
                            onPressed: _toggleSignUp,
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
        ],
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

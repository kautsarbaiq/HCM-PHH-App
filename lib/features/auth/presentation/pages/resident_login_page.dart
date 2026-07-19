import 'dart:async';

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
  // HCA multi-community signup fields.
  final _communityCodeController = TextEditingController();
  String _residentType = 'owner';
  // Live community-code lookup: as the user types the code, the community
  // name appears underneath automatically ("001 – Sunway Apartments").
  Timer? _codeDebounce;
  String? _communityName;
  bool _checkingCode = false;
  bool _isLoading = false;
  bool _isSignUp = false;

  void _onCommunityCodeChanged(String value) {
    _codeDebounce?.cancel();
    final code = value.trim();
    if (!RegExp(r'^\d{3,6}$').hasMatch(code)) {
      setState(() {
        _communityName = null;
        _checkingCode = false;
      });
      return;
    }
    setState(() => _checkingCode = true);
    _codeDebounce = Timer(const Duration(milliseconds: 450), () async {
      try {
        final name = await ref
            .read(authServiceProvider)
            .checkCommunityCode(code);
        if (!mounted || _communityCodeController.text.trim() != code) return;
        setState(() {
          _communityName = name;
          _checkingCode = false;
        });
      } catch (_) {
        if (mounted) setState(() => _checkingCode = false);
      }
    });
  }

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
      // Accounts are activated by the management office, so point the
      // resident there instead of at their email inbox.
      return 'Please contact the management office for approval of your '
          'account.';
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
      if (!RegExp(
        r'^\d{3,6}$',
      ).hasMatch(_communityCodeController.text.trim())) {
        _showMessage('Please enter your residence community code (3-6 digit).');
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);

      if (_isSignUp) {
        // Validate the community code BEFORE creating the account.
        final communityName = await authService.checkCommunityCode(
          _communityCodeController.text.trim(),
        );
        if (communityName == null) {
          if (!mounted) return;
          _showMessage(
            'Community code not found. Please check with your management.',
          );
          setState(() => _isLoading = false);
          return;
        }
        final res = await authService.signUpWithEmailPassword(
          email,
          password,
          _nameController.text.trim(),
          communityCode: _communityCodeController.text.trim(),
          residentType: _residentType,
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
        _communityCodeController.clear();
        _residentType = 'owner';
      }
    });
  }

  @override
  void dispose() {
    _codeDebounce?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _communityCodeController.dispose();
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
            // bottomCenter: on wide screens only the empty sky gets cropped —
            // the buildings/waves at the bottom stay visible (phones are
            // unaffected: portrait crops left/right, not vertically).
            Image.asset(
              'assets/branding/login_bg.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
            ),
            // Soft veil so the form stays readable over the illustration. On
            // wide screens the portrait wallpaper crops to its busy building
            // area, so the veil is stronger there.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: MediaQuery.of(context).size.width >= 700
                      ? [
                          Colors.white.withOpacity(0.60),
                          Colors.white.withOpacity(0.18),
                        ]
                      : [
                          Colors.white.withOpacity(0.30),
                          Colors.white.withOpacity(0.05),
                        ],
                ),
              ),
            ),
          ],
          SafeArea(
            // HCA (boss feedback): content pinned to the top so the wallpaper
            // artwork at the bottom stays fully visible; PHH stays centered.
            child: Align(
              alignment: Brand.isPhh ? Alignment.center : Alignment.topCenter,
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
                    // PHH keeps the white card around the form; on HCA the
                    // fields sit straight on the wallpaper (boss feedback) so
                    // the artwork isn't hidden behind a big white surface.
                    _FormSurface(
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
                            ...[
                              GlassTextField(
                                hintText: 'Residence Community Code',
                                prefixIcon: Icons.apartment_outlined,
                                controller: _communityCodeController,
                                keyboardType: TextInputType.number,
                                onChanged: _onCommunityCodeChanged,
                              ),
                              // Live result: "001 – Sunway Apartments".
                              if (_checkingCode ||
                                  _communityCodeController.text
                                      .trim()
                                      .isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    left: 6,
                                  ),
                                  child: Row(
                                    children: [
                                      if (_checkingCode)
                                        const SizedBox(
                                          width: 13,
                                          height: 13,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      else
                                        Icon(
                                          _communityName != null
                                              ? Icons.check_circle
                                              : Icons.error_outline,
                                          size: 15,
                                          color: _communityName != null
                                              ? AppColors.success
                                              : AppColors.error,
                                        ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _checkingCode
                                              ? 'Checking code…'
                                              : _communityName ??
                                                    'Community code not found',
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w700,
                                            color: _checkingCode
                                                ? AppColors.textSecondary
                                                : _communityName != null
                                                ? AppColors.success
                                                : AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 16),
                            ],
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
                          // Owner / Tenant selector (point 17) — last thing
                          // before the Sign Up button, per boss feedback.
                          if (_isSignUp) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                for (final t in const [
                                  ('owner', 'Owner'),
                                  ('tenant', 'Tenant'),
                                ]) ...[
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _residentType = t.$1,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: _residentType == t.$1
                                              ? AppColors.brandGradient
                                              : null,
                                          color: _residentType == t.$1
                                              ? null
                                              : AppColors.surfaceTint,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            t.$2,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: _residentType == t.$1
                                                  ? Colors.white
                                                  : AppColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (t.$1 == 'owner')
                                    const SizedBox(width: 10),
                                ],
                              ],
                            ),
                          ],
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

/// PHH: the classic white card behind the login form. HCA: no card at all —
/// the glass fields sit directly on the wallpaper.
class _FormSurface extends StatelessWidget {
  final Widget child;
  const _FormSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    if (Brand.isPhh) {
      return PremiumCard(padding: const EdgeInsets.all(22), child: child);
    }
    return child;
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

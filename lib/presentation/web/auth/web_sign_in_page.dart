import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'web_auth_repository.dart';
import 'web_auth_session.dart';

class WebSignInPage extends StatefulWidget {
  final WebAuthRepository repository;
  final ValueChanged<WebAppUser> onSignedIn;
  final String? initialError;

  const WebSignInPage({
    super.key,
    required this.repository,
    required this.onSignedIn,
    this.initialError,
  });

  @override
  State<WebSignInPage> createState() => _WebSignInPageState();
}

class _WebSignInPageState extends State<WebSignInPage>
    with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  late final AnimationController entranceController;
  late final Animation<double> fadeAnimation;
  bool obscurePassword = true;
  bool rememberMe = true;
  bool submitting = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    errorMessage = widget.initialError;
    entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..forward();
    fadeAnimation = CurvedAnimation(
      parent: entranceController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    entranceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (submitting || formKey.currentState?.validate() != true) return;
    setState(() {
      submitting = true;
      errorMessage = null;
    });
    try {
      final user = await widget.repository.signIn(
        email: emailController.text,
        password: passwordController.text,
      );
      if (!mounted) return;
      widget.onSignedIn(user);
    } on WebAuthException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => errorMessage = 'Enter your email address first.');
      return;
    }
    try {
      await widget.repository.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent.')),
      );
    } on WebAuthException catch (error) {
      if (mounted) setState(() => errorMessage = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.width < 900;
    return Scaffold(
      backgroundColor: const Color(0xFF061B36),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _AuthBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: FadeTransition(
                  opacity: fadeAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, .045),
                      end: Offset.zero,
                    ).animate(fadeAnimation),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Container(
                        height: compact ? 940 : 650,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x6600122E),
                              blurRadius: 60,
                              offset: Offset(0, 28),
                            ),
                            BoxShadow(
                              color: Color(0x3300BDEB),
                              blurRadius: 45,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: compact
                            ? Column(
                                children: [
                                  const SizedBox(
                                    height: 230,
                                    child: _WelcomePanel(),
                                  ),
                                  _formPanel(),
                                ],
                              )
                            : Row(
                                children: [
                                  const Expanded(
                                    flex: 10,
                                    child: _WelcomePanel(),
                                  ),
                                  Expanded(flex: 11, child: _formPanel()),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formPanel() => Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 50),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 410),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.blueSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Asset Managment',
                      style: TextStyle(
                        color: AppColors.headerText,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'Sign in to manage assets, inventory and operations securely.',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _AuthTextField(
                controller: emailController,
                label: 'Email address',
                hint: 'name@alainpharmacy.ae',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty) return 'Email address is required';
                  if (!email.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              _AuthTextField(
                controller: passwordController,
                label: 'Password',
                hint: 'Enter your password',
                icon: Icons.lock_outline_rounded,
                obscureText: obscurePassword,
                suffix: IconButton(
                  tooltip: obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () =>
                      setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.subText,
                  ),
                ),
                validator: (value) =>
                    (value ?? '').isEmpty ? 'Password is required' : null,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: Checkbox(
                      value: rememberMe,
                      activeColor: AppColors.primaryColor,
                      onChanged: (value) =>
                          setState(() => rememberMe = value ?? true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Keep me signed in',
                    style: TextStyle(fontSize: 12.5, color: AppColors.text),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: submitting ? null : _resetPassword,
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFFFCCD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Color(0xFFE5485D),
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFF9D2637),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _SignInButton(loading: submitting, onPressed: _submit),
              const SizedBox(height: 20),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'SECURE ADMIN ACCESS',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 18),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF2CB67D),
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Protected by Supabase authentication',
                    style: TextStyle(color: AppColors.subText, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    validator: validator,
    onFieldSubmitted: onSubmitted,
    autofillHints: obscureText
        ? const [AutofillHints.password]
        : const [AutofillHints.email],
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
      fillColor: const Color(0xFFF5F8FC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
  );
}

class _SignInButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onPressed;
  const _SignInButton({required this.loading, required this.onPressed});

  @override
  State<_SignInButton> createState() => _SignInButtonState();
}

class _SignInButtonState extends State<_SignInButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: widget.loading
        ? SystemMouseCursors.basic
        : SystemMouseCursors.click,
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: AnimatedScale(
      scale: hovered && !widget.loading ? 1.012 : 1,
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        height: 54,
        child: ElevatedButton(
          onPressed: widget.loading ? null : widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryColor,
            disabledBackgroundColor: AppColors.primaryColor.withValues(
              alpha: .65,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: hovered ? 8 : 0,
            shadowColor: const Color(0x661769FF),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: widget.loading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    key: ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign in securely',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    ),
  );
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF071B39), Color(0xFF075AA9), Color(0xFF00BDEB)],
          ),
        ),
      ),
      const Positioned(
        left: -95,
        bottom: -100,
        child: _GlassOrb(size: 290, opacity: .12),
      ),
      const Positioned(
        right: -65,
        top: -75,
        child: _GlassOrb(size: 250, opacity: .10),
      ),
      const Positioned(
        right: -25,
        bottom: 55,
        child: _GlassOrb(size: 215, opacity: .16),
      ),
      Padding(
        padding: const EdgeInsets.all(58),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 92,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4400163D),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
            const SizedBox(height: 38),
            const Text(
              'WELCOME',
              style: TextStyle(
                color: Colors.white,
                fontSize: 40,
                height: 1,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'SMART ASSET CONTROL',
              style: TextStyle(
                color: Color(0xFFD8F7FF),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.4,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 58,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'One secure workspace for every asset, movement, maintenance record and operational decision.',
              style: TextStyle(
                color: Color(0xFFD8EDFF),
                fontSize: 15,
                height: 1.65,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _GlassOrb extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlassOrb({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withValues(alpha: opacity),
      border: Border.all(color: Colors.white.withValues(alpha: opacity + .04)),
    ),
  );
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B79D0), Color(0xFF07589D), Color(0xFF052F5D)],
            ),
          ),
        ),
      ),
      Positioned(
        left: -170,
        top: -210,
        child: Container(
          width: 520,
          height: 520,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x3300D9FF), Color(0x0000D9FF)],
            ),
          ),
        ),
      ),
      Positioned(
        right: -130,
        bottom: -190,
        child: Container(
          width: 500,
          height: 500,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [Color(0x332C8DFF), Color(0x002C8DFF)],
            ),
          ),
        ),
      ),
    ],
  );
}

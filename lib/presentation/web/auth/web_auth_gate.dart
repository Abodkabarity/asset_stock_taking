import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../pages/web_asset_dashboard_page.dart';
import 'web_auth_repository.dart';
import 'web_auth_session.dart';
import 'web_sign_in_page.dart';

class WebAuthGate extends StatefulWidget {
  const WebAuthGate({super.key});

  @override
  State<WebAuthGate> createState() => _WebAuthGateState();
}

class _WebAuthGateState extends State<WebAuthGate> {
  final repository = WebAuthRepository();
  StreamSubscription<AuthState>? subscription;
  WebAppUser? profile;
  String? startupError;
  bool resolving = true;

  @override
  void initState() {
    super.initState();
    subscription = repository.authChanges.listen((state) {
      if (!mounted) return;
      if (state.session == null) {
        WebAuthSession.clear();
        setState(() {
          profile = null;
          startupError = null;
          resolving = false;
        });
      }
    });
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    if (repository.currentSession == null) {
      if (mounted) setState(() => resolving = false);
      return;
    }
    try {
      final restored = await repository.loadCurrentProfile();
      if (!mounted) return;
      setState(() {
        profile = restored;
        resolving = false;
      });
    } on WebAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        startupError = error.message;
        resolving = false;
      });
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (resolving) return const _WebAuthSplash();
    if (profile != null) return const WebAssetDashboardPage();
    return WebSignInPage(
      repository: repository,
      initialError: startupError,
      onSignedIn: (user) => setState(() {
        profile = user;
        startupError = null;
      }),
    );
  }
}

class _WebAuthSplash extends StatelessWidget {
  const _WebAuthSplash();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF061B36),
    body: Center(
      child: Container(
        width: 190,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Color(0x4400BDEB), blurRadius: 36),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primaryColor,
              ),
            ),
            SizedBox(width: 13),
            Text(
              'Securing session',
              style: TextStyle(
                color: AppColors.headerText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

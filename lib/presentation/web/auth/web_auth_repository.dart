import 'package:supabase_flutter/supabase_flutter.dart';

import 'web_auth_session.dart';

class WebAuthException implements Exception {
  final String message;
  const WebAuthException(this.message);

  @override
  String toString() => message;
}

class WebAuthRepository {
  final SupabaseClient supabase;

  WebAuthRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Session? get currentSession => supabase.auth.currentSession;

  Stream<AuthState> get authChanges => supabase.auth.onAuthStateChange;

  Future<WebAppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const WebAuthException('Unable to start a secure session.');
      }
      return loadProfile(user);
    } on AuthException catch (error) {
      throw WebAuthException(_friendlyAuthMessage(error.message));
    }
  }

  Future<WebAppUser> loadCurrentProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw const WebAuthException('Your session has expired. Sign in again.');
    }
    return loadProfile(user);
  }

  Future<WebAppUser> loadProfile(User authUser) async {
    try {
      final response = await supabase
          .from('app_users')
          .select('user_id,email,user_name,role,is_active')
          .eq('user_id', authUser.id)
          .maybeSingle();

      if (response == null) {
        await signOut();
        throw const WebAuthException(
          'This account is not registered in Al Ain Pharmacy Asset.',
        );
      }

      final profile = WebAppUser(
        id: response['user_id']?.toString() ?? authUser.id,
        email: response['email']?.toString().trim().isNotEmpty == true
            ? response['email'].toString()
            : (authUser.email ?? ''),
        userName: response['user_name']?.toString().trim().isNotEmpty == true
            ? response['user_name'].toString().trim()
            : (authUser.email?.split('@').first ?? 'Administrator'),
        role: response['role']?.toString().trim().toLowerCase() ?? '',
        isActive: response['is_active'] == true,
      );

      if (!profile.isActive) {
        await signOut();
        throw const WebAuthException(
          'This account is inactive. Contact your administrator.',
        );
      }
      if (profile.role != 'admin') {
        await signOut();
        throw const WebAuthException(
          'This account does not have permission to access the web app.',
        );
      }
      WebAuthSession.setUser(profile);
      return profile;
    } on PostgrestException catch (error) {
      throw WebAuthException(
        error.code == '42P01'
            ? 'Authentication setup is incomplete. Apply the app_users migration.'
            : 'Unable to load your user profile. Please try again.',
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email.trim().toLowerCase());
    } on AuthException catch (error) {
      throw WebAuthException(_friendlyAuthMessage(error.message));
    }
  }

  Future<void> signOut() async {
    WebAuthSession.clear();
    await supabase.auth.signOut();
  }

  String _friendlyAuthMessage(String message) {
    final normalized = message.toLowerCase();
    if (normalized.contains('invalid login credentials')) {
      return 'Incorrect email or password.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'Confirm your email address before signing in.';
    }
    if (normalized.contains('rate limit')) {
      return 'Too many attempts. Wait a moment and try again.';
    }
    return 'Sign in failed. Check your details and try again.';
  }
}

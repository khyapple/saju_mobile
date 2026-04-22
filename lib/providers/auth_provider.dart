import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = true;

  User? get user => _user;
  bool get loading => _loading;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _user = Supabase.instance.client.auth.currentUser;
    _loading = false;
    notifyListeners();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      notifyListeners();
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signUpWithEmail(String name, String email, String password) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': name,
        'display_name': name,
        'onboarding_step': 'welcome',
      },
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future<void> updatePassword(String newPassword) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> updateEmail(String newEmail) async {
    await Supabase.instance.client.auth.updateUser(
      UserAttributes(email: newEmail),
    );
  }

  Future<void> verifyPassword(String password) async {
    final em = email;
    if (em.isEmpty) throw Exception('no email');
    await Supabase.instance.client.auth.signInWithPassword(
      email: em,
      password: password,
    );
  }

  String get displayName {
    if (_user == null) return '';
    return _user!.userMetadata?['full_name'] as String? ??
        _user!.email?.split('@').first ??
        '사용자';
  }

  String get email => _user?.email ?? '';
}

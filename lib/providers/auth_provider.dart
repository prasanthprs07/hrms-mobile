import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  String _userId = '';

  String get userId => _userId;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserProfile? get userProfile => _userProfile;

  AuthProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString('user_id') ?? '';
    if (savedUserId.isNotEmpty) {
      _userId = savedUserId;
      _isLoggedIn = true;
      final name = prefs.getString('user_name') ?? 'User';
      final email = prefs.getString('user_email') ?? '';
      _userProfile = UserProfile(
        uid: savedUserId,
        displayName: name,
        email: email,
      );
      notifyListeners();
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('password_$email');

      if (savedPassword == null) {
        _error = 'No account found with this email.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      if (savedPassword != password) {
        _error = 'Incorrect password.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _userId = email;
      _isLoggedIn = true;
      final name = prefs.getString('user_name_$email') ?? email.split('@').first;

      _userProfile = UserProfile(
        uid: email,
        displayName: name,
        email: email,
      );

      await prefs.setString('user_id', email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Something went wrong.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString('password_$email');

      if (existing != null) {
        _error = 'An account already exists with this email.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      await prefs.setString('password_$email', password);
      await prefs.setString('user_name_$email', name);

      _userId = email;
      _isLoggedIn = true;
      _userProfile = UserProfile(
        uid: email,
        displayName: name,
        email: email,
      );

      await prefs.setString('user_id', email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Something went wrong.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    _isLoggedIn = false;
    _userProfile = null;
    _userId = '';
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile profile) async {
    _userProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name_${profile.uid}', profile.displayName);
    notifyListeners();
  }

  Future<bool> resetPassword(String email) async {
    return true;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

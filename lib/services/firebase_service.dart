import '../models/user_profile.dart';

class FirebaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    _initialized = true;
  }

  bool get isAvailable => _initialized;
  bool get isLoggedIn => false;

  Future<void> signOut() async {}

  Future<void> saveUserProfile(UserProfile profile) async {}

  Future<UserProfile?> getUserProfile(String uid) async => null;

  Future<void> updateUserProfile(UserProfile profile) async {}
}

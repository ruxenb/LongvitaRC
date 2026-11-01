import '../models/user_model.dart';

abstract class IAuthService {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<UserModel?> signInWithGoogle();
  Future<void> signOut();
  Future<UserModel?> fetchUserProfile(String uid);
}

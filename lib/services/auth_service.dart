import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'i_auth_service.dart';

class AuthService implements IAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  UserModel? _cachedUser;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  UserModel? get currentUser => _cachedUser;

  @override
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        _cachedUser = null;
        return null;
      }
      return await fetchUserProfile(firebaseUser.uid);
    });
  }

  @override
  Future<UserModel?> fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        _cachedUser = UserModel.fromMap(doc.data()!, doc.id);
        return _cachedUser;
      }
      final currentAuth = _auth.currentUser;
      if (currentAuth != null && currentAuth.uid == uid) {
        final newUser = UserModel(
          uid: uid,
          email: currentAuth.email ?? '',
          displayName: currentAuth.displayName ?? 'Người dùng Longvita',
          photoUrl: currentAuth.photoURL,
          role: 'user', // Default role for app users
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(uid).set(newUser.toMap(), SetOptions(merge: true));
        _cachedUser = newUser;
        return _cachedUser;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      // User cancelled the picker
      return null;
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) return null;

    return await fetchUserProfile(user.uid);
  }

  @override
  Future<void> signOut() async {
    _cachedUser = null;
    await Future.wait([
      _googleSignIn.signOut(),
      _auth.signOut(),
    ]);
  }
}

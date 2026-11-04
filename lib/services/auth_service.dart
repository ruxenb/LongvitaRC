import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/auth_state.dart';
import '../models/user_model.dart';
import 'auth_error_mapper.dart';
import 'i_auth_service.dart';

class AuthService implements IAuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  UserModel? _cachedUser;

  /// Numbers profile loads. Only the latest may fill [_cachedUser], and a
  /// sign-out invalidates loads in flight, so a late response of an ended
  /// session never replaces the profile of the next one (PM-S3-5-03).
  int _profileRequest = 0;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  @override
  Stream<String?> get authUidChanges =>
      _auth.authStateChanges().map((user) {
        if (user == null || user.uid != _cachedUser?.uid) _cachedUser = null;
        if (user == null) _profileRequest++;
        return user?.uid;
      });

  @override
  String? get currentUid => _auth.currentUser?.uid;

  @override
  UserModel? get currentUser {
    final cached = _cachedUser;
    return cached != null && cached.uid == currentUid ? cached : null;
  }

  @override
  Future<AuthSignInResult> signInWithGoogle() async {
    final GoogleSignInAccount? account;
    try {
      account = await _googleSignIn.signIn();
    } on PlatformException catch (e) {
      final failure = AuthErrorMapper.fromGoogle(e);
      return failure.kind == AuthFailureKind.cancelled
          ? const AuthSignInCancelled()
          : AuthSignInFailed(failure);
    }
    if (account == null) return const AuthSignInCancelled();

    try {
      final tokens = await account.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: tokens.accessToken,
        idToken: tokens.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final uid = result.user?.uid;
      if (uid == null) {
        return const AuthSignInFailed(
            AuthFailure(AuthFailureKind.credential, code: 'no-user'));
      }
      return AuthSignInSucceeded(uid);
    } on FirebaseAuthException catch (e) {
      await _signOutGoogleQuietly();
      return AuthSignInFailed(AuthErrorMapper.fromFirebaseAuth(e));
    } on PlatformException catch (e) {
      await _signOutGoogleQuietly();
      return AuthSignInFailed(AuthErrorMapper.fromGoogle(e));
    } catch (e) {
      await _signOutGoogleQuietly();
      return AuthSignInFailed(
          AuthFailure(AuthFailureKind.unknown, cause: e));
    }
  }

  @override
  Future<UserModel> loadProfile(String uid) async {
    final request = ++_profileRequest;
    UserModel remember(UserModel user) {
      if (request == _profileRequest) _cachedUser = user;
      return user;
    }

    final doc = _firestore.collection('users').doc(uid);

    final DocumentSnapshot<Map<String, dynamic>> snapshot;
    try {
      snapshot = await doc.get();
    } on FirebaseException catch (e) {
      throw AuthErrorMapper.fromFirestore(e, writing: false);
    }

    final data = snapshot.data();
    if (snapshot.exists && data != null) {
      try {
        return remember(UserModel.fromMap(data, snapshot.id));
      } catch (e) {
        throw AuthFailure(AuthFailureKind.profileRead,
            code: 'invalid-profile', cause: e);
      }
    }

    // First sign-in: create the profile with the default role. Rules only
    // allow the owner to create it with role 'user'.
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null || firebaseUser.uid != uid) {
      throw const AuthFailure(AuthFailureKind.profileRead,
          code: 'signed-out-during-load');
    }
    final newUser = UserModel(
      uid: uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'Người dùng Longvita',
      photoUrl: firebaseUser.photoURL,
      role: 'user',
      createdAt: DateTime.now(),
    );
    try {
      await doc.set(newUser.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw AuthErrorMapper.fromFirestore(e, writing: true);
    }
    return remember(newUser);
  }

  @override
  Future<void> signOut() async {
    _cachedUser = null;
    _profileRequest++;
    await _signOutGoogleQuietly();
    await _auth.signOut();
  }

  /// Clears the cached Google account so the picker shows next time. A
  /// failure here must not block the Firebase sign-out.
  Future<void> _signOutGoogleQuietly() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
